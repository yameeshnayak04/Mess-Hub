// controllers/kiosk.controller.js
const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { normalizeToStartOfDay, getCurrentMealType } = require('../utils/timeUtils');

// List active members who have NOT eaten for the target meal today, excluding on-leave and toggle-skipped
const getActiveMembers = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const mess = await Mess.findById(messId);
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }

  const mealType = req.query.mealType || getCurrentMealType(mess);
  const today = normalizeToStartOfDay(new Date());

  const memberships = await Membership.find({ mess: messId, status: 'active' }).select('_id customer');
  const membershipIds = memberships.map(m => m._id);

  const [eaten, onLeave, toggled] = await Promise.all([
    MealRecord.find({ mess: messId, membership: { $in: membershipIds }, date: today, mealType }).select('membership'),
    Leave.find({ membership: { $in: membershipIds }, startDate: { $lte: today }, endDate: { $gte: today } }).select('membership'),
    MealSkip.find({ membership: { $in: membershipIds }, date: today, mealType }).select('membership'),
  ]);

  const exclude = new Set([
    ...eaten.map(x => x.membership.toString()),
    ...onLeave.map(x => x.membership.toString()),
    ...toggled.map(x => x.membership.toString()),
  ]);

  const remainingMemberships = memberships.filter(m => !exclude.has(m._id.toString()));
  const userIds = remainingMemberships.map(m => m.customer);
  const users = await User.find({ _id: { $in: userIds } }).select('name photoUrl');
  res.status(200).json({ mealType, users });
});

// Log meal for monthly member after PIN verification
const logMonthlyMeal = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { membershipId, pin, mealType } = req.body;

  const membership = await Membership.findById(membershipId).populate('mess').populate('customer', '+pin');
  if (!membership || String(membership.mess._id) !== String(messId)) {
    res.status(404);
    throw new Error('Membership not found for this mess.');
  }
  const user = membership.customer;
  if (!user?.pin) {
    res.status(401);
    throw new Error('PIN has not been set.');
  }
  const ok = await user.comparePin(pin);
  if (!ok) {
    res.status(401);
    throw new Error('Incorrect PIN.');
  }

  const today = normalizeToStartOfDay(new Date());
  // unique index will also protect, but check early
  const existing = await MealRecord.findOne({ mess: messId, membership: membershipId, date: today, mealType });
  if (existing) {
    res.status(400);
    throw new Error('Meal already logged for this member for today.');
  }

  await MealRecord.create({ mess: messId, membership: membershipId, date: today, mealType });
  res.status(201).json({ message: `Meal logged successfully for ${user.name}.` });
});

// Log meal for daily user (walk-in)
const logDailyMeal = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { mealType } = req.body;
  const today = normalizeToStartOfDay(new Date());
  await MealRecord.create({ mess: messId, membership: null, date: today, mealType });
  res.status(201).json({ message: 'Daily meal logged successfully.' });
});

// Manager override using manager's PIN
const managerOverride = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { membershipId, managerPin, mealType } = req.body;

  const mess = await Mess.findById(messId);
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const manager = await User.findById(mess.owner).select('+pin');
  if (!manager?.pin) {
    res.status(403);
    throw new Error('Manager PIN not set.');
  }
  const ok = await manager.comparePin(managerPin);
  if (!ok) {
    res.status(403);
    throw new Error('Incorrect Manager PIN.');
  }

  const today = normalizeToStartOfDay(new Date());
  const existing = await MealRecord.findOne({ mess: messId, membership: membershipId, date: today, mealType });
  if (existing) {
    res.status(400);
    throw new Error('Meal already logged for this member for today.');
  }

  await MealRecord.create({ mess: messId, membership: membershipId, date: today, mealType, isManagerOverride: true });
  res.status(201).json({ message: 'Manager override successful. Meal logged.' });
});

module.exports = { getActiveMembers, logMonthlyMeal, logDailyMeal, managerOverride };
