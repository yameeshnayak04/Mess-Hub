// new_backend/services/billingMath.test.js
//
// Pure-function tests for the two pieces of billing that need no database:
// the arithmetic, and working out which slice of the month to bill.
//
// billingService.test.js covers the same logic end-to-end against real
// Postgres. These run in milliseconds and pin down the exact numbers, which
// makes them the fastest way to see WHY a figure came out the way it did.

const test = require('node:test');
const assert = require('node:assert/strict');

const { calculateBillAmounts, resolveBillingWindow } = require('./billingService');

// Same shape as the DB test: 30-day month, both meals, Rs 6000/month, so a
// single meal costs exactly Rs 100 (10000 stored units).
const APRIL = {
  monthlyRatePrice: 600000,
  totalMealsInMonth: 60,
  activeMeals: 60,
};
const RULES = {
  rebatePerThaliPrice: 5000,
  skipAllowancePercent: 20,
  allowAbsentRebate: false,
  minMonthlyChargePrice: 0,
};
const noAttendance = { Present: 60, Skipped: 0, Leave: 0, Absent: 0 };

test('a full month with perfect attendance costs exactly the plan rate', () => {
  const result = calculateBillAmounts({ ...APRIL, counts: noAttendance, rules: RULES });
  assert.equal(result.basePrice, 600000);
  assert.equal(result.rebatePrice, 0);
  assert.equal(result.totalPrice, 600000);
});

test('half a month active is billed at half the rate', () => {
  const result = calculateBillAmounts({
    ...APRIL,
    activeMeals: 30,
    counts: { Present: 30, Skipped: 0, Leave: 0, Absent: 0 },
    rules: RULES,
  });
  assert.equal(result.basePrice, 300000);
});

test('leave days rebate the flat per-thali amount', () => {
  const result = calculateBillAmounts({
    ...APRIL,
    counts: { Present: 52, Skipped: 0, Leave: 8, Absent: 0 },
    rules: RULES,
  });
  assert.equal(result.rebatePrice, 8 * 5000);
  assert.equal(result.totalPrice, 600000 - 40000);
});

test('skips rebate the allowance percentage of a meal, not the flat amount', () => {
  const result = calculateBillAmounts({
    ...APRIL,
    counts: { Present: 55, Skipped: 5, Leave: 0, Absent: 0 },
    rules: RULES,
  });
  // 5 skips x 10000 per meal x 20% = 10000. Deliberately different from the
  // leave rebate, which would have been 5 x 5000 = 25000.
  assert.equal(result.rebatePrice, 10000);
});

test('absent days only rebate when the mess allows it', () => {
  const counts = { Present: 54, Skipped: 0, Leave: 0, Absent: 6 };

  const notAllowed = calculateBillAmounts({ ...APRIL, counts, rules: RULES });
  assert.equal(notAllowed.rebatePrice, 0);

  const allowed = calculateBillAmounts({
    ...APRIL,
    counts,
    rules: { ...RULES, allowAbsentRebate: true },
  });
  assert.equal(allowed.rebatePrice, 6 * 5000);
});

test('rebates can never exceed the base charge', () => {
  const result = calculateBillAmounts({
    ...APRIL,
    counts: { Present: 0, Skipped: 0, Leave: 60, Absent: 0 },
    rules: RULES,
  });
  // 60 leave meals x 5000 = 300000, which is under the 600000 base, so no
  // clamp yet - but push the rebate rate up and it must stop at the base.
  assert.equal(result.rebatePrice, 300000);

  const clamped = calculateBillAmounts({
    ...APRIL,
    counts: { Present: 0, Skipped: 0, Leave: 60, Absent: 0 },
    rules: { ...RULES, rebatePerThaliPrice: 20000 },
  });
  assert.equal(clamped.rebatePrice, 600000, 'rebate is capped at the base charge');
  assert.equal(clamped.totalPrice, 0);
});

test('the minimum monthly charge acts as a floor', () => {
  const result = calculateBillAmounts({
    ...APRIL,
    counts: { Present: 20, Skipped: 0, Leave: 40, Absent: 0 },
    rules: { ...RULES, minMonthlyChargePrice: 500000 },
  });
  assert.equal(result.rebatePrice, 200000); // would leave 400000
  assert.equal(result.totalPrice, 500000); // floored
});

test('proration is computed from the ratio so rounding cannot pile up', () => {
  // 31-day month, both meals = 62 meals, at a rate that does not divide evenly.
  const result = calculateBillAmounts({
    monthlyRatePrice: 500000,
    totalMealsInMonth: 62,
    activeMeals: 61,
    counts: { Present: 61, Skipped: 0, Leave: 0, Absent: 0 },
    rules: RULES,
  });
  // Straight from the ratio: 500000 * 61 / 62 = 491935.48 -> 491935.
  // Multiplying a rounded per-meal price (8065) by 61 would give 491965 -
  // thirty units of drift on a single bill.
  assert.equal(result.basePrice, 491935);
});

test('window is the overlap of the membership and the requested period', () => {
  const membership = { active_start: '2026-04-10', active_end: null, discontinuation_date: null };
  const window = resolveBillingWindow(membership, '2026-04-01', '2026-05-01');
  assert.deepEqual(window, { windowStart: '2026-04-10', windowEnd: '2026-05-01' });
});

test('window is null when the membership never overlapped the month', () => {
  const joinedNextMonth = {
    active_start: '2026-05-01',
    active_end: null,
    discontinuation_date: null,
  };
  assert.equal(resolveBillingWindow(joinedNextMonth, '2026-04-01', '2026-05-01'), null);

  const neverActivated = { active_start: null, active_end: null, discontinuation_date: null };
  assert.equal(resolveBillingWindow(neverActivated, '2026-04-01', '2026-05-01'), null);
});

test('a pending discontinuation caps the window at the request date', () => {
  const membership = {
    active_start: '2026-04-01',
    active_end: null, // manager has not approved yet
    discontinuation_date: '2026-04-16',
  };
  const window = resolveBillingWindow(membership, '2026-04-01', '2026-05-01');
  // Exclusive end: they are billed up to and including the 15th.
  assert.deepEqual(window, { windowStart: '2026-04-01', windowEnd: '2026-04-16' });
});

test('the earliest of every end date wins', () => {
  const membership = {
    active_start: '2026-04-01',
    active_end: '2026-04-20',
    discontinuation_date: '2026-04-12',
  };
  const window = resolveBillingWindow(membership, '2026-04-01', '2026-05-01');
  assert.equal(window.windowEnd, '2026-04-12');
});
