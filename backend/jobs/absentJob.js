// jobs/absentJob.js
const cron = require('node-cron');
const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Leave = require('../models/Leave');
// FIX: Import from consolidated utility
const { startOfDay, endOfDay, checkMealTiming } = require('../utils/billCalculation');

async function markAbsentForMeal(mealType) {
  const today = new Date();
  const dayStart = startOfDay(today);
  const dayEnd = endOfDay(today);

  // For each mess where meal time has passed
  const messes = await Mess.find({});
  for (const mess of messes) {
    const timing = checkMealTiming(mess.timings, mealType);
    if (!timing.isPast) continue; // Only run if mealtime is over

    // Active memberships in this mess
    const memberships = await Membership.find({ mess: mess._id, status: 'Active' });
    for (const m of memberships) {
      const plan = String(m.planName || '').toLowerCase();
      // Skip if plan doesn't cover this meal
      if (mealType === 'Lunch' && !(plan.includes('lunch') || plan.includes('both'))) continue;
      if (mealType === 'Dinner' && !(plan.includes('dinner') || plan.includes('both'))) continue;

      // Skip if Leave exists today
      const onLeave = await Leave.findOne({ user: m.user, mess: mess._id, startDate: { $lte: dayEnd }, endDate: { $gte: dayStart } });
      if (onLeave) continue;

      // Skip if any attendance already exists (Present, Skipped)
      const exists = await Attendance.findOne({ membership: m._id, date: dayStart, mealType });
      if (exists) continue;

      // If no record exists, and not on leave, mark as 'Absent'
      try {
        await Attendance.create({
          user: m.user,
          membership: m._id,
          mess: mess._id,
          date: dayStart,
          mealType,
          status: 'Absent', // Mark as Absent
          memberType: 'Monthly',
          planNameSnapshot: m.planName,
          rateSnapshot: m.billingRate,
          rebatePerThaliSnapshot: mess.rules.rebatePerThali,
        });
      } catch (e) { 
        if (e.code === 11000) {
          // Rare race condition, ignore duplicate key error
        } else {
          console.error("Error creating Absent record:", e);
        }
      }
    }
  }
}

// run every 5 minutes to check
cron.schedule('*/5 * * * *', async () => {
  // console.log('Checking for meals to mark absent...');
  await markAbsentForMeal('Lunch');
  await markAbsentForMeal('Dinner');
});

console.log('Absentee Job scheduled to run every 5 minutes.');

module.exports = { markAbsentForMeal };
