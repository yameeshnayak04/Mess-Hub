// jobs/absentJob.js
const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Leave = require('../models/Leave');
const { startOfDay, endOfDay, checkMealTiming } = require('../utils/billCalculation');
// The main server.js process already handles the DB connection.

/**
 * This is the main function triggered by the API route.
 * It does NOT schedule itself.
 */
async function runAbsentJob() {
  console.log('--- JOB: Running Absent Job (Triggered by API) ---');

  try {
    // Run for both meals. The function will internally check if it's time.
    await markAbsentForMeal('Lunch');
    await markAbsentForMeal('Dinner');
    console.log('--- JOB: Absent Job Completed ---');
  } catch (err) {
    console.error('--- JOB ERROR (Absent):', err);
  }
}

/**
 * Your existing logic to mark a single meal type as absent.
 * This logic is perfectly fine.
 */
async function markAbsentForMeal(mealType) {
  const today = new Date();
  const dayStart = startOfDay(today);
  const dayEnd = endOfDay(today);

  const messes = await Mess.find({});
  for (const mess of messes) {
    // Check if the meal window for this mess is over
    const timing = checkMealTiming(mess.timings, mealType);
    if (!timing.isPast) {
      // console.log(`Skipping ${mealType} for ${mess.messName}, meal not over.`);
      continue; // Only run if mealtime is over
    }

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
        if (e.code !== 11000) { // Ignore duplicate key errors (rare race condition)
          console.error("Error creating Absent record:", e);
        }
      }
    }
  }
}

// --- ALL 'cron.schedule' CODE IS REMOVED ---

// Export the main function so 'jobRoutes.js' can import it
module.exports = { runAbsentJob };