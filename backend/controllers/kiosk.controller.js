// controllers/kiosk.controller.js
const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const asyncHandler = require('../utils/asynchandler.js');

const startOfDay = (d) => { const x = new Date(d); x.setHours(0,0,0,0); return x; };
const getMealTypeByNow = (mess) => {
  const now = new Date();
  const today = startOfDay(now);
  const lunchEnd = mess.timings?.lunch?.end && new Date(today.setHours(...mess.timings.lunch.end.split(':').map(Number)));
  const dinnerEnd = mess.timings?.dinner?.end && new Date(startOfDay(new Date()).setHours(...mess.timings.dinner.end.split(':').map(Number)));
  if (lunchEnd && now <= lunchEnd) return 'Lunch';
  return 'Dinner';
};

// Get Active Members
const getActiveMembers = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const mess = await Mess.findById(messId);
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  const mealType = req.query.mealType || getMealTypeByNow(mess);
  const today = startOfDay(new Date());
  const memberships = await Membership.find({ mess: messId, status: 'active' }).select('_id customer');
  const ids = memberships.map(m => m._id);
  const [eaten, onLeave, toggled] = await Promise.all([
    MealRecord.find({ mess: messId, membership: { $in: ids }, date: today, mealType }).select('membership'),
    Leave.find({ membership: { $in: ids }, startDate: { $lte: today }, endDate: { $gte: today } }).select('membership'),
    MealSkip.find({ membership: { $in: ids }, date: today, mealType }).select('membership'),
  ]);
  const exclude = new Set([...eaten, ...onLeave, ...toggled].map(x => String(x.membership)));
  const remainingMemberships = memberships.filter(m => !exclude.has(String(m._id)));
  const users = await User.find({ _id: { $in: remainingMemberships.map(m => m.customer) } }).select('name photoUrl phone');
  res.status(200).json({ mealType, members: users });
});

// Log Monthly Meal (PIN)
const logMonthlyMeal = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { membershipId, pin, mealType } = req.body;
  if (!membershipId || !pin || !mealType) { res.status(400); throw new Error('membershipId, pin, mealType are required'); }
  const membership = await Membership.findById(membershipId).populate('mess').populate({ path: 'customer', select: '+pin' });
  if (!membership || String(membership.mess._id) !== String(messId)) { res.status(404); throw new Error('Membership not found for this mess'); }
  const customer = membership.customer;
  if (!customer?.pin) { res.status(401); throw new Error('Customer has not set a PIN'); }
  const ok = await customer.comparePin(pin);
  if (!ok) { res.status(401); throw new Error('Incorrect PIN'); }
  const today = startOfDay(new Date());
  const exists = await MealRecord.findOne({ mess: messId, membership: membershipId, date: today, mealType });
  if (exists) { res.status(400); throw new Error('Meal already logged for this member today'); }
  await MealRecord.create({ mess: messId, membership: membershipId, date: today, mealType });
  res.status(201).json({ message: `Meal logged for ${customer.name}` });
});

// Mark Attendance (alias to logMonthlyMeal)
const markAttendance = logMonthlyMeal;

// Log Daily Meal (walk-in, only when serviceType === 'Both')
const logDailyMeal = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { mealType } = req.body;
  if (!['Lunch', 'Dinner'].includes(mealType)) { res.status(400); throw new Error('Invalid mealType'); }
  const mess = await Mess.findById(messId);
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  if (mess.serviceType !== 'Both') { res.status(400); throw new Error('Daily walk-ins are not allowed for this mess'); }
  await MealRecord.create({ mess: messId, membership: null, date: startOfDay(new Date()), mealType });
  res.status(201).json({ message: 'Daily meal logged' });
});

module.exports = { getActiveMembers, logMonthlyMeal, markAttendance, logDailyMeal };
