// new_backend/services/billingService.test.js
//
// These tests run against the REAL Postgres from docker compose, not a mock.
// Billing is the part of this app that must not be wrong, and mocks would hide
// exactly the things we care about here: how Postgres rounds, how the date
// ranges behave, and whether the constraints actually hold.
//
// Test month is April 2026 (30 days) with a "Both Meals" plan, chosen so the
// numbers stay easy to check by hand:
//   30 days x 2 meals            = 60 billable meals in the month
//   rate 600000 stored units (Rs 6000) = 10000 per meal (Rs 100), exactly

const test = require('node:test');
const assert = require('node:assert/strict');

const billingService = require('./billingService');
const { IncompleteAttendanceDataError } = require('../errors/AppError');
const {
  knex,
  withRollback,
  createMess,
  createPlan,
  createMembership,
  createCustomer,
  fillAttendance,
  setAttendanceStatus,
} = require('./test-helpers/fixtures');

const APRIL_START = '2026-04-01';
const MAY_START = '2026-05-01';
const MONTHLY_RATE = 600000; // Rs 6000, stored as rupees x 100
const PER_MEAL = 10000; // 600000 / 60 meals
const REBATE_PER_THALI = 5000; // Rs 50, stored as rupees x 100

// Most tests want the same starting point: a mess, a two-meal plan, and an
// active membership covering all of April.
async function setupFullMonthMembership(trx, messOptions = {}) {
  const mess = await createMess(trx, messOptions);
  const plan = await createPlan(trx, mess.id, { ratePrice: MONTHLY_RATE });
  const membership = await createMembership(trx, {
    messId: mess.id,
    planId: plan.id,
    activeStart: APRIL_START,
  });
  return { mess, plan, membership };
}

test('1. mid-month join is prorated to the days actually active', async () => {
  await withRollback(async (trx) => {
    const mess = await createMess(trx);
    const plan = await createPlan(trx, mess.id, { ratePrice: MONTHLY_RATE });
    // Joined on the 16th, so 15 of April's 30 days.
    const membership = await createMembership(trx, {
      messId: mess.id,
      planId: plan.id,
      activeStart: '2026-04-16',
    });
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: '2026-04-16',
      to: MAY_START,
      status: 'Present',
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    // Half the month active -> half the monthly rate.
    assert.equal(Number(bill.base_price), 300000);
    assert.equal(Number(bill.rebate_price), 0);
    assert.equal(Number(bill.total_price), 300000);
  });
});

test('2. approved leave days earn the per-thali rebate', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx);
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });
    // 4 days of leave = 8 meals (lunch + dinner each day).
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-10',
      to: '2026-04-14',
      status: 'Leave',
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    assert.equal(Number(bill.base_price), MONTHLY_RATE);
    assert.equal(Number(bill.rebate_price), 8 * REBATE_PER_THALI); // 40000
    assert.equal(Number(bill.total_price), MONTHLY_RATE - 40000);
  });
});

test('3. an explicit periodEnd bills only the partial window, not the whole month', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx);
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: '2026-04-16',
    });

    // This is what requestDiscontinuation does: bill up to (not including)
    // today. 15 days billed, but the proration denominator is still the full
    // 30-day month.
    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
      periodEnd: '2026-04-16',
    });

    assert.equal(Number(bill.base_price), 300000);
    assert.equal(Number(bill.total_price), 300000);
  });
});

test('4. refuses to bill when attendance for the window is incomplete', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx);
    // Absence-marking job only got through the 20th - the rest of April has
    // no records at all.
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: '2026-04-21',
    });

    await assert.rejects(
      () =>
        billingService.generateBillForMembership(trx, {
          membershipId: membership.id,
          periodStart: APRIL_START,
        }),
      IncompleteAttendanceDataError
    );

    // And critically: it must not have written a half-guessed bill.
    const bills = await trx('bills').where('membership_id', membership.id);
    assert.equal(bills.length, 0);
  });
});

test('5. a plan rate change mid-cycle applies to existing members (live pricing)', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx);
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-10',
      to: '2026-04-14',
      status: 'Leave',
    });

    // Manager raises the plan price and the rebate rate mid-cycle. The
    // membership was created while the plan still cost MONTHLY_RATE.
    const NEW_RATE = 900000; // Rs 9000
    await trx('plans').where('id', plan.id).update({ rate_price: NEW_RATE });
    await trx('messes').where('id', mess.id).update({ rule_rebate_per_thali_price: 7000 });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    // Billing joins to the plan every time, so this bill charges the NEW rate
    // even though the member joined at the old one. Nothing is snapshotted on
    // the membership - this is the whole point of live pricing.
    assert.equal(Number(bill.base_price), NEW_RATE);
    assert.notEqual(Number(bill.base_price), MONTHLY_RATE);
    // Rebate rules are read live at billing time too.
    assert.equal(Number(bill.rebate_price), 8 * 7000);
  });
});

test('5b. a bill generated BEFORE a rate change keeps the old amount', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx);
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });

    // Bill first, at the original rate.
    const firstBill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });
    assert.equal(Number(firstBill.base_price), MONTHLY_RATE);

    // Then the manager raises the price. Live pricing applies from the NEXT
    // bill onwards, so a re-run of the same period does pick it up - but an
    // already-settled bill is never rewritten (see test 13).
    await trx('plans').where('id', plan.id).update({ rate_price: 900000 });
    await trx('bills').where('id', firstBill.id).update({ status: 'Paid' });

    const rerun = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });
    assert.equal(rerun.status, 'Paid');
    assert.equal(Number(rerun.base_price), MONTHLY_RATE, 'a paid bill is never repriced');
  });
});

test('6. rejoining the same mess in the same month produces two independent bills', async () => {
  await withRollback(async (trx) => {
    const customer = await createCustomer(trx);
    const mess = await createMess(trx);
    const plan = await createPlan(trx, mess.id, { ratePrice: MONTHLY_RATE });

    // First stint: April 1-10, then they left.
    const firstMembership = await createMembership(trx, {
      customer,
      messId: mess.id,
      planId: plan.id,
      status: 'Inactive',
      activeStart: APRIL_START,
      activeEnd: '2026-04-11',
    });
    // Second stint: rejoined on the 21st.
    const secondMembership = await createMembership(trx, {
      customer,
      messId: mess.id,
      planId: plan.id,
      status: 'Active',
      activeStart: '2026-04-21',
    });

    await fillAttendance(trx, {
      membershipId: firstMembership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: '2026-04-11',
    });
    await fillAttendance(trx, {
      membershipId: secondMembership.id,
      messId: mess.id,
      meals: plan.meals,
      from: '2026-04-21',
      to: MAY_START,
    });

    const firstBill = await billingService.generateBillForMembership(trx, {
      membershipId: firstMembership.id,
      periodStart: APRIL_START,
    });
    const secondBill = await billingService.generateBillForMembership(trx, {
      membershipId: secondMembership.id,
      periodStart: APRIL_START,
    });

    // The old backend keyed bills by (user, mess, month), so the second bill
    // would have silently overwritten the first. Keyed by membership, both survive.
    assert.notEqual(firstBill.id, secondBill.id);
    assert.equal(Number(firstBill.base_price), 200000); // 10 days
    assert.equal(Number(secondBill.base_price), 200000); // 10 days

    const allBills = await trx('bills').where('mess_id', mess.id);
    assert.equal(allBills.length, 2);
  });
});

test('7. absent meals are rebated when the mess allows it', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx, {
      allowAbsentRebate: true,
    });
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });
    // 3 days absent = 6 meals.
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-05',
      to: '2026-04-08',
      status: 'Absent',
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    assert.equal(Number(bill.rebate_price), 6 * REBATE_PER_THALI); // 30000
  });
});

test('8. absent meals are charged in full when the mess does not allow the rebate', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx, {
      allowAbsentRebate: false,
    });
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-05',
      to: '2026-04-08',
      status: 'Absent',
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    assert.equal(Number(bill.rebate_price), 0);
    assert.equal(Number(bill.total_price), MONTHLY_RATE);
  });
});

test('9. skips rebate a percentage of the per-meal price', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx, {
      skipAllowancePercent: 20,
    });
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });
    // 5 skipped lunches (lunch only, so exactly 5 meals not 10).
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-05',
      to: '2026-04-10',
      meals: ['Lunch'],
      status: 'Skipped',
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    // 5 skips x 10000 per meal x 20% = 10000
    const expectedSkipRebate = Math.round(5 * PER_MEAL * 0.2);
    assert.equal(Number(bill.rebate_price), expectedSkipRebate);
    assert.equal(Number(bill.total_price), MONTHLY_RATE - expectedSkipRebate);
  });
});

test('10. the bill never drops below the minimum monthly charge', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx, {
      minMonthlyChargePrice: 500000,
    });
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });
    // 20 days of leave = 40 meals x 5000 = 200000 rebate, which would take the
    // bill down to 400000 - below the mess's 500000 floor.
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-01',
      to: '2026-04-21',
      status: 'Leave',
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    assert.equal(Number(bill.rebate_price), 200000);
    assert.equal(Number(bill.total_price), 500000);
  });
});

test('11. a plan with no meals produces a zero bill instead of an error', async () => {
  await withRollback(async (trx) => {
    const mess = await createMess(trx);
    const plan = await createPlan(trx, mess.id, { ratePrice: MONTHLY_RATE, meals: [] });
    const membership = await createMembership(trx, {
      messId: mess.id,
      planId: plan.id,
      activeStart: APRIL_START,
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    assert.equal(Number(bill.base_price), 0);
    assert.equal(Number(bill.total_price), 0);
  });
});

test('12. a membership that was not active during the month is billed zero', async () => {
  await withRollback(async (trx) => {
    const mess = await createMess(trx, { minMonthlyChargePrice: 500000 });
    const plan = await createPlan(trx, mess.id, { ratePrice: MONTHLY_RATE });
    // Joins in May; we are billing April.
    const membership = await createMembership(trx, {
      messId: mess.id,
      planId: plan.id,
      activeStart: MAY_START,
    });

    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    assert.equal(Number(bill.base_price), 0);
    // Importantly the minimum monthly charge must NOT kick in here - they were
    // not a member at all in April.
    assert.equal(Number(bill.total_price), 0);
  });
});

test('13. re-running billing never touches a bill that is already paid or awaiting approval', async () => {
  await withRollback(async (trx) => {
    const { mess, plan, membership } = await setupFullMonthMembership(trx);
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: MAY_START,
    });

    const firstBill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });
    // The customer pays it and the manager approves.
    await trx('bills').where('id', firstBill.id).update({ status: 'Paid' });

    // Something changes that would alter the amount, then billing re-runs.
    await setAttendanceStatus(trx, {
      membershipId: membership.id,
      from: '2026-04-10',
      to: '2026-04-14',
      status: 'Leave',
    });
    const rerunBill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    // Paid bills are immutable as far as the job is concerned.
    assert.equal(rerunBill.status, 'Paid');
    assert.equal(Number(rerunBill.base_price), MONTHLY_RATE);
    assert.equal(Number(rerunBill.rebate_price), 0);
    assert.equal(Number(rerunBill.total_price), MONTHLY_RATE);
  });
});

test('14. a pending discontinuation freezes billing at the request date', async () => {
  await withRollback(async (trx) => {
    const mess = await createMess(trx);
    const plan = await createPlan(trx, mess.id, { ratePrice: MONTHLY_RATE });
    // Active with no end date yet (the manager has not approved the
    // discontinuation), but the customer requested it on the 16th.
    const membership = await createMembership(trx, {
      messId: mess.id,
      planId: plan.id,
      activeStart: APRIL_START,
      discontinuationRequestedAt: '2026-04-16 10:00:00+05:30',
    });
    await fillAttendance(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      from: APRIL_START,
      to: '2026-04-16',
    });

    // The monthly job runs for all of April and does NOT pass a periodEnd.
    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart: APRIL_START,
    });

    // Without the freeze this would have expanded to a full-month bill and
    // quietly overwritten the partial one created at request time.
    assert.equal(Number(bill.base_price), 300000);
    assert.equal(Number(bill.total_price), 300000);
  });
});

test.after(async () => {
  await knex.destroy();
});
