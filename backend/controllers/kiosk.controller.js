// backend/controllers/kiosk.controller.js

const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const { getTodayDateRange } = require('../utils/timeUtils');
const asyncHandler = require('../utils/asynchandler.js');

// @desc    Get the list of active members who have NOT eaten today
// @route   GET /api/kiosk/messes/:messId/active-members
// @access  Public (Kiosk)
const getActiveMembers = asyncHandler(async (req, res) => {
    const { messId } = req.params;
    const { startOfDay, endOfDay } = getTodayDateRange();

    const memberships = await Membership.find({ mess: messId, status: 'active' }).select('customer');
    const memberIds = memberships.map(m => m.customer);

    const mealsEatenRecords = await MealRecord.find({
        mess: messId, customer: { $in: memberIds },
        createdAt: { $gte: startOfDay, $lte: endOfDay }
    });
    const eatenMemberIds = mealsEatenRecords.map(m => m.customer.toString());
    const remainingMemberIds = memberIds.filter(id => !eatenMemberIds.includes(id.toString()));

    // TODO: Further filter out members who are on a formal leave today.
    const activeMembers = await User.find({ _id: { $in: remainingMemberIds } }).select('name photoUrl');
    res.status(200).json(activeMembers);
});

// @desc    Log a meal for a monthly member via PIN verification
// @route   POST /api/kiosk/messes/:messId/log-monthly
// @access  Public (Kiosk)
const logMonthlyMeal = asyncHandler(async (req, res) => {
    const { messId } = req.params;
    const { userId, pin, mealType } = req.body;

    const user = await User.findById(userId).select('+pin');
    if (!user || !user.pin) {
        res.status(401);
        throw new Error('Invalid user or PIN has not been set.');
    }

    const isPinCorrect = await user.comparePin(pin);
    if (!isPinCorrect) {
        res.status(401);
        throw new Error('Incorrect PIN.');
    }
    
    // Check if meal already logged
    const { startOfDay, endOfDay } = getTodayDateRange();
    const existingRecord = await MealRecord.findOne({ customer: userId, mess: messId, mealType, createdAt: { $gte: startOfDay, $lte: endOfDay } });
    if(existingRecord) {
        res.status(400);
        throw new Error('Meal already logged for this user today.');
    }

    await MealRecord.create({ mess: messId, customer: userId, mealType });
    res.status(201).json({ message: `Meal logged successfully for ${user.name}.` });
});

// @desc    Log a meal for a daily (pay-per-meal) user
// @route   POST /api/kiosk/messes/:messId/log-daily
// @access  Public (Kiosk)
const logDailyMeal = asyncHandler(async (req, res) => {
    const { messId } = req.params;
    const { mealType } = req.body;
    await MealRecord.create({ mess: messId, mealType: mealType, membership: null });
    res.status(201).json({ message: 'Daily meal logged successfully.' });
});

// @desc    Manager logs a meal for a user who forgot their PIN
// @route   POST /api/kiosk/messes/:messId/manager-override
// @access  Public (Kiosk)
const managerOverride = asyncHandler(async (req, res) => {
    const { messId } = req.params;
    const { userId, managerPin, mealType } = req.body;

    const mess = await Mess.findById(messId);
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }

    const manager = await User.findById(mess.owner).select('+pin');
    if (!manager || !manager.pin) {
        res.status(403);
        throw new Error('Manager PIN not set.');
    }

    const isManagerPinCorrect = await manager.comparePin(managerPin);
    if (!isManagerPinCorrect) {
        res.status(403);
        throw new Error('Incorrect Manager PIN.');
    }

    // Manager PIN is correct, log the meal for the user with the override flag.
    await MealRecord.create({
        mess: messId,
        customer: userId,
        mealType: mealType,
        isManagerOverride: true,
    });
    res.status(201).json({ message: 'Manager override successful. Meal logged.' });
});

module.exports = { getActiveMembers, logMonthlyMeal, logDailyMeal, managerOverride };