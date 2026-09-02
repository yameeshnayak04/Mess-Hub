// new_backend/jobs/billingJob.js
//
// Runs on the 1st of each month and bills everyone for the month just gone.

const knex = require('../db/knex');
const billingService = require('../services/billingService');
const { runTrackedJob } = require('./jobRunner');
const { getTodayInIndia } = require('../services/messClock');
const { addMonths, firstDayOfMonth } = require('../utils/dates');

// Who gets billed for a month: anyone whose membership *overlapped* that
// month, not just those who are Active right now.
//
// The difference matters. Someone who left on the 20th of last month is
// already Inactive by the time this runs on the 1st, so filtering on current
// status would skip them forever. Selecting on the date range instead means
// this job doubles as a safety net: if the partial bill created when they
// asked to leave failed for any reason, this run still catches it. Re-billing
// someone who was already billed is harmless because generateBillForMembership
// refuses to touch a bill that is already Paid or awaiting approval.
async function findMembershipsToBill(periodStart, periodEnd) {
  const rows = await knex('memberships')
    .select('id')
    .whereRaw('active_period && daterange(?::date, ?::date, ?)', [periodStart, periodEnd, '[)'])
    .orderBy('id');
  return rows.map((row) => row.id);
}

async function generateMonthlyBills({ periodStart } = {}) {
  const today = await getTodayInIndia();
  // Default: the month that just ended.
  const start = periodStart || addMonths(firstDayOfMonth(today), -1);
  const end = addMonths(start, 1);

  return runTrackedJob('monthly_billing', start, async () => {
    const membershipIds = await findMembershipsToBill(start, end);

    const succeeded = [];
    const failed = [];

    // Deliberately one transaction per membership rather than one giant one.
    // If a single member has incomplete attendance, only their bill fails -
    // everyone else's still gets written. One long transaction would roll the
    // whole month back because of one member, and would likely hit Postgres'
    // transaction time limits on a large mess.
    for (const membershipId of membershipIds) {
      try {
        await knex.transaction(async (trx) => {
          await billingService.generateBillForMembership(trx, {
            membershipId,
            periodStart: start,
          });
        });
        succeeded.push(membershipId);
      } catch (error) {
        failed.push({ membershipId, reason: error.message });
      }
    }

    if (failed.length > 0) {
      console.warn(`[billing] ${failed.length} membership(s) could not be billed for ${start}`);
    }

    return {
      rowsAffected: succeeded.length,
      period: start,
      billed: succeeded.length,
      failed,
    };
  });
}

module.exports = { generateMonthlyBills };
