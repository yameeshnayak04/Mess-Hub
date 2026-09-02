// new_backend/services/attendanceService.js
const bcrypt = require('bcryptjs');
const knex = require('../db/knex');
const { getMessClock, getTodayInIndia } = require('./messClock');
const { NotFoundError, ValidationError, ConflictError, AppError } = require('../errors/AppError');
const { priceToRupees } = require('../utils/money');
const { buildPageMeta } = require('../utils/pagination');
const { daysBetween } = require('../utils/dates');

// Does this membership's plan actually include this meal? One JOIN, which is
// what replaced the old backend's plan-name substring guessing.
async function planIncludesMeal(db, planId, meal) {
  const row = await db('plan_meals').where({ plan_id: planId, meal }).first();
  return Boolean(row);
}

// Shared gate for anything that writes attendance.
function assertMembershipCanBeMarked(membership) {
  if (membership.status !== 'Active') {
    throw new ValidationError('This membership is not active');
  }
  // Once someone has asked to leave, their membership is frozen: no new
  // attendance, and billing stops counting at the request date. Allowing
  // marking here would create days the final bill could never charge for.
  if (membership.discontinuation_requested_at) {
    throw new ValidationError(
      'This membership is closing - attendance can no longer be marked for it'
    );
  }
}

// Customer says "I won't be eating this meal".
async function skipMeal(membership, meal) {
  assertMembershipCanBeMarked(membership);

  if (!(await planIncludesMeal(knex, membership.plan_id, meal))) {
    throw new ValidationError(`Your plan does not include ${meal.toLowerCase()}`);
  }

  const clock = await getMessClock(membership.mess_id);

  // Skipping is only ever for today. The old backend accepted any date in the
  // request body, so a customer could add "skips" to past days and generate
  // rebates for meals they had already eaten.
  if (clock.isMealOver(meal)) {
    throw new ValidationError(
      `${meal} service has already finished today, so it can no longer be skipped`
    );
  }

  const existing = await knex('attendance')
    .where({ membership_id: membership.id, service_date: clock.today, meal })
    .first();
  if (existing) {
    throw new ConflictError(`${meal} is already marked as ${existing.status} today`);
  }

  const [row] = await knex('attendance')
    .insert({
      membership_id: membership.id,
      mess_id: membership.mess_id,
      service_date: clock.today,
      meal,
      status: 'Skipped',
    })
    .returning('*');

  return row;
}

// The checks every kiosk action shares: the member belongs to this mess, the
// PIN is theirs, their plan covers this meal, and the meal is being served now.
// Both marking present and overriding a leave go through this, so the two can
// never drift apart on who is allowed to do what.
async function verifyKioskRequest(db, messId, { membershipId, pin, meal }) {
  const membership = await db('memberships')
    .select('memberships.*', 'users.pin_hash')
    .join('users', 'users.id', 'memberships.user_id')
    .where('memberships.id', membershipId)
    .first();

  if (!membership || membership.mess_id !== messId) {
    throw new NotFoundError('That member is not part of your mess');
  }
  assertMembershipCanBeMarked(membership);

  if (!membership.pin_hash || !(await bcrypt.compare(pin, membership.pin_hash))) {
    throw new AppError('Incorrect PIN', 401, 'BAD_PIN');
  }

  if (!(await planIncludesMeal(db, membership.plan_id, meal))) {
    throw new ValidationError(`This member's plan does not include ${meal.toLowerCase()}`);
  }

  const clock = await getMessClock(messId, db);
  if (clock.current_meal !== meal) {
    throw new ValidationError(`${meal} is not being served right now`);
  }

  return { membership, clock };
}

// Manager's kiosk: member picks their name, types their PIN, gets marked present.
// `db` exists so tests can run this inside their own transaction; production
// callers leave it out and get the normal connection pool.
async function markAttendanceAtKiosk(messId, { membershipId, pin, meal }, db = knex) {
  const { clock } = await verifyKioskRequest(db, messId, { membershipId, pin, meal });

  const existing = await db('attendance')
    .where({ membership_id: membershipId, service_date: clock.today, meal })
    .first();

  // If something is already recorded we refuse rather than overwrite. Someone
  // on approved leave who turns up anyway needs a deliberate decision, not a
  // silent rewrite of a record their rebate depends on - that deliberate path
  // is overrideLeaveAndMarkPresent below. This guard stays as it is.
  if (existing) {
    throw new ConflictError(`Already marked as ${existing.status} for ${meal.toLowerCase()} today`);
  }

  const [row] = await db('attendance')
    .insert({
      membership_id: membershipId,
      mess_id: messId,
      service_date: clock.today,
      meal,
      status: 'Present',
    })
    .returning('*');

  return row;
}

// A member who is in the middle of an approved leave turns up at the mess
// anyway and wants to eat. This is the deliberate, named way to do that -
// markAttendanceAtKiosk still refuses to quietly overwrite a Leave record.
//
// The tricky part is keeping `leaves` and `attendance` agreeing with each
// other, and never handing out a leave rebate for days that were not actually
// taken. What happens to the leave depends on how much of it has already run:
//
//   * enough days already elapsed to meet the mess minimum -> that part stays
//     valid, and the leave is simply cut short to end yesterday
//   * not enough days elapsed -> the leave never qualified at all, so the days
//     already taken become plain Absent and the leave row is removed
//
// Either way, today onwards stops being leave and this meal becomes Present.
async function overrideLeaveAndMarkPresent(messId, { membershipId, pin, meal }, db = knex) {
  const { clock } = await verifyKioskRequest(db, messId, { membershipId, pin, meal });
  const today = clock.today;

  const existing = await db('attendance')
    .where({ membership_id: membershipId, service_date: today, meal })
    .first();

  // This endpoint exists only for the mid-leave case. Anything else should go
  // through the normal kiosk action so its guards still apply.
  if (!existing || existing.status !== 'Leave') {
    throw new ValidationError(
      existing
        ? `${meal} is marked as ${existing.status} today, not Leave - use the normal kiosk check-in`
        : `${meal} is not marked as Leave today - use the normal kiosk check-in`
    );
  }

  // One transaction: either the leave is corrected AND today is marked
  // Present, or nothing changes at all. A partial result here would leave the
  // two tables contradicting each other.
  // Works whether `db` is the pool or an outer transaction - knex turns a
  // nested transaction into a savepoint, so the all-or-nothing guarantee holds
  // either way.
  return db.transaction(async (trx) => {
    const mess = await trx('messes')
      .select('rule_min_leave_days_for_rebate')
      .where('id', messId)
      .first();

    // `@>` asks whether the range contains this date. Leave can only start the
    // day after it is applied for, so a Leave record today always means we are
    // inside an already-running multi-day leave.
    const leave = await trx('leaves')
      .select(
        'id',
        trx.raw('lower(period)::text AS start_date'),
        trx.raw('upper(period)::text AS end_exclusive')
      )
      .where('membership_id', membershipId)
      .andWhereRaw('period @> ?::date', [today])
      .first();

    if (!leave) {
      // Attendance says Leave but no leave period covers today. That is a
      // contradiction we should never reach, so fail loudly instead of
      // guessing which of the two is right.
      throw new ConflictError('Attendance says Leave today but no matching leave period was found');
    }

    // Days of this leave already behind us, not counting today.
    const elapsedDays = daysBetween(leave.start_date, today);
    const minDays = Number(mess.rule_min_leave_days_for_rebate);
    const elapsedLeaveStillCounts = elapsedDays >= minDays;

    if (elapsedLeaveStillCounts) {
      // Cut the leave short so it ends yesterday. The min-days trigger fires
      // again on this UPDATE and passes - it checks exactly the condition we
      // just tested - so this is defence in depth, not a risk.
      await trx('leaves')
        .where('id', leave.id)
        .update({ period: trx.raw('daterange(lower(period), ?::date, ?)', [today, '[)']) });
    } else {
      // The leave never reached the minimum, so it was never rebate-eligible.
      // Days already taken become ordinary absences and the leave disappears.
      await trx('attendance')
        .where('membership_id', membershipId)
        .andWhere('service_date', '>=', leave.start_date)
        .andWhere('service_date', '<', today)
        .andWhere('status', 'Leave')
        .update({ status: 'Absent' });

      await trx('leaves').where('id', leave.id).del();
    }

    // Today and the rest of this leave are no longer leave days. Bounded by
    // this leave's own end date so that a separate, later leave period the
    // member may already have booked is left completely alone.
    await trx('attendance')
      .where('membership_id', membershipId)
      .andWhere('service_date', '>=', today)
      .andWhere('service_date', '<', leave.end_exclusive)
      .andWhere('status', 'Leave')
      .del();

    // Today's Leave row for this meal was just removed, so a plain insert is
    // correct. The member's other meal today deliberately gets no row: the
    // absence job will mark it Absent once its own window closes, which is
    // already the right outcome.
    const [row] = await trx('attendance')
      .insert({
        membership_id: membershipId,
        mess_id: messId,
        service_date: today,
        meal,
        status: 'Present',
      })
      .returning('*');

    return {
      attendance: row,
      elapsedLeaveDays: elapsedDays,
      elapsedLeaveKept: elapsedLeaveStillCounts,
      leaveEndedOn: elapsedLeaveStillCounts ? today : null,
    };
  });
}

// A walk-in customer paying for a single thali.
//
// These go in their own table, not in attendance. A walk-in is a one-off sale
// with no membership behind it; the old backend forced them into the
// attendance table with null user and membership columns, which made every
// attendance query have to remember to filter them out.
async function recordWalkinSale(mess, { meal, quantity }, recordedByUserId) {
  if (mess.service_type !== 'Both Daily & Monthly') {
    throw new ValidationError('This mess does not offer daily walk-in service');
  }
  if (mess.daily_thali_rate_price == null) {
    throw new ValidationError('Set a daily thali rate before recording walk-in sales');
  }

  const clock = await getMessClock(mess.id);
  if (clock.current_meal !== meal) {
    throw new ValidationError(`${meal} is not being served right now`);
  }

  const rows = Array.from({ length: quantity }, () => ({
    mess_id: mess.id,
    service_date: clock.today,
    meal,
    rate_price: mess.daily_thali_rate_price, // price at the time of sale
    recorded_by: recordedByUserId,
  }));

  const inserted = await knex('walkin_sales').insert(rows).returning('*');
  return {
    serviceDate: clock.today,
    meal,
    quantity: inserted.length,
    totalRupees: priceToRupees(inserted.length * Number(mess.daily_thali_rate_price)),
  };
}

// Calendar view for one membership over one month.
async function getAttendanceCalendar(membershipId, { month, year }) {
  const today = await getTodayInIndia();
  const targetMonth = month || Number(today.slice(5, 7));
  const targetYear = year || Number(today.slice(0, 4));
  const monthStart = `${targetYear}-${String(targetMonth).padStart(2, '0')}-01`;

  const rows = await knex('attendance')
    .select('service_date', 'meal', 'status')
    .where('membership_id', membershipId)
    .andWhereRaw("service_date >= ?::date AND service_date < (?::date + INTERVAL '1 month')", [
      monthStart,
      monthStart,
    ])
    .orderBy(['service_date', 'meal']);

  // Group per day so the app can draw one row per calendar square instead of
  // working that out itself.
  const byDate = new Map();
  for (const row of rows) {
    const key = row.service_date;
    if (!byDate.has(key)) byDate.set(key, { date: key, meals: {} });
    byDate.get(key).meals[row.meal] = row.status;
  }

  return { month: targetMonth, year: targetYear, days: [...byDate.values()] };
}

// The manager's live dashboard: one grouped query, not a loop in JavaScript.
//
// The old backend loaded every active membership into Node, filtered them by
// plan name, then fired several more COUNT queries. This does the whole thing
// in the database, and stays one query no matter how many members there are.
async function getLiveMealStats(mess, requestedMeal) {
  const clock = await getMessClock(mess.id);
  const meal = requestedMeal || clock.current_meal || clock.nextMeal;

  const { rows } = await knex.raw(
    `
    WITH eligible_members AS (
      SELECT memberships.id
      FROM memberships
      JOIN plan_meals ON plan_meals.plan_id = memberships.plan_id AND plan_meals.meal = ?
      WHERE memberships.mess_id = ? AND memberships.status = 'Active'
    )
    SELECT
      (SELECT count(*) FROM eligible_members)                     AS eligible,
      count(*) FILTER (WHERE attendance.status = 'Present')       AS eating,
      count(*) FILTER (WHERE attendance.status = 'Skipped')       AS skipped,
      count(*) FILTER (WHERE attendance.status = 'Leave')         AS on_leave,
      count(*) FILTER (WHERE attendance.status = 'Absent')        AS absent
    FROM eligible_members
    LEFT JOIN attendance
      ON attendance.membership_id = eligible_members.id
     AND attendance.service_date = ?::date
     AND attendance.meal = ?
    `,
    [meal, mess.id, clock.today, meal]
  );

  const counts = rows[0];
  const eligible = Number(counts.eligible);
  const decided =
    Number(counts.eating) +
    Number(counts.skipped) +
    Number(counts.on_leave) +
    Number(counts.absent);

  const walkins = await knex('walkin_sales')
    .where({ mess_id: mess.id, service_date: clock.today, meal })
    .count('* as count')
    .first();

  return {
    date: clock.today,
    meal,
    liveStatus: clock.current_meal ? 'Open' : 'Closed',
    currentMeal: clock.current_meal,
    nextMeal: clock.nextMeal,
    nextMealIsTomorrow: clock.nextMealIsTomorrow,
    counts: {
      eligible,
      eating: Number(counts.eating),
      skipped: Number(counts.skipped),
      onLeave: Number(counts.on_leave),
      absent: Number(counts.absent),
      // "Remaining" is never stored - it is simply everyone eligible who has
      // no record yet. Once the meal window closes the absence job turns each
      // of these into a real 'Absent' row, so this naturally drops to zero.
      remaining: eligible - decided,
      walkins: Number(walkins.count),
    },
  };
}

// The clickable drill-down behind each dashboard number.
async function listMembersByMealStatus(mess, { status, meal, page, limit, offset }) {
  const clock = await getMessClock(mess.id);
  const targetMeal = meal || clock.current_meal || clock.nextMeal;

  const baseQuery = () => {
    const query = knex('memberships')
      .join('users', 'users.id', 'memberships.user_id')
      .join('plan_meals', function joinEligibleMeals() {
        this.on('plan_meals.plan_id', '=', 'memberships.plan_id').andOn(
          'plan_meals.meal',
          '=',
          knex.raw('?', [targetMeal])
        );
      })
      .leftJoin('attendance', function joinTodaysAttendance() {
        this.on('attendance.membership_id', '=', 'memberships.id')
          .andOn('attendance.service_date', '=', knex.raw('?::date', [clock.today]))
          .andOn('attendance.meal', '=', knex.raw('?', [targetMeal]));
      })
      .where('memberships.mess_id', mess.id)
      .andWhere('memberships.status', 'Active');

    // "Remaining" means no attendance row exists yet, which is why it is a
    // null check rather than a status comparison.
    if (status === 'Remaining') {
      query.whereNull('attendance.id');
    } else {
      query.andWhere('attendance.status', status);
    }
    return query;
  };

  const totalRow = await baseQuery().count('* as count').first();
  const rows = await baseQuery()
    .select(
      'memberships.id as membership_id',
      'users.id as user_id',
      'users.name',
      'users.phone',
      'attendance.status'
    )
    .orderBy('users.name')
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map((row) => ({
      membershipId: row.membership_id,
      userId: row.user_id,
      name: row.name,
      phone: row.phone,
      status: row.status || 'Remaining',
    })),
    meta: {
      ...buildPageMeta({ page, limit, total: Number(totalRow.count) }),
      meal: targetMeal,
      date: clock.today,
    },
  };
}

module.exports = {
  skipMeal,
  markAttendanceAtKiosk,
  overrideLeaveAndMarkPresent,
  recordWalkinSale,
  getAttendanceCalendar,
  getLiveMealStats,
  listMembersByMealStatus,
};
