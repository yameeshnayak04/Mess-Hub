// jobs/billingJob.js
const mongoose = require('mongoose');
// const cron = require('node-cron'); // <--- DELETED
const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance');
const connectDB = require('../config/db'); // <-- ADDED
const { getStartAndEndOfMonth } = require('../utils/billCalculation'); // <-- ADDED

// Helper: derive plan meals from planName (from your file)
function mealsInPlan(planName) {
  const p = String(planName || '').toLowerCase();
  if (p.includes('both')) return ['Lunch', 'Dinner'];
  if (p.includes('lunch')) return ['Lunch'];
  if (p.includes('dinner')) return ['Dinner'];
  return [];
}

async function processMessForPeriod(mess, billingMonth, billingYear, startOfMonth, endOfMonth) {
  const session = await mongoose.startSession();
  try {
    let billsCreatedCount = 0;

    await session.withTransaction(async () => {
      const activeMembers = await Membership.find({ mess: mess._id, status: 'Active' }).session(session);

      for (const member of activeMembers) {
        const exists = await Bill.exists({
          user: member.user,
          mess: mess._id,
          month: billingMonth,
          year: billingYear
        }).session(session);

        if (exists) continue;

        const includedMeals = mealsInPlan(member.planName);
        const skippedMeals = await Attendance.countDocuments({
          membership: member._id,
          mess: mess._id,
          date: { $gte: startOfMonth, $lte: endOfMonth },
          mealType: { $in: includedMeals },
          status: 'Skipped'
        }).session(session);

        const leaveMeals = await Attendance.countDocuments({
          membership: member._id,
          mess: mess._id,
          date: { $gte: startOfMonth, $lte: endOfMonth },
          mealType: { $in: includedMeals },
          status: 'Leave'
        }).session(session);

        const baseAmount = Number(member.billingRate || 0);
        const rules = mess.rules || {};
        const rebatePerThali = Number(rules.rebatePerThali || 0);
        const skipAllowancePercent = Number(rules.skipAllowancePercent || 50);
        const minMonthlyCharge = Number(rules.minMonthlyCharge || 0);

        const skipRebate = skippedMeals * rebatePerThali * (skipAllowancePercent / 100);
        const leaveRebate = leaveMeals * rebatePerThali;
        const rebateAmount = Math.max(0, Math.round((skipRebate + leaveRebate) * 100) / 100);

        let totalAmount = Math.max(minMonthlyCharge, Math.round((baseAmount - rebateAmount) * 100) / 100);

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

        billsCreatedCount++;

        const planKey = String(member.planName || '').toLowerCase();
        const matchedPlan = Array.isArray(mess.plans)
          ? mess.plans.find(p => String(p.name || '').toLowerCase() === planKey)
          : null;
        const nextRate = matchedPlan && typeof matchedPlan.rate === 'number'
          ? matchedPlan.rate
          : member.billingRate;
        if (typeof nextRate === 'number' && nextRate !== member.billingRate) {
          member.billingRate = nextRate;
          await member.save({ session });
        }
      }
    });

    return { success: true, messId: mess._id, messName: mess.messName, billsCreated: billsCreatedCount };
  } catch (err) {
    return { success: false, messId: mess._id, messName: mess.messName, error: err.message };
  } finally {
    session.endSession();
  }
}

/**
 * Generate bills for the previous month across all messes
 */
async function runBillingJob() {
  await connectDB(); // <-- ADDED: Must connect to DB
  console.log('--- JOB: Running Monthly Billing Job ---');

  const now = new Date();
  const prevMonthDate = new Date(now.getFullYear(), now.getMonth(), 0);
  const billingMonth = prevMonthDate.getMonth() + 1;
  const billingYear = prevMonthDate.getFullYear();
  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

  const messes = await Mess.find({});
  const results = [];

  for (const mess of messes) {
    const r = await processMessForPeriod(mess, billingMonth, billingYear, startOfMonth, endOfMonth);
    results.push(r);
  }

  const ok = results.filter(r => r.success).length;
  const fail = results.length - ok;
  console.log(`[Billing Job] Completed for ${results.length} mess(es). Success: ${ok}, Failed: ${fail}`);
  if (fail) console.error('[Billing Job] Failures:', results.filter(r => !r.success));

  return results;
}

// --- DELETED 'scheduleBillingJob' function ---

module.exports = { runBillingJob }; // <-- CLEANED EXPORT