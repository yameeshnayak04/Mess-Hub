// backend/jobs/billingJob.js
const cron = require('node-cron');
const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance');
const { getStartAndEndOfMonth } = require('../utils/billCalculation');

async function runBillingJob() {
  console.log('--- JOB: Running Monthly Billing Job (Triggered) ---');
  const now = new Date();
  const prevMonthDate = new Date(now.getFullYear(), now.getMonth(), 0);
  const billingMonth = prevMonthDate.getMonth() + 1;
  const billingYear = prevMonthDate.getFullYear();
  console.log(`[Billing Job] Period: ${billingMonth}/${billingYear}`);

  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

  try {
    const messes = await Mess.find({});
    const results = { success: [], failed: [] };

    for (const mess of messes) {
      const messResult = await processSingleMess(
        mess, billingMonth, billingYear, startOfMonth, endOfMonth
      );
      if (messResult.success) results.success.push(messResult);
      else results.failed.push(messResult);
    }

    console.log(`[Billing Job] Done. Success: ${results.success.length}, Failed: ${results.failed.length}`);
    if (results.failed.length) console.error('[Billing Job] Failed:', JSON.stringify(results.failed, null, 2));
    return results;
  } catch (error) {
    console.error('[Billing Job] Fatal error:', error);
    throw error;
  }
}

const processSingleMess = async (mess, billingMonth, billingYear, startOfMonth, endOfMonth) => {
  const session = await mongoose.startSession();
  try {
    let billsCreatedCount = 0;
    await session.withTransaction(async () => {
      const members = await Membership.find({ mess: mess._id, status: 'Active' }).session(session);

      for (const member of members) {
        const existingBill = await Bill.exists({
          user: member.user, mess: mess._id, month: billingMonth, year: billingYear
        }).session(session);
        if (existingBill) continue;

        const planName = String(member.planName).toLowerCase();
        const mealsInPlan = [];
        if (planName.includes('both')) mealsInPlan.push('Lunch', 'Dinner');
        else if (planName.includes('lunch')) mealsInPlan.push('Lunch');
        else if (planName.includes('dinner')) mealsInPlan.push('Dinner');

        const skippedMeals = await Attendance.countDocuments({
          membership: member._id, date: { $gte: startOfMonth, $lte: endOfMonth }, status: 'Skipped', mealType: { $in: mealsInPlan }
        }).session(session);

        const leaveMeals = await Attendance.countDocuments({
          membership: member._id, date: { $gte: startOfMonth, $lte: endOfMonth }, status: 'Leave', mealType: { $in: mealsInPlan }
        }).session(session);

        const rebatePerThali = mess.rules.rebatePerThali || 0;
        const skipAllowancePercent = mess.rules.skipAllowancePercent || 50;
        const skipRebate = skippedMeals * rebatePerThali * (skipAllowancePercent / 100);
        const leaveRebate = leaveMeals * rebatePerThali;
        const rebateAmount = Math.round((leaveRebate + skipRebate) * 100) / 100;

        const baseAmount = member.billingRate;
        let totalAmount = baseAmount - rebateAmount;
        const minMonthlyCharge = mess.rules.minMonthlyCharge || 0;
        if (totalAmount < minMonthlyCharge) totalAmount = minMonthlyCharge;
        totalAmount = Math.round(totalAmount * 100) / 100;

        await Bill.create([{
          user: member.user, mess: mess._id, month: billingMonth, year: billingYear,
          baseAmount, rebateAmount, totalAmount, status: 'Due'
        }], { session });
        billsCreatedCount++;

        const updatedRate =
          mess.plans.find(p => p.name.toLowerCase() === planName)?.pricePerMonth || member.billingRate;
        member.billingRate = updatedRate;
        await member.save({ session });
      }
    });

    return { success: true, messId: mess._id, messName: mess.messName, billsCreated: billsCreatedCount };
  } catch (error) {
    console.error(`[Billing Job][${mess.messName}] Transaction failed:`, error);
    return { success: false, messId: mess._id, messName: mess.messName, error: error.message };
  } finally {
    session.endSession();
  }
};

// Optional internal scheduler (IST midnight on the 1st): enable with ENABLE_INTERNAL_CRON=true
function scheduleBillingJob() {
  if (process.env.ENABLE_INTERNAL_CRON !== 'true') {
    console.log('[Billing Job] Internal cron disabled (ENABLE_INTERNAL_CRON != true)');
    return;
  }
  // Run at 18:30 UTC on the last day to approximate 00:00 IST on 1st
  cron.schedule('30 18 L * *', async () => {
    try { await runBillingJob(); } catch (e) { /* logged in runBillingJob */ }
  });
  console.log('[Billing Job] Internal cron scheduled at 18:30 UTC on the last day monthly');
}

module.exports = { runBillingJob, scheduleBillingJob };
