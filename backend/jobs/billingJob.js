// jobs/billingJob.js
const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance');
const { getStartAndEndOfMonth } = require('../utils/billCalculation');
// The main server.js process already handles the DB connection.

/**
 * This is the main function triggered by the API route.
 * It does NOT schedule itself.
 */
async function runBillingJob() {
  console.log('--- JOB: Running Monthly Billing Job (Triggered by API) ---');

  // 1. Determine the target billing period (previous month)
  const now = new Date();
  // This correctly gets the *last* day of the *previous* month
  const prevMonthDate = new Date(now.getFullYear(), now.getMonth(), 0); 
  const billingMonth = prevMonthDate.getMonth() + 1; // getMonth() is 0-indexed
  const billingYear = prevMonthDate.getFullYear();
  
  console.log(`[Billing Job] Generating bills for period: ${billingMonth}/${billingYear}`);

  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

  try {
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
      if (messResult.success) {
        results.success.push(messResult);
      } else {
        results.failed.push(messResult);
      }
    }

    console.log(`[Billing Job] Completed. Success: ${results.success.length}, Failed: ${results.failed.length}`);
    if (results.failed.length > 0) {
      console.error('[Billing Job] Failed messes:', JSON.stringify(results.failed, null, 2));
    }
  } catch (error) {
    console.error('[Billing Job] Fatal error during monthly billing:', error);
  }
}

/**
 * This is your existing core logic. It is correct.
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

      for (const member of members) {
        // Skip if bill already exists
        const existingBill = await Bill.exists({
          user: member.user,
          mess: mess._id,
          month: billingMonth,
          year: billingYear
        }).session(session);

        if (existingBill) {
          continue;
        }

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
    });
    return { success: true, messId: mess._id, messName: mess.messName, billsCreated: billsCreatedCount };
  } catch (error) {
    console.error(`[Billing Job][${mess.messName}] Transaction failed:`, error);
    return { success: false, messId: messId, messName: mess.messName, error: error.message };
  } finally {
    session.endSession();
  }
};

// --- ALL 'cron.schedule' CODE IS REMOVED ---

// Export the main function so 'jobRoutes.js' can import it
module.exports = { runBillingJob };