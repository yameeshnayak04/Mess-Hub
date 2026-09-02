// new_backend/services/leaveService.js
//
// This is holiday leave — "I'm away from the 10th to the 14th, don't cook for
// me". It is approved automatically the moment it meets the mess's minimum
// number of consecutive days.
//
// Not to be confused with *leaving the mess* (ending a membership), which is
// a different feature living in membershipService. The old backend used the
// word "leave" for both and the two got tangled together.

const knex = require('../db/knex');
const { getTodayInIndia } = require('./messClock');
const { ValidationError } = require('../errors/AppError');
const { buildPageMeta } = require('../utils/pagination');

function toPublicLeave(row) {
  return {
    id: row.id,
    membershipId: row.membership_id,
    startDate: row.start_date,
    endDate: row.end_date,
    reason: row.reason,
    memberName: row.member_name,
    memberPhone: row.member_phone,
  };
}

// daterange stores the end exclusively, so read it back as an inclusive date
// for the app (a 10th-to-14th leave should read as ending on the 14th).
function selectLeaveColumns(query) {
  return query.select(
    'leaves.id',
    'leaves.membership_id',
    'leaves.reason',
    knex.raw('lower(leaves.period)::text AS start_date'),
    knex.raw("(upper(leaves.period) - INTERVAL '1 day')::date::text AS end_date")
  );
}

async function applyForLeave(membership, { startDate, endDate, reason }) {
  if (membership.status !== 'Active') {
    throw new ValidationError('This membership is not active');
  }
  if (membership.discontinuation_requested_at) {
    throw new ValidationError('This membership is closing - new leave cannot be applied for');
  }
  if (endDate < startDate) {
    throw new ValidationError('The end date cannot be before the start date');
  }

  const today = await getTodayInIndia();
  // Leave is planned in advance; it cannot start today or in the past.
  if (startDate <= today) {
    throw new ValidationError('Leave must start from tomorrow onwards');
  }

  return knex.transaction(async (trx) => {
    let leave;
    try {
      // The minimum-consecutive-days rule is enforced by a trigger on this
      // table, not by an if-statement here. That way it holds no matter which
      // code path inserts a leave, and it can never drift out of sync with
      // whatever each mess has configured.
      const inserted = await trx('leaves')
        .insert({
          membership_id: membership.id,
          period: trx.raw('daterange(?::date, ?::date, ?)', [startDate, endDate, '[]']),
          reason: reason || null,
        })
        .returning('*');
      leave = inserted[0];
    } catch (error) {
      // 23514 is Postgres' "check violation", which is what our trigger
      // raises. Its message is already written for a customer to read
      // ("Leave must be at least 4 consecutive days"), so pass it through.
      if (error.code === '23514') {
        throw new ValidationError(error.message.replace(/^.*?:\s*/, ''));
      }
      // 23P01 is the exclusion constraint: this range overlaps a leave the
      // member already has.
      if (error.code === '23P01') {
        throw new ValidationError('You already have leave booked that overlaps these dates');
      }
      throw error;
    }

    // Write the actual Leave attendance rows in one statement: every day in
    // the range, crossed with every meal the member's plan covers.
    // ON CONFLICT DO NOTHING means an already-recorded meal (say they were
    // marked Present earlier today) is left alone rather than overwritten.
    const { rowCount } = await trx.raw(
      `
      INSERT INTO attendance (membership_id, mess_id, service_date, meal, status)
      SELECT ?, ?, day::date, plan_meals.meal, 'Leave'
      FROM generate_series(?::date, ?::date, INTERVAL '1 day') AS day
      CROSS JOIN plan_meals
      WHERE plan_meals.plan_id = ?
      ON CONFLICT (membership_id, service_date, meal) DO NOTHING
      `,
      [membership.id, membership.mess_id, startDate, endDate, membership.plan_id]
    );

    return {
      id: leave.id,
      membershipId: membership.id,
      startDate,
      endDate,
      reason: reason || null,
      mealsMarked: rowCount,
    };
  });
}

async function listLeavesForMembership(membershipId, { page, limit, offset }) {
  const totalRow = await knex('leaves')
    .where('membership_id', membershipId)
    .count('* as count')
    .first();

  const rows = await selectLeaveColumns(knex('leaves'))
    .where('membership_id', membershipId)
    .orderByRaw('lower(period) DESC')
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map(toPublicLeave),
    meta: buildPageMeta({ page, limit, total: Number(totalRow.count) }),
  };
}

async function listLeavesForMess(messId, { page, limit, offset }) {
  const applyFilter = (query) =>
    query
      .join('memberships', 'memberships.id', 'leaves.membership_id')
      .where('memberships.mess_id', messId);

  const totalRow = await applyFilter(knex('leaves')).count('* as count').first();

  const rows = await applyFilter(selectLeaveColumns(knex('leaves')))
    .join('users', 'users.id', 'memberships.user_id')
    .select('users.name as member_name', 'users.phone as member_phone')
    .orderByRaw('lower(leaves.period) DESC')
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map(toPublicLeave),
    meta: buildPageMeta({ page, limit, total: Number(totalRow.count) }),
  };
}

// Who is away today (or on a given date) — used by the manager dashboard.
async function listMembersOnLeave(messId, onDate) {
  const date = onDate || (await getTodayInIndia());
  const rows = await knex('leaves')
    .join('memberships', 'memberships.id', 'leaves.membership_id')
    .join('users', 'users.id', 'memberships.user_id')
    .where('memberships.mess_id', messId)
    .andWhereRaw('leaves.period @> ?::date', [date]) // @> means "range contains this date"
    .select('memberships.id as membership_id', 'users.name', 'users.phone');

  return { date, members: rows, count: rows.length };
}

module.exports = {
  applyForLeave,
  listLeavesForMembership,
  listLeavesForMess,
  listMembersOnLeave,
};
