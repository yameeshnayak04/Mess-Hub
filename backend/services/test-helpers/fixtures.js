// new_backend/services/test-helpers/fixtures.js
//
// Helpers for building test data. Every test runs inside a database
// transaction that is rolled back at the end (see withRollback below), so
// nothing here needs to clean up after itself — the rollback does it.

const bcrypt = require('bcryptjs');
const knex = require('../../db/knex');
const { addDays } = require('../../utils/dates');

// Phone numbers are UNIQUE in the schema, so each fixture user needs a
// different one. A counter is the simplest way to guarantee that.
let phoneCounter = 9000000000;
function nextPhone() {
  phoneCounter += 1;
  return String(phoneCounter);
}

// Runs `testBody` inside a transaction and always rolls it back, so tests
// never leave rows behind and can't interfere with each other.
async function withRollback(testBody) {
  const rollbackSignal = new Error('rollback');
  try {
    await knex.transaction(async (trx) => {
      await testBody(trx);
      // Throwing is how you tell knex to roll back instead of commit.
      throw rollbackSignal;
    });
  } catch (error) {
    if (error !== rollbackSignal) throw error;
  }
}

async function createManager(trx) {
  const [manager] = await trx('users')
    .insert({
      name: 'Test Manager',
      phone: nextPhone(),
      password_hash: 'not-a-real-hash',
      role: 'Manager',
    })
    .returning('*');
  return manager;
}

// `pin` is hashed for real so kiosk flows, which bcrypt-compare it, work.
async function createCustomer(trx, options = {}) {
  const [customer] = await trx('users')
    .insert({
      name: 'Test Customer',
      phone: nextPhone(),
      password_hash: 'not-a-real-hash',
      pin_hash: await bcrypt.hash(options.pin ?? '1234', 4),
      role: 'Customer',
      location: trx.raw('ST_SetSRID(ST_MakePoint(73.85, 18.52), 4326)::geography'),
    })
    .returning('*');
  return customer;
}

async function createMess(trx, options = {}) {
  const manager = await createManager(trx);
  const [mess] = await trx('messes')
    .insert({
      owner_id: manager.id,
      mess_name: `Test Mess ${nextPhone()}`,
      address: `${nextPhone()} Test Street`,
      city: 'Pune',
      contact_phone: nextPhone(),
      location: trx.raw('ST_SetSRID(ST_MakePoint(73.85, 18.52), 4326)::geography'),
      service_type: 'Monthly Only',
      cuisine: 'Veg',
      basic_thali_details: 'Roti, sabzi, dal, chawal, salad',
      lunch_start: options.lunchStart ?? '12:00',
      lunch_end: options.lunchEnd ?? '14:00',
      dinner_start: options.dinnerStart ?? '19:00',
      dinner_end: options.dinnerEnd ?? '21:00',
      rule_min_leave_days_for_rebate: options.minLeaveDays ?? 4,
      rule_rebate_per_thali_price: options.rebatePerThaliPrice ?? 5000,
      rule_skip_allowance_percent: options.skipAllowancePercent ?? 20,
      rule_allow_absent_rebate: options.allowAbsentRebate ?? false,
      rule_min_monthly_charge_price: options.minMonthlyChargePrice ?? null,
    })
    .returning('*');
  return mess;
}

async function createPlan(trx, messId, options = {}) {
  const meals = options.meals ?? ['Lunch', 'Dinner'];
  const [plan] = await trx('plans')
    .insert({
      mess_id: messId,
      name: options.name ?? `Plan ${nextPhone()}`,
      rate_price: options.ratePrice ?? 600000,
    })
    .returning('*');

  for (const meal of meals) {
    await trx('plan_meals').insert({ plan_id: plan.id, meal });
  }
  return { ...plan, meals };
}

async function createMembership(trx, options) {
  const customer = options.customer ?? (await createCustomer(trx, { pin: options.pin }));
  const [membership] = await trx('memberships')
    .insert({
      user_id: customer.id,
      mess_id: options.messId,
      plan_id: options.planId,
      // No rate here - billing reads it live from the plan.
      status: options.status ?? 'Active',
      joined_date: options.activeStart ?? null,
      effective_from: options.activeStart ?? null,
      // A daterange is Postgres' native "from this date up to (but not
      // including) that date" type. Passing null as the end means "still
      // ongoing, no end date yet".
      active_period: options.activeStart
        ? trx.raw('daterange(?::date, ?::date, ?)', [
            options.activeStart,
            options.activeEnd ?? null,
            '[)',
          ])
        : null,
      discontinuation_requested_at: options.discontinuationRequestedAt ?? null,
    })
    .returning('*');
  return membership;
}

// Inserts one attendance row per (day, meal) from `from` up to but not
// including `to` — i.e. a fully recorded window, which is what billing
// requires before it will produce a bill.
async function fillAttendance(trx, options) {
  const rows = [];
  for (let day = options.from; day < options.to; day = addDays(day, 1)) {
    for (const meal of options.meals) {
      rows.push({
        membership_id: options.membershipId,
        mess_id: options.messId,
        service_date: day,
        meal,
        status: options.status ?? 'Present',
      });
    }
  }
  if (rows.length > 0) {
    await trx('attendance').insert(rows);
  }
  return rows.length;
}

// Overwrites the status of already-inserted attendance rows, e.g. to turn a
// few 'Present' days into 'Leave' or 'Skipped' for a test.
async function setAttendanceStatus(trx, options) {
  await trx('attendance')
    .where('membership_id', options.membershipId)
    .andWhere('service_date', '>=', options.from)
    .andWhere('service_date', '<', options.to)
    .modify((query) => {
      if (options.meals) query.whereIn('meal', options.meals);
    })
    .update({ status: options.status });
}

// Creates a leave period plus its matching Leave attendance rows, i.e. the
// same state applyForLeave would leave behind. Dates are inclusive, the way a
// customer would type them.
async function createLeave(trx, { membershipId, messId, meals, startDate, endDate }) {
  const [leave] = await trx('leaves')
    .insert({
      membership_id: membershipId,
      period: trx.raw('daterange(?::date, ?::date, ?)', [startDate, endDate, '[]']),
    })
    .returning('*');

  await fillAttendance(trx, {
    membershipId,
    messId,
    meals,
    from: startDate,
    to: addDays(endDate, 1), // fillAttendance's `to` is exclusive
    status: 'Leave',
  });

  return leave;
}

// Reads a leave period back as the inclusive dates a human would recognise.
async function readLeavePeriod(trx, leaveId) {
  const { rows } = await trx.raw(
    `SELECT lower(period)::text AS start_date,
            (upper(period) - INTERVAL '1 day')::date::text AS end_date
     FROM leaves WHERE id = ?`,
    [leaveId]
  );
  return rows[0] || null;
}

module.exports = {
  knex,
  withRollback,
  createManager,
  createCustomer,
  createMess,
  createPlan,
  createMembership,
  createLeave,
  readLeavePeriod,
  fillAttendance,
  setAttendanceStatus,
};
