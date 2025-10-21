// controllers/kiosk.controller.js
const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { normalizeToStartOfDay, getCurrentMealType } = require('../utils/timeUtils');

// @desc Get active members who have NOT eaten for the target meal today
// @route GET /api/kiosk/messes/:messId/active-members
// @access Public (Kiosk)
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
  const membershipIds = memberships.map((m) => m._id);

  const [eaten, onLeave, toggled] = await Promise.all([
    MealRecord.find({ mess: messId, membership: { $in: membershipIds }, date: today, mealType }).select(
      'membership'
    ),
    Leave.find({
      membership: { $in: membershipIds },
      startDate: { $lte: today },
      endDate: { $gte: today },
    }).select('membership'),
    MealSkip.find({ membership: { $in: membershipIds }, date: today, mealType }).select('membership'),
  ]);

  const exclude = new Set([
    ...eaten.map((x) => x.membership.toString()),
    ...onLeave.map((x) => x.membership.toString()),
    ...toggled.map((x) => x.membership.toString()),
  ]);

  const remainingMemberships = memberships.filter((m) => !exclude.has(m._id.toString()));
  const userIds = remainingMemberships.map((m) => m.customer);
  const users = await User.find({ _id: { $in: userIds } }).select('name photoUrl phone');

  res.status(200).json({ mealType, members: users });
});

// @desc Log meal for monthly member after customer's PIN verification
// @route POST /api/kiosk/messes/:messId/log-monthly
// @access Public (Kiosk)
const logMonthlyMeal = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { membershipId, pin, mealType } = req.body;

  if (!membershipId || !pin || !mealType) {
    res.status(400);
    throw new Error('Membership ID, PIN, and meal type are required.');
  }

  // Find membership and populate customer with PIN
  const membership = await Membership.findById(membershipId).populate('mess').populate({
    path: 'customer',
    select: '+pin',
  });

  if (!membership || String(membership.mess._id) !== String(messId)) {
    res.status(404);
    throw new Error('Membership not found for this mess.');
  }

  const customer = membership.customer;
  if (!customer) {
    res.status(404);
    throw new Error('Customer not found.');
  }

  // Verify customer's PIN
  if (!customer.pin) {
    res.status(401);
    throw new Error('Customer has not set a PIN. Please ask them to set one first.');
  }

  const isPinValid = await customer.comparePin(pin);
  if (!isPinValid) {
    res.status(401);
    throw new Error('Incorrect PIN. Please try again.');
  }

  // Check if already logged today
  const today = normalizeToStartOfDay(new Date());
  const existing = await MealRecord.findOne({ mess: messId, membership: membershipId, date: today, mealType });
  if (existing) {
    res.status(400);
    throw new Error('Meal already logged for this member today.');
  }

  // Log the meal
  await MealRecord.create({ mess: messId, membership: membershipId, date: today, mealType });
  res.status(201).json({ message: `Meal logged successfully for ${customer.name}.` });
});

// @desc Log meal for daily walk-in user (no PIN required)
// @route POST /api/kiosk/messes/:messId/log-daily
// @access Public (Kiosk)
const logDailyMeal = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { mealType } = req.body;

  if (!mealType) {
    res.status(400);
    throw new Error('Meal type is required.');
  }

  const today = normalizeToStartOfDay(new Date());
  await MealRecord.create({ mess: messId, membership: null, date: today, mealType });
  res.status(201).json({ message: 'Daily meal logged successfully.' });
});

// @desc Manager override to log meal without PIN (authenticated manager only)
// @route POST /api/kiosk/messes/:messId/manager-override
// @access Protected (Manager must be authenticated via token)
const managerOverride = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { membershipId, mealType } = req.body;

  // Manager must be authenticated (this route should be protected by middleware)
  if (!req.user || req.user.role !== 'manager') {
    res.status(403);
    throw new Error('Only authenticated managers can override meal logging.');
  }

  const mess = await Mess.findById(messId);
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }

  // Verify the manager owns this mess
  if (String(mess.owner) !== String(req.user._id)) {
    res.status(403);
    throw new Error('You are not the owner of this mess.');
  }

  const today = normalizeToStartOfDay(new Date());
  const existing = await MealRecord.findOne({ mess: messId, membership: membershipId, date: today, mealType });
  if (existing) {
    res.status(400);
    throw new Error('Meal already logged for this member today.');
  }

  await MealRecord.create({ mess: messId, membership: membershipId, date: today, mealType, isManagerOverride: true });
  res.status(201).json({ message: 'Manager override successful. Meal logged.' });
});

module.exports = { getActiveMembers, logMonthlyMeal, logDailyMeal, managerOverride };
