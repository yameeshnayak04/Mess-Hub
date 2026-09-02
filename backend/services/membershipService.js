// new_backend/services/membershipService.js
const knex = require('../db/knex');
const billingService = require('./billingService');
const { toPublicBill } = require('./billPaymentService');
const { getTodayInIndia } = require('./messClock');
const { NotFoundError, ValidationError, ConflictError } = require('../errors/AppError');
const { priceToRupees } = require('../utils/money');
const { buildPageMeta } = require('../utils/pagination');
const { firstDayOfMonth } = require('../utils/dates');

function toPublicMembership(row) {
  return {
    id: row.id,
    userId: row.user_id,
    messId: row.mess_id,
    planId: row.plan_id,
    planName: row.plan_name,
    // Always the plan's current rate, read live - see selectMembershipColumns.
    rateRupees: priceToRupees(row.plan_rate_price),
    status: row.status,
    joinedDate: row.joined_date,
    discontinuationRequested: Boolean(row.discontinuation_requested_at),
    messName: row.mess_name,
    memberName: row.member_name,
    memberPhone: row.member_phone,
  };
}

// Reads a membership together with the names the app needs to display, and the
// plan's current rate. The rate is joined rather than stored on the membership
// because pricing is live: a plan rate change applies to existing members too.
function selectMembershipColumns(query) {
  return query
    .select(
      'memberships.*',
      'plans.name as plan_name',
      'plans.rate_price as plan_rate_price',
      'messes.mess_name',
      'users.name as member_name',
      'users.phone as member_phone'
    )
    .join('plans', 'plans.id', 'memberships.plan_id')
    .join('messes', 'messes.id', 'memberships.mess_id')
    .join('users', 'users.id', 'memberships.user_id');
}

// Shared by join and approve: both must not let the mess go over capacity.
//
// The lock matters. Reading the count and then inserting as two separate
// steps leaves a gap where another request can do the same thing, and both
// see "one spot left". `FOR UPDATE` on the mess row makes the second request
// wait until the first has finished, so the count it reads is always current.
// This is the check-then-act race the old backend had in both places.
async function assertCapacityAvailable(trx, messId) {
  const mess = await trx('messes').where('id', messId).forUpdate().first();
  if (!mess) throw new NotFoundError('Mess not found');
  if (mess.max_capacity == null) return mess;

  const activeCount = await trx('memberships')
    .where({ mess_id: messId, status: 'Active' })
    .count('* as count')
    .first();

  if (Number(activeCount.count) >= mess.max_capacity) {
    throw new ConflictError('This mess is full and cannot take new members right now', 'MESS_FULL');
  }
  return mess;
}

async function joinMess(userId, messId, planId) {
  return knex.transaction(async (trx) => {
    await assertCapacityAvailable(trx, messId);

    const plan = await trx('plans').where({ id: planId, mess_id: messId, is_active: true }).first();
    if (!plan) throw new ValidationError('That plan is not available at this mess');

    const alreadyHere = await trx('memberships')
      .where({ user_id: userId, mess_id: messId })
      .whereIn('status', ['Pending', 'Active'])
      .first();
    if (alreadyHere) {
      throw new ConflictError('You already have a pending or active membership at this mess');
    }

    const [inserted] = await trx('memberships')
      .insert({
        user_id: userId,
        mess_id: messId,
        plan_id: planId,
        // No rate is stored here on purpose. Billing joins to the plan every
        // time, so if the manager changes the plan's rate this member is
        // billed the new rate from their next bill onwards.
        status: 'Pending',
      })
      .returning('id');

    // Re-read through the shared selector so the response carries the plan's
    // current rate and the display names, same as every other read path.
    return selectMembershipColumns(trx('memberships')).where('memberships.id', inserted.id).first();
  });
}

async function approveMembership(membershipId) {
  return knex.transaction(async (trx) => {
    const membership = await trx('memberships').where('id', membershipId).first();
    if (!membership) throw new NotFoundError('Membership not found');
    if (membership.status !== 'Pending') {
      throw new ValidationError(`This membership is already ${membership.status}`);
    }

    // Checked again here, not just at join time: plenty of time may have
    // passed and the mess may have filled up in between.
    await assertCapacityAvailable(trx, membership.mess_id);

    const today = await getTodayInIndia(trx);

    await trx('memberships')
      .where('id', membershipId)
      .update({
        status: 'Active',
        joined_date: today,
        effective_from: today,
        // Open-ended range: active from today with no end date yet.
        active_period: trx.raw('daterange(?::date, NULL, ?)', [today, '[)']),
      });

    return selectMembershipColumns(trx('memberships'))
      .where('memberships.id', membershipId)
      .first();
  });
}

async function rejectMembership(membershipId) {
  const membership = await knex('memberships').where('id', membershipId).first();
  if (!membership) throw new NotFoundError('Membership not found');
  if (membership.status !== 'Pending') {
    throw new ValidationError('Only a pending request can be rejected');
  }
  await knex('memberships').where('id', membershipId).del();
  return { id: Number(membershipId), rejected: true };
}

// Customer asks to leave the mess for good.
//
// Two things happen at once and they are related: we mark the request, and we
// immediately produce the partial bill for the month so far. From this moment
// the membership is "frozen" — no more attendance can be marked and billing
// will never count a day past today (see billingService's window logic).
async function requestDiscontinuation(membershipId) {
  return knex.transaction(async (trx) => {
    const membership = await trx('memberships').where('id', membershipId).first();
    if (!membership) throw new NotFoundError('Membership not found');
    if (membership.status !== 'Active') {
      throw new ValidationError('Only an active membership can be discontinued');
    }
    if (membership.discontinuation_requested_at) {
      throw new ValidationError('You have already requested to leave this mess');
    }

    const today = await getTodayInIndia(trx);
    await trx('memberships')
      .where('id', membershipId)
      .update({ discontinuation_requested_at: trx.fn.now() });

    // periodEnd is today and exclusive, i.e. bill everything up to and
    // including yesterday. Today's meals have not finished yet, so including
    // them would fail billing's "attendance must be complete" check.
    const bill = await billingService.generateBillForMembership(trx, {
      membershipId,
      periodStart: firstDayOfMonth(today),
      periodEnd: today,
    });

    // Map the bill: its raw columns are integer paise, so handing the row
    // straight out would show an amount 100x too large.
    return {
      membershipId: Number(membershipId),
      requestedOn: today,
      bill: bill ? toPublicBill(bill) : null,
    };
  });
}

async function approveDiscontinuation(membershipId) {
  return knex.transaction(async (trx) => {
    const membership = await trx('memberships').where('id', membershipId).first();
    if (!membership) throw new NotFoundError('Membership not found');
    if (!membership.discontinuation_requested_at) {
      throw new ValidationError('This member has not asked to leave');
    }

    const unpaid = await trx('bills')
      .where('membership_id', membershipId)
      .whereIn('status', ['Due', 'Pending Approval'])
      .select('id', 'period', 'total_price', 'status');

    if (unpaid.length > 0) {
      throw new ConflictError(
        'This member still has unpaid bills. Settle them before closing the membership.',
        'OUTSTANDING_BILLS'
      );
    }

    const today = await getTodayInIndia(trx);
    await trx('memberships')
      .where('id', membershipId)
      .update({
        status: 'Inactive',
        // Close the open-ended range. The end is exclusive, so their last
        // billable day is the day before this.
        active_period: trx.raw('daterange(lower(active_period), ?::date, ?)', [today, '[)']),
      });

    return { membershipId: Number(membershipId), status: 'Inactive', closedOn: today };
  });
}

// Manager says no — the membership carries on as normal.
async function rejectDiscontinuation(membershipId) {
  const membership = await knex('memberships').where('id', membershipId).first();
  if (!membership) throw new NotFoundError('Membership not found');
  if (!membership.discontinuation_requested_at) {
    throw new ValidationError('This member has not asked to leave');
  }

  // Clearing this one column un-freezes everything: attendance can be marked
  // again and billing goes back to counting the whole month, because every
  // freeze check in the codebase keys off this single field.
  await knex('memberships')
    .where('id', membershipId)
    .update({ discontinuation_requested_at: null });

  return { membershipId: Number(membershipId), discontinuationRequested: false };
}

async function listMyMemberships(userId) {
  const rows = await selectMembershipColumns(knex('memberships'))
    .where('memberships.user_id', userId)
    .orderBy('memberships.created_at', 'desc');
  return rows.map(toPublicMembership);
}

async function listMessMembers(messId, { status, page, limit, offset }) {
  const applyFilter = (query) => {
    query.where('memberships.mess_id', messId);
    if (status) query.andWhere('memberships.status', status);
    return query;
  };

  const totalRow = await applyFilter(knex('memberships').count('* as count')).first();
  const rows = await applyFilter(selectMembershipColumns(knex('memberships')))
    .orderBy('memberships.created_at', 'desc')
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map(toPublicMembership),
    meta: buildPageMeta({ page, limit, total: Number(totalRow.count) }),
  };
}

// Everything the customer dashboard needs, in one call.
async function getMembershipDetails(membershipId) {
  const membership = await selectMembershipColumns(knex('memberships'))
    .where('memberships.id', membershipId)
    .first();
  if (!membership) throw new NotFoundError('Membership not found');

  const today = await getTodayInIndia();
  const monthStart = firstDayOfMonth(today);

  // One grouped query for the month's attendance summary rather than four
  // separate COUNT queries.
  const { rows: summaryRows } = await knex.raw(
    `
    SELECT
      count(*) FILTER (WHERE status = 'Present') AS present,
      count(*) FILTER (WHERE status = 'Skipped') AS skipped,
      count(*) FILTER (WHERE status = 'Leave')   AS leave,
      count(*) FILTER (WHERE status = 'Absent')  AS absent
    FROM attendance
    WHERE membership_id = ? AND service_date >= ?::date AND service_date <= ?::date
    `,
    [membershipId, monthStart, today]
  );

  const recentBills = await knex('bills')
    .where('membership_id', membershipId)
    .orderBy('period', 'desc')
    .limit(6);

  const todaysMenu = await knex('menus')
    .where({ mess_id: membership.mess_id, service_date: today })
    .first();

  return {
    membership: toPublicMembership(membership),
    monthToDate: {
      present: Number(summaryRows[0].present),
      skipped: Number(summaryRows[0].skipped),
      leave: Number(summaryRows[0].leave),
      absent: Number(summaryRows[0].absent),
    },
    recentBills: recentBills.map((bill) => ({
      id: bill.id,
      period: bill.period,
      totalRupees: priceToRupees(bill.total_price),
      status: bill.status,
    })),
    todaysMenu: todaysMenu
      ? { lunchItems: todaysMenu.lunch_items, dinnerItems: todaysMenu.dinner_items }
      : null,
  };
}

module.exports = {
  joinMess,
  approveMembership,
  rejectMembership,
  requestDiscontinuation,
  approveDiscontinuation,
  rejectDiscontinuation,
  listMyMemberships,
  listMessMembers,
  getMembershipDetails,
  toPublicMembership,
};
