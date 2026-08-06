// new_backend/services/billingService.js
//
// Generates a member's bill for one month. This is the most important file in
// the project, so it is deliberately broken into small named steps rather than
// one big clever query.
//
// The rules it implements (all decided during planning, see docs/HLD.md):
//   - Base charge is prorated by how much of the month the membership was active.
//   - Leave days rebate a fixed per-thali amount set by the mess.
//   - Skipped meals rebate a percentage of the per-meal price.
//   - Absent meals rebate only if the mess turned that option on.
//   - The final bill never goes below the mess's minimum monthly charge.
//   - Billing refuses to run at all if attendance for the period is incomplete.

const { NotFoundError, IncompleteAttendanceDataError } = require('../errors/AppError');
const { addMonths, daysBetween, earlier, later } = require('../utils/dates');

async function loadMembershipAndRules(trx, membershipId) {
  // Dates come back as plain 'YYYY-MM-DD' text on purpose. If we let the
  // driver hand us JavaScript Date objects, they would carry a timezone we
  // do not want and could shift the day by one.
  const { rows } = await trx.raw(
    `
    SELECT
      memberships.id,
      memberships.mess_id,
      memberships.plan_id,
      memberships.rate_paise,
      lower(memberships.active_period)::text AS active_start,
      upper(memberships.active_period)::text AS active_end,
      (memberships.discontinuation_requested_at AT TIME ZONE 'Asia/Kolkata')::date::text
        AS discontinuation_date,
      messes.rule_rebate_per_thali_paise,
      messes.rule_skip_allowance_percent,
      messes.rule_allow_absent_rebate,
      messes.rule_min_monthly_charge_paise
    FROM memberships
    JOIN messes ON messes.id = memberships.mess_id
    WHERE memberships.id = ?
    `,
    [membershipId]
  );
  return rows[0];
}

async function loadPlanMeals(trx, planId) {
  const rows = await trx('plan_meals').select('meal').where('plan_id', planId).orderBy('meal');
  return rows.map((row) => row.meal);
}

// Works out which slice of the month this membership should actually be
// billed for. Returns null when there is nothing to bill.
function resolveBillingWindow(membership, periodStart, periodEnd) {
  if (!membership.active_start) return null; // never activated

  const windowStart = later(periodStart, membership.active_start);

  let windowEnd = periodEnd;
  if (membership.active_end) {
    windowEnd = earlier(windowEnd, membership.active_end);
  }
  // A requested-but-not-yet-approved discontinuation freezes the membership
  // on that date, so billing must stop there too. Without this, a monthly job
  // running later would recalculate a full month and quietly overwrite the
  // smaller partial bill created when the request was made.
  //
  // The cap is exclusive (we bill up to but not including the request date).
  // That is what makes the bill computable the moment the customer asks to
  // leave: every earlier day already has complete attendance, whereas today's
  // meals have not happened yet.
  if (membership.discontinuation_date) {
    windowEnd = earlier(windowEnd, membership.discontinuation_date);
  }

  if (windowEnd <= windowStart) return null;
  return { windowStart, windowEnd };
}

async function countAttendanceByStatus(trx, membershipId, meals, windowStart, windowEnd) {
  const rows = await trx('attendance')
    .select('status')
    .count('* as count')
    .where('membership_id', membershipId)
    .andWhere('service_date', '>=', windowStart)
    .andWhere('service_date', '<', windowEnd)
    .whereIn('meal', meals)
    .groupBy('status');

  const counts = { Present: 0, Skipped: 0, Leave: 0, Absent: 0 };
  for (const row of rows) {
    counts[row.status] = Number(row.count);
  }
  counts.total = counts.Present + counts.Skipped + counts.Leave + counts.Absent;
  return counts;
}

// Pure money math - no database, no dates, just numbers in and numbers out.
// Everything is in paise (whole numbers), so there is no floating-point money
// anywhere. The old backend stored rupees as floats and patched the rounding
// afterwards, which is how small errors crept into invoices.
function calculateBillAmounts({ monthlyRatePaise, totalMealsInMonth, activeMeals, counts, rules }) {
  const perMealPaise = Math.round(monthlyRatePaise / totalMealsInMonth);

  // Prorate from the ratio directly rather than multiplying the rounded
  // per-meal price, so the rounding error cannot pile up over many meals.
  const basePaise = Math.round((monthlyRatePaise * activeMeals) / totalMealsInMonth);

  const leaveRebate = counts.Leave * rules.rebatePerThaliPaise;

  // "Skip allowance percent" is read as a rebate *rate*: every skipped meal
  // gives back that percentage of the meal's price. It is not a cap on how
  // many meals you may skip. (Confirmed product decision during planning.)
  const skipRebate = Math.round(counts.Skipped * perMealPaise * (rules.skipAllowancePercent / 100));

  const absentRebate = rules.allowAbsentRebate ? counts.Absent * rules.rebatePerThaliPaise : 0;

  // Rebates can never exceed the base charge - both because it makes no
  // business sense and because the bills table has a CHECK enforcing it.
  const rebatePaise = Math.min(leaveRebate + skipRebate + absentRebate, basePaise);

  const totalPaise = Math.max(basePaise - rebatePaise, rules.minMonthlyChargePaise);

  return { basePaise, rebatePaise, totalPaise };
}

// Insert the bill, or update it if one already exists for this membership and
// month. Written as a single statement so two concurrent job runs cannot both
// insert and collide.
async function saveBill(trx, { membershipId, messId, period, amounts }) {
  const { rows } = await trx.raw(
    `
    INSERT INTO bills (membership_id, mess_id, period, base_paise, rebate_paise, total_paise, status)
    VALUES (?, ?, ?, ?, ?, ?, 'Due')
    ON CONFLICT (membership_id, period) DO UPDATE
      SET base_paise   = EXCLUDED.base_paise,
          rebate_paise = EXCLUDED.rebate_paise,
          total_paise  = EXCLUDED.total_paise,
          status       = 'Due',
          updated_at   = now()
      WHERE bills.status NOT IN ('Paid', 'Pending Approval')
    RETURNING *
    `,
    [membershipId, messId, period, amounts.basePaise, amounts.rebatePaise, amounts.totalPaise]
  );

  // No row came back, which means the WHERE above blocked the update: the
  // customer has already paid this bill or submitted proof for it. Leave it
  // exactly as it is and hand back what is already stored.
  if (rows.length === 0) {
    return trx('bills').where({ membership_id: membershipId, period }).first();
  }
  return rows[0];
}

/**
 * Generates (or refreshes) one membership's bill for one month.
 *
 * @param trx           a knex transaction or the knex instance
 * @param membershipId  which membership to bill
 * @param periodStart   first day of the month being billed, 'YYYY-MM-DD'
 * @param periodEnd     optional 'YYYY-MM-DD', exclusive. Used when billing a
 *                      partial month (e.g. a customer discontinuing mid-month).
 *                      Defaults to the end of the month.
 */
async function generateBillForMembership(trx, { membershipId, periodStart, periodEnd }) {
  const membership = await loadMembershipAndRules(trx, membershipId);
  if (!membership) {
    throw new NotFoundError(`Membership ${membershipId} not found`);
  }

  // The month always runs start-to-start; this is the proration denominator
  // and must stay the FULL month even when periodEnd cuts the window short.
  // Otherwise a half-month bill would be divided by half a month and come out
  // as a full month's charge.
  const monthEnd = addMonths(periodStart, 1);
  const requestedEnd = periodEnd || monthEnd;

  const meals = await loadPlanMeals(trx, membership.plan_id);
  const window = resolveBillingWindow(membership, periodStart, requestedEnd);

  // Nothing to bill: either the plan covers no meals, or the membership was
  // not active during this month at all. Record a zero bill and stop here -
  // note we skip the minimum-monthly-charge floor, because charging a minimum
  // to someone who was never a member that month would be wrong.
  if (meals.length === 0 || window === null) {
    return saveBill(trx, {
      membershipId,
      messId: membership.mess_id,
      period: periodStart,
      amounts: { basePaise: 0, rebatePaise: 0, totalPaise: 0 },
    });
  }

  const totalMealsInMonth = daysBetween(periodStart, monthEnd) * meals.length;
  const activeMeals = daysBetween(window.windowStart, window.windowEnd) * meals.length;

  const counts = await countAttendanceByStatus(
    trx,
    membershipId,
    meals,
    window.windowStart,
    window.windowEnd
  );

  // Every meal in the window must already have a record. A missing record is
  // not evidence of anything - it usually means the absence-marking job has
  // not caught up yet. Billing stops rather than guessing, which is the fix
  // for the old backend treating gaps as free rebates.
  if (counts.total < activeMeals) {
    throw new IncompleteAttendanceDataError(
      `Cannot bill membership ${membershipId} for ${periodStart}: ` +
        `${counts.total} of ${activeMeals} meals have attendance records ` +
        `between ${window.windowStart} and ${window.windowEnd}.`
    );
  }

  const amounts = calculateBillAmounts({
    monthlyRatePaise: Number(membership.rate_paise),
    totalMealsInMonth,
    activeMeals,
    counts,
    rules: {
      rebatePerThaliPaise: Number(membership.rule_rebate_per_thali_paise),
      skipAllowancePercent: Number(membership.rule_skip_allowance_percent),
      allowAbsentRebate: membership.rule_allow_absent_rebate,
      minMonthlyChargePaise: Number(membership.rule_min_monthly_charge_paise || 0),
    },
  });

  return saveBill(trx, {
    membershipId,
    messId: membership.mess_id,
    period: periodStart,
    amounts,
  });
}

module.exports = {
  generateBillForMembership,
  // Exported so the pure math can be reasoned about (and tested) on its own.
  calculateBillAmounts,
  resolveBillingWindow,
};
