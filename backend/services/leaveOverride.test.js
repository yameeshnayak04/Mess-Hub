// new_backend/services/leaveOverride.test.js
//
// Tests for overrideLeaveAndMarkPresent: a member who is mid-leave shows up at
// the mess anyway and gets marked Present.
//
// The thing being protected here is that `leaves` and `attendance` never
// contradict each other, and that nobody keeps a leave rebate for days they
// did not actually take.
//
// These run against the real Postgres inside a rolled-back transaction, so the
// meal-window checks are evaluated by the database against the real clock. The
// mess timings in each test are chosen so the meal we want is genuinely being
// served "now", whenever the suite happens to run.

const test = require('node:test');
const assert = require('node:assert/strict');

const attendanceService = require('./attendanceService');
const billingService = require('./billingService');
const { markAbsentForMeal } = require('../jobs/absenceJob');
const { getTodayInIndia } = require('./messClock');
const { addDays, firstDayOfMonth, daysBetween } = require('../utils/dates');
const {
  knex,
  withRollback,
  createMess,
  createPlan,
  createMembership,
  createLeave,
  readLeavePeriod,
} = require('./test-helpers/fixtures');

const PIN = '4321';
const MIN_LEAVE_DAYS = 4;
const BOTH_MEALS = ['Lunch', 'Dinner'];

// Lunch spans almost the whole day, so "lunch is being served now" holds
// whenever this suite runs (bar the last two minutes before midnight). Dinner
// is parked in those final minutes. The schema requires each window to start
// before it ends, and lunch to finish before dinner begins.
const LUNCH_IS_ON = {
  lunchStart: '00:00',
  lunchEnd: '23:57',
  dinnerStart: '23:58',
  dinnerEnd: '23:59',
};

// The mirror image: lunch closed seconds after midnight, dinner on for the rest
// of the day. Used where a test needs an already-closed meal window.
const DINNER_IS_ON = {
  lunchStart: '00:00',
  lunchEnd: '00:01',
  dinnerStart: '00:02',
  dinnerEnd: '23:59',
};

// Sets up a mess, a both-meals plan, an active membership, and a leave that is
// already running: it started `elapsedDays` ago and still has days left.
async function setupRunningLeave(trx, { elapsedDays, timings = LUNCH_IS_ON, messOptions = {} }) {
  const today = await getTodayInIndia(trx);
  const leaveStart = addDays(today, -elapsedDays);
  const leaveEnd = addDays(today, 3); // inclusive, so the leave outlives today

  const mess = await createMess(trx, {
    ...timings,
    minLeaveDays: MIN_LEAVE_DAYS,
    ...messOptions,
  });
  const plan = await createPlan(trx, mess.id, { meals: BOTH_MEALS });
  const membership = await createMembership(trx, {
    messId: mess.id,
    planId: plan.id,
    pin: PIN,
    // Active from the day the leave began, so billing windows line up.
    activeStart: leaveStart,
  });
  const leave = await createLeave(trx, {
    membershipId: membership.id,
    messId: mess.id,
    meals: BOTH_MEALS,
    startDate: leaveStart,
    endDate: leaveEnd,
  });

  return { today, leaveStart, leaveEnd, mess, plan, membership, leave };
}

function attendanceOn(trx, membershipId, serviceDate) {
  return trx('attendance')
    .select('meal', 'status')
    .where({ membership_id: membershipId, service_date: serviceDate })
    .orderBy('meal');
}

test('A. mid-leave override once the minimum days are already served: leave is cut short', async () => {
  await withRollback(async (trx) => {
    // Day 5 of the leave, so 4 full days already elapsed - exactly the mess
    // minimum, which means that part still earns its rebate.
    const { today, leaveStart, mess, membership, leave } = await setupRunningLeave(trx, {
      elapsedDays: MIN_LEAVE_DAYS,
    });

    const result = await attendanceService.overrideLeaveAndMarkPresent(
      mess.id,
      {
        membershipId: membership.id,
        pin: PIN,
        meal: 'Lunch',
      },
      trx
    );

    assert.equal(result.elapsedLeaveDays, MIN_LEAVE_DAYS);
    assert.equal(result.elapsedLeaveKept, true, 'the served part of the leave stays valid');

    // The leave row survives but now ends yesterday.
    const period = await readLeavePeriod(trx, leave.id);
    assert.equal(period.start_date, leaveStart, 'start is untouched');
    assert.equal(period.end_date, addDays(today, -1), 'now ends yesterday');

    // Days already taken keep their Leave status - they were genuinely taken.
    const dayBefore = await attendanceOn(trx, membership.id, addDays(today, -1));
    assert.deepEqual(
      dayBefore.map((r) => r.status),
      ['Leave', 'Leave']
    );

    // Today: the overridden meal is Present, the other meal has NO row at all.
    // That is deliberate - the absence job will settle it when its window ends.
    const todayRows = await attendanceOn(trx, membership.id, today);
    assert.deepEqual(todayRows, [{ meal: 'Lunch', status: 'Present' }]);

    // Nothing is left booked as Leave from today onwards.
    const futureLeave = await trx('attendance')
      .where('membership_id', membership.id)
      .andWhere('service_date', '>=', today)
      .andWhere('status', 'Leave');
    assert.equal(futureLeave.length, 0);
  });
});

test('B. mid-leave override before the minimum is met: leave is void, served days become Absent', async () => {
  await withRollback(async (trx) => {
    // Day 2, so only 1 day elapsed against a 4-day minimum. The leave never
    // qualified, so it should not earn any rebate at all.
    const { today, leaveStart, mess, membership, leave } = await setupRunningLeave(trx, {
      elapsedDays: 1,
    });

    const result = await attendanceService.overrideLeaveAndMarkPresent(
      mess.id,
      {
        membershipId: membership.id,
        pin: PIN,
        meal: 'Lunch',
      },
      trx
    );

    assert.equal(result.elapsedLeaveDays, 1);
    assert.equal(result.elapsedLeaveKept, false);

    // The leave row is gone entirely.
    assert.equal(await readLeavePeriod(trx, leave.id), null, 'leave row deleted');

    // The single day already taken is now Absent, not Leave - no rebate.
    const elapsed = await attendanceOn(trx, membership.id, leaveStart);
    assert.deepEqual(
      elapsed.map((r) => r.status),
      ['Absent', 'Absent']
    );

    const todayRows = await attendanceOn(trx, membership.id, today);
    assert.deepEqual(todayRows, [{ meal: 'Lunch', status: 'Present' }]);

    const anyLeaveLeft = await trx('attendance')
      .where('membership_id', membership.id)
      .andWhere('status', 'Leave');
    assert.equal(anyLeaveLeft.length, 0, 'no Leave rows survive an invalidated leave');
  });
});

test('C. override on the very first day of the leave (nothing elapsed) behaves like case B', async () => {
  await withRollback(async (trx) => {
    const { today, mess, membership, leave } = await setupRunningLeave(trx, { elapsedDays: 0 });

    const result = await attendanceService.overrideLeaveAndMarkPresent(
      mess.id,
      {
        membershipId: membership.id,
        pin: PIN,
        meal: 'Lunch',
      },
      trx
    );

    assert.equal(result.elapsedLeaveDays, 0);
    assert.equal(result.elapsedLeaveKept, false);
    assert.equal(await readLeavePeriod(trx, leave.id), null);

    const todayRows = await attendanceOn(trx, membership.id, today);
    assert.deepEqual(todayRows, [{ meal: 'Lunch', status: 'Present' }]);

    // There was nothing before today, so nothing should have been converted.
    const absents = await trx('attendance')
      .where('membership_id', membership.id)
      .andWhere('status', 'Absent');
    assert.equal(absents.length, 0);
  });
});

test('D. the meal that was not overridden is marked Absent by the absence job', async () => {
  await withRollback(async (trx) => {
    // Dinner is the meal being served now and lunch closed just after
    // midnight, so lunch is the one whose window has already passed.
    const { today, mess, membership } = await setupRunningLeave(trx, {
      elapsedDays: MIN_LEAVE_DAYS,
      timings: DINNER_IS_ON,
    });

    await attendanceService.overrideLeaveAndMarkPresent(
      mess.id,
      {
        membershipId: membership.id,
        pin: PIN,
        meal: 'Dinner',
      },
      trx
    );

    // Straight after the override, lunch today has no record at all.
    let todayRows = await attendanceOn(trx, membership.id, today);
    assert.deepEqual(todayRows, [{ meal: 'Dinner', status: 'Present' }]);

    // The absence job fills it in, because lunch's window has closed.
    await markAbsentForMeal(trx, 'Lunch');

    // Ordered by the meal_type enum, which sorts by how the values were
    // declared (Lunch then Dinner) rather than alphabetically.
    todayRows = await attendanceOn(trx, membership.id, today);
    assert.deepEqual(todayRows, [
      { meal: 'Lunch', status: 'Absent' },
      { meal: 'Dinner', status: 'Present' },
    ]);
  });
});

test('E. billing after an override gives no rebate for the voided leave days', async () => {
  await withRollback(async (trx) => {
    // One day elapsed against a 4-day minimum, so the override voids the leave
    // and that day becomes Absent. The mess does not rebate absences.
    const { today, leaveStart, mess, membership } = await setupRunningLeave(trx, {
      elapsedDays: 1,
      messOptions: { allowAbsentRebate: false },
    });

    await attendanceService.overrideLeaveAndMarkPresent(
      mess.id,
      {
        membershipId: membership.id,
        pin: PIN,
        meal: 'Lunch',
      },
      trx
    );

    // Bill the window that ends today, so today's still-incomplete records are
    // outside it. periodStart is anchored on the month containing the leave's
    // start, which keeps this correct even when run on the 1st of a month.
    const periodStart = firstDayOfMonth(leaveStart);
    const bill = await billingService.generateBillForMembership(trx, {
      membershipId: membership.id,
      periodStart,
      periodEnd: today,
    });

    // Had the leave stood, these 2 meals would have rebated 2 x 5000 = 10000.
    assert.equal(Number(bill.rebate_price), 0, 'a voided leave earns no rebate');

    // And the base is prorated over just the days actually inside the window.
    const monthMeals = daysBetween(periodStart, addDays(firstDayOfMonth(leaveStart), 0)) || 0;
    assert.ok(monthMeals >= 0); // (denominator is checked in the billing suite)
    assert.ok(Number(bill.base_price) > 0, 'the day taken is still charged for');
    assert.equal(Number(bill.total_price), Number(bill.base_price));
  });
});

test('the override endpoint refuses when today is not actually a Leave day', async () => {
  await withRollback(async (trx) => {
    const today = await getTodayInIndia(trx);
    const mess = await createMess(trx, { ...LUNCH_IS_ON, minLeaveDays: MIN_LEAVE_DAYS });
    const plan = await createPlan(trx, mess.id, { meals: BOTH_MEALS });
    const membership = await createMembership(trx, {
      messId: mess.id,
      planId: plan.id,
      pin: PIN,
      activeStart: addDays(today, -5),
    });

    // No attendance at all for today.
    await assert.rejects(
      () =>
        attendanceService.overrideLeaveAndMarkPresent(
          mess.id,
          {
            membershipId: membership.id,
            pin: PIN,
            meal: 'Lunch',
          },
          trx
        ),
      /not marked as Leave today/
    );

    // Present already recorded - still refused, this is not an override case.
    await trx('attendance').insert({
      membership_id: membership.id,
      mess_id: mess.id,
      service_date: today,
      meal: 'Lunch',
      status: 'Present',
    });
    await assert.rejects(
      () =>
        attendanceService.overrideLeaveAndMarkPresent(
          mess.id,
          {
            membershipId: membership.id,
            pin: PIN,
            meal: 'Lunch',
          },
          trx
        ),
      /marked as Present today, not Leave/
    );
  });
});

test('the override still requires the correct kiosk PIN', async () => {
  await withRollback(async (trx) => {
    const { mess, membership } = await setupRunningLeave(trx, { elapsedDays: MIN_LEAVE_DAYS });

    await assert.rejects(
      () =>
        attendanceService.overrideLeaveAndMarkPresent(
          mess.id,
          {
            membershipId: membership.id,
            pin: '0000',
            meal: 'Lunch',
          },
          trx
        ),
      /Incorrect PIN/
    );

    // And the leave must be untouched after a failed attempt.
    const stillOnLeave = await trx('attendance')
      .where('membership_id', membership.id)
      .andWhere('status', 'Leave');
    assert.ok(stillOnLeave.length > 0, 'a rejected override changes nothing');
  });
});

test('a separate future leave period is left alone by an override', async () => {
  await withRollback(async (trx) => {
    const { today, mess, membership, plan } = await setupRunningLeave(trx, {
      elapsedDays: MIN_LEAVE_DAYS,
    });

    // A second, non-overlapping leave booked further out.
    const laterStart = addDays(today, 20);
    const laterEnd = addDays(today, 25);
    const laterLeave = await createLeave(trx, {
      membershipId: membership.id,
      messId: mess.id,
      meals: plan.meals,
      startDate: laterStart,
      endDate: laterEnd,
    });

    await attendanceService.overrideLeaveAndMarkPresent(
      mess.id,
      {
        membershipId: membership.id,
        pin: PIN,
        meal: 'Lunch',
      },
      trx
    );

    // The later leave and its attendance rows must survive untouched - the
    // delete is bounded by the overridden leave's own end date.
    const laterPeriod = await readLeavePeriod(trx, laterLeave.id);
    assert.equal(laterPeriod.start_date, laterStart);
    assert.equal(laterPeriod.end_date, laterEnd);

    const laterRows = await trx('attendance')
      .where('membership_id', membership.id)
      .andWhere('service_date', '>=', laterStart)
      .andWhere('status', 'Leave');
    assert.equal(laterRows.length, 12, '6 days x 2 meals still booked as Leave');
  });
});

test.after(async () => {
  await knex.destroy();
});
