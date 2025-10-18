// This file contains the final, feature-complete logic for the on-premise Kiosk tablet.

const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');

// --- Helper function ---
const getTodayTimeRange = () => {
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(); endOfDay.setHours(23, 59, 59, 999);
    return { startOfDay, endOfDay };
};

// @desc    Get the list of active members who have NOT eaten today
// @route   GET /api/kiosk/messes/:messId/active-members
// @access  Public (Kiosk)
const getActiveMembers = async (req, res) => {
    try {
        const { messId } = req.params;
        const { startOfDay, endOfDay } = getTodayTimeRange();

        // 1. Get IDs of all active members for this mess.
        const memberships = await Membership.find({ mess: messId, status: 'active' }).select('customer');
        const memberIds = memberships.map(m => m.customer);

        // 2. Get IDs of members who have already eaten today.
        const mealsEatenRecords = await MealRecord.find({
            mess: messId,
            customer: { $in: memberIds },
            createdAt: { $gte: startOfDay, $lte: endOfDay }
        });
        const eatenMemberIds = mealsEatenRecords.map(m => m.customer.toString());

        // 3. Filter out members who have already eaten.
        const remainingMemberIds = memberIds.filter(id => !eatenMemberIds.includes(id.toString()));

        // TODO: Further filter out members who are on a formal leave today.

        // 4. Fetch the profile details for the final list of members to display.
        const activeMembers = await User.find({ _id: { $in: remainingMemberIds } }).select('name photoUrl');
        
        res.status(200).json(activeMembers);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Log a meal for a monthly member via PIN verification
// @route   POST /api/kiosk/messes/:messId/log-monthly
// @access  Public (Kiosk)
const bcrypt = require('bcryptjs');

// @desc    Log a meal for a daily (pay-per-meal) user
// @route   POST /api/kiosk/messes/:messId/log-daily
// @access  Public (Kiosk)
const logDailyMeal = async (req, res) => {
    const { messId } = req.params;
    const { mealType } = req.body;
    try {
        // Create a meal record without a customer ID.
        await MealRecord.create({ mess: messId, mealType: mealType });
        res.status(201).json({ message: 'Daily meal logged successfully.' });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Manager logs a meal for a user who forgot their PIN
// @route   POST /api/kiosk/messes/:messId/manager-override
// @access  Public (Kiosk)
const managerOverride = async (req, res) => {
    const { messId } = req.params;
    const { userId, managerPin, mealType } = req.body;

    try {
        const mess = await Mess.findById(messId);
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        // Find the manager of this mess and verify their PIN.
        const manager = await User.findById(mess.owner).select('+pin');
        if (!manager || !manager.pin) return res.status(403).json({ message: 'Manager PIN not set.' });

        const isManagerPinCorrect = await manager.comparePin(managerPin);
        if (!isManagerPinCorrect) return res.status(403).json({ message: 'Incorrect Manager PIN.' });

        // --- Manager PIN is correct, proceed to log the meal for the user ---
        await MealRecord.create({
            mess: messId,
            customer: userId,
            mealType: mealType,
            isManagerOverride: true, // Set the audit flag
        });

        res.status(201).json({ message: 'Manager override successful. Meal logged.' });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

const logMonthlyMeal = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const { customerId, mealType, pin } = req.body;

    if (!customerId || !mealType || !pin) {
      return res.status(400).json({ message: 'customerId, mealType and pin are required' });
    }

    const user = await User.findById(customerId).select('+kioskPinHash');
    if (!user || !user.kioskPinHash) {
      return res.status(400).json({ message: 'Kiosk PIN not set for this user' });
    }
    const ok = await bcrypt.compare(pin, user.kioskPinHash);
    if (!ok) return res.status(401).json({ message: 'Invalid PIN' });

    // Validate active membership in this mess
    const membership = await Membership.findOne({ user: customerId, mess: messId, status: 'active' });
    if (!membership) return res.status(400).json({ message: 'No active membership' });

    // Validate plan covers current meal
    const isLunch = mealType.toLowerCase() === 'lunch';
    const isDinner = mealType.toLowerCase() === 'dinner';
    const covers =
      membership.mealPlan === 'Full Day' ||
      (membership.mealPlan === 'Lunch' && isLunch) ||
      (membership.mealPlan === 'Dinner' && isDinner);
    if (!covers) return res.status(400).json({ message: 'Plan does not cover this meal' });

    // Respect leave
    const { startOfDay, endOfDay } = getTodayTimeRange();
    const onLeave = await Leave.findOne({
      user: customerId,
      mess: messId,
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay },
      status: 'approved',
    });
    if (onLeave) return res.status(400).json({ message: 'User is on leave today' });

    // Prevent duplicate for same meal today
    const existing = await MealRecord.findOne({
      user: customerId,
      mess: messId,
      mealType: isLunch ? 'Lunch' : 'Dinner',
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    });
    if (existing) return res.status(409).json({ message: 'Already marked today' });

    // Create meal record
    const record = await MealRecord.create({
      user: customerId,
      mess: messId,
      mealType: isLunch ? 'Lunch' : 'Dinner',
      source: 'kiosk',
    });

    return res.status(201).json({ message: 'Meal logged', recordId: record._id });
  } catch (e) {
    next(e);
  }
};

module.exports = {
    getActiveMembers,
    logMonthlyMeal,
    logDailyMeal,
    managerOverride,
    logMonthlyMeal,
};