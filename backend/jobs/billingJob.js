// jobs/billingJob.js
const cron = require('node-cron');
const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance');
const { getStartAndEndOfMonth } = require('../utils/billCalculation');

/**
 * Generates bills for the PREVIOUS month for all active members in all messes.
 * Each mess is processed in isolation to prevent cascading failures.
 */
const generateBillsForPreviousMonth = async () => {
  console.log('--- Running Monthly Billing Job ---');

  // 1. Determine the target billing period (previous month)
  const now = new Date();
  const prevMonthDate = new Date(now.getFullYear(), now.getMonth(), 0);
  const billingMonth = prevMonthDate.getMonth() + 1;
  const billingYear = prevMonthDate.getFullYear();
  console.log(`[Billing Job] Generating bills for period: ${billingMonth}/${billingYear}`);

  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

  try {
    // 2. Get all messes
    const messes = await Mess.find({});
    console.log(`[Billing Job] Found ${messes.length} mess(es)`);

    const results = { success: [], failed: [] };

    // 3. Process each mess independently
    for (const mess of messes) {
      const messResult = await processSingleMess(
        mess,
        billingMonth,
        billingYear,
        startOfMonth,
        endOfMonth
      );
      if (messResult.success) results.success.push(messResult);
      else results.failed.push(messResult);
    }

    console.log(`[Billing Job] Completed. Success: ${results.success.length}, Failed: ${results.failed.length}`);
    if (results.failed.length > 0) {
      console.error('[Billing Job] Failed messes:', JSON.stringify(results.failed, null, 2));
    }
  } catch (error) {
    console.error('[Billing Job] Fatal error during monthly billing:', error);
  }
};

/**
 * Process billing for a single mess in isolation
 */
const processSingleMess = async (mess, billingMonth, billingYear, startOfMonth, endOfMonth) => {
  const session = await mongoose.startSession();
  try {
    let billsCreatedCount = 0;

    await session.withTransaction(async () => {
      // Find all active memberships for this mess
      const members = await Membership.find({
        mess: mess._id,
        status: 'Active'
      }).session(session);

      console.log(`[Billing Job][${mess.messName}] Processing ${members.length} active members`);

      for (const member of members) {
        // Skip if bill already exists
        const existingBill = await Bill.exists({
          user: member.user,
          mess: mess._id,
          month: billingMonth,
          year: billingYear
        }).session(session);

        if (existingBill) {
          console.log(`[Billing Job][${mess.messName}] Bill already exists for user ${member.user}`);
          continue;
        }

        // --- FIX 1: Plan-based rebate filtering ---
        const planName = String(member.planName).toLowerCase();
        const mealsInPlan = [];
        if (planName.includes('both')) mealsInPlan.push('Lunch', 'Dinner');
        else if (planName.includes('lunch')) mealsInPlan.push('Lunch');
        else if (planName.includes('dinner')) mealsInPlan.push('Dinner');

        // Count skipped meals ONLY for meals in the plan
        const skippedMeals = await Attendance.countDocuments({
          membership: member._id,
          date: { $gte: startOfMonth, $lte: endOfMonth },
          status: 'Skipped',
          mealType: { $in: mealsInPlan }
        }).session(session);

        // Count leave meals ONLY for meals in the plan
        const leaveMeals = await Attendance.countDocuments({
          membership: member._id,
          date: { $gte: startOfMonth, $lte: endOfMonth },
          status: 'Leave',
          mealType: { $in: mealsInPlan }
        }).session(session);

        // Calculate rebates
        const rebatePerThali = mess.rules.rebatePerThali || 0;
        const skipAllowancePercent = mess.rules.skipAllowancePercent || 50;
        const skipRebate = skippedMeals * rebatePerThali * (skipAllowancePercent / 100);
        const leaveRebate = leaveMeals * rebatePerThali;
        const rebateAmount = Math.round((leaveRebate + skipRebate) * 100) / 100;

        // --- FIX 2: Keep full monthly billing (no proration) ---
        // Use the member's current billing rate for the full month
        const baseAmount = member.billingRate;
        let totalAmount = baseAmount - rebateAmount;

        // Apply minimum charge
        const minMonthlyCharge = mess.rules.minMonthlyCharge || 0;
        if (totalAmount < minMonthlyCharge) {
          totalAmount = minMonthlyCharge;
        }

        totalAmount = Math.round(totalAmount * 100) / 100;

        // Create bill
        await Bill.create(
          [{
            user: member.user,
            mess: mess._id,
            month: billingMonth,
            year: billingYear,
            baseAmount,
            rebateAmount,
            totalAmount,
            status: 'Due'
          }],
          { session }
        );

        billsCreatedCount++;

        // Update billing rate for next cycle (based on current plan)
        const updatedRate =
          mess.plans.find(p => p.name.toLowerCase() === planName)?.pricePerMonth || member.billingRate;

        member.billingRate = updatedRate;
        await member.save({ session });
      }

      console.log(`[Billing Job][${mess.messName}] Created ${billsCreatedCount} bill(s)`);
    });

    return { success: true, messId: mess._id, messName: mess.messName, billsCreated: billsCreatedCount };
  } catch (error) {
    console.error(`[Billing Job][${mess.messName}] Transaction failed:`, error);
    return { success: false, messId: mess._id, messName: mess.messName, error: error.message };
  } finally {
    session.endSession();
  }
};

/**
 * Schedule the billing job to run at midnight on the 1st of every month (IST)
 */
const scheduleBillingJob = () => {
  cron.schedule(
    '0 0 1 * *',
    () => {
      console.log('[Cron] Starting monthly billing job');
      generateBillsForPreviousMonth();
    },
    { scheduled: true, timezone: 'Asia/Kolkata' }
  );
  console.log('[Cron] Monthly billing job scheduled for 1st of every month at midnight IST');
};

module.exports = { scheduleBillingJob, generateBillsForPreviousMonth };
