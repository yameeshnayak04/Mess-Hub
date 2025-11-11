// backend/jobs/absentJob.js
// const cron = require('node-cron'); // <--- DELETED
const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Leave = require('../models/Leave');
const { startOfDay, endOfDay, checkMealTiming } = require('../utils/billCalculation');
const connectDB = require('../config/db'); // <-- ADDED
const TZ_OFFSET_MINUTES = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

async function markAbsentForMeal(mealType) {
  const today = new Date();
  const dayStart = startOfDay(today);
  const dayEnd = endOfDay(today);

  const messes = await Mess.find({});
  for (const mess of messes) {
    const timing = checkMealTiming(mess.timings, mealType, TZ_OFFSET_MINUTES);
    if (!timing.isPast) continue; // Only run if mealtime is over

    const memberships = await Membership.find({ mess: mess._id, status: 'Active' });
    for (const m of memberships) {
      const plan = String(m.planName || '').toLowerCase();
      if (mealType === 'Lunch' && !(plan.includes('lunch') || plan.includes('both'))) continue;
      if (mealType === 'Dinner' && !(plan.includes('dinner') || plan.includes('both'))) continue;

      const onLeave = await Leave.findOne({
        user: m.user, mess: mess._id, startDate: { $lte: dayEnd }, endDate: { $gte: dayStart }
      });
      if (onLeave) continue;

      const exists = await Attendance.findOne({ membership: m._id, date: dayStart, mealType });
      if (exists) continue;

      try {
        await Attendance.create({
          user: m.user, membership: m._id, mess: mess._id, date: dayStart, mealType,
          status: 'Absent', memberType: 'Monthly',
          planNameSnapshot: m.planName, rateSnapshot: m.billingRate,
          rebatePerThaliSnapshot: mess.rules.rebatePerThali,
        });
      } catch (e) {
        if (e.code !== 11000) console.error('Error creating Absent record:', e);
      }
    }
  }
}

async function runAbsentJob() {
  await connectDB(); // <-- ADDED: Must connect to DB on its own
  console.log('--- JOB: Running Absent Job (Triggered) ---');
  try {
    await markAbsentForMeal('Lunch');
    await markAbsentForMeal('Dinner');
    console.log('--- JOB: Absent Job Completed ---');
  } catch (err) {
    console.error('--- JOB ERROR (Absent):', err);
  }
}

// --- DELETED 'scheduleAbsentJob' function ---

module.exports = { runAbsentJob, markAbsentForMeal }; // <-- CLEANED EXPORT
