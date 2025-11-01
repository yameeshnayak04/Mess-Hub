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
 * This is the single source of truth for billing.
 */
const generateBillsForPreviousMonth = async () => {
  console.log('--- Running Monthly Billing Job ---');
  
  // 1. Determine the target billing period (previous month)
  const now = new Date();
  // Get last day of previous month to correctly get its month/year
  const prevMonthDate = new Date(now.getFullYear(), now.getMonth(), 0); 
  const billingMonth = prevMonthDate.getMonth() + 1;
  const billingYear = prevMonthDate.getFullYear();
  
  console.log(`[Billing Job] Generating bills for period: ${billingMonth}/${billingYear}`);
  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

  const session = await mongoose.startSession();
  let totalBillsGenerated = 0;

  try {
    await session.withTransaction(async () => {
      // 2. Find all messes to process
      const messes = await Mess.find({}).session(session);

      for (const mess of messes) {
        // 3. Find all active members for this mess
        const activeMembers = await Membership.find({ 
          mess: mess._id, 
          status: 'Active' 
        }).session(session);
        
        if (activeMembers.length === 0) continue;

        // 4. Get mess rules once
        const rules = mess.rules || {};
        const rebatePerThali = Number(rules.rebatePerThali || 0);
        const skipAllowancePercent = Number(rules.skipAllowancePercent || 0);
        const minMonthlyCharge = Number(rules.minMonthlyCharge || 0);

        // 5. Process each member
        for (const member of activeMembers) {
          // Avoid duplicate bill
          const exists = await Bill.exists({
            user: member.user,
            mess: mess._id,
            month: billingMonth,
            year: billingYear
          });
          if (exists) continue;

          const baseAmount = Number(member.billingRate || 0);

          // --- Calculate Rebates based *only* on the Attendance table ---
          // This is the single source of truth.

          // Count 'Skipped' meals (eligible for partial/full rebate)
          const skippedMeals = await Attendance.countDocuments({
            membership: member._id,
            date: { $gte: startOfMonth, $lte: endOfMonth },
            status: 'Skipped'
          }).session(session);

          // Count 'Leave' meals (eligible for full rebate)
          const leaveMeals = await Attendance.countDocuments({
            membership: member._id,
            date: { $gte: startOfMonth, $lte: endOfMonth },
            status: 'Leave'
          }).session(session);

          // 'Absent' status provides NO rebate.

          // Calculate final rebate amounts
          const skipRebate = skippedMeals * rebatePerThali * (skipAllowancePercent / 100);
          const leaveRebate = leaveMeals * rebatePerThali;
          const rebateAmount = Math.round((leaveRebate + skipRebate) * 100) / 100; // Round to 2 decimal places

          // Calculate total, respecting minimum charge
          let totalAmount = Math.max(0, baseAmount - rebateAmount);
          if (totalAmount < minMonthlyCharge) {
            totalAmount = minMonthlyCharge;
          }
          totalAmount = Math.round(totalAmount * 100) / 100;

          // 6. Create the bill
          await Bill.create([{
            user: member.user,
            mess: mess._id,
            month: billingMonth,
            year: billingYear,
            baseAmount,
            rebateAmount,
            totalAmount,
            status: 'Due'
          }], { session });
          totalBillsGenerated++;

          // 7. Update member's billingRate for the *next* cycle
          //    (based on any scheduled mess plan updates)
          const currentPlan = mess.plans?.find(
            p => p.name?.toLowerCase() === member.planName?.toLowerCase()
          );
          if (currentPlan && typeof currentPlan.rate === 'number' && member.billingRate !== currentPlan.rate) {
            member.billingRate = currentPlan.rate;
            await member.save({ session });
          }
        }
      }
    });
    console.log(`[Billing Job] Successfully generated ${totalBillsGenerated} bills.`);

  } catch (error) {
    console.error('[Billing Job] Error during automated bill generation:', error);
  } finally {
    session.endSession();
  }
};

// Schedule to run at 00:00 (midnight) on the 1st day of every month
cron.schedule('0 0 1 * *', generateBillsForPreviousMonth, {
  timezone: "Asia/Kolkata" // Specify your timezone
});

console.log('Automated Billing Job scheduled for 1st of every month at 00:00 (Asia/Kolkata)');

module.exports = { generateBillsForPreviousMonth };
