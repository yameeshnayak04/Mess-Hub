// This file contains all logic for the on-premise Kiosk tablet.

const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');

// @desc    Get the list of active members for the Kiosk grid
// @route   GET /api/kiosk/messes/:messId/active-members
// @access  Public (Kiosk)
const getActiveMembers = async (req, res) => {
    try {
        const { messId } = req.params;
        const { startOfDay, endOfDay } = getTodayTimeRange(); // Helper from manager controller

        // 1. Find all active members of the mess.
        const memberships = await Membership.find({ mess: messId, status: 'active' }).select('customer');
        const memberIds = memberships.map(m => m.customer);

        // 2. Find members who have already eaten today.
        const mealsEaten = await MealRecord.find({
            mess: messId,
            customer: { $in: memberIds },
            createdAt: { $gte: startOfDay, $lte: endOfDay }
        });
        const eatenMemberIds = mealsEaten.map(m => m.customer.toString());

        // 3. Filter out members who have already eaten.
        const remainingMemberIds = memberIds.filter(id => !eatenMemberIds.includes(id.toString()));

        // TODO: Filter out members on leave today.

        // 4. Fetch the final list of members to display.
        const activeMembers = await User.find({ _id: { $in: remainingMemberIds } }).select('name photoUrl');
        
        res.status(200).json(activeMembers);

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Log a meal for a monthly member via PIN verification
// @route   POST /api/kiosk/messes/:messId/log-monthly
// @access  Public (Kiosk)
const logMonthlyMeal = async (req, res) => {
    const { messId } = req.params;
    const { userId, pin, mealType } = req.body;

    try {
        // Find the user and explicitly select the 'pin' field, which is normally hidden.
        const user = await User.findById(userId).select('+pin');
        if (!user || !user.pin) {
            return res.status(401).json({ message: 'Invalid user or PIN not set.' });
        }

        // Use the method we defined in the user model to compare the entered PIN.
        const isPinCorrect = await user.comparePin(pin);
        if (!isPinCorrect) {
            return res.status(401).json({ message: 'Incorrect PIN.' });
        }

        // --- At this point, PIN is correct ---
        // Create the meal record.
        await MealRecord.create({ mess: messId, customer: userId, mealType });

        res.status(201).json({ message: `Meal logged successfully for ${user.name}.` });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

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
    const { userId, managerPin } = req.body;

    try {
        const mess = await Mess.findById(messId);
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        // Find the manager of this mess and check their PIN.
        const manager = await User.findById(mess.owner).select('+pin');
        if (!manager || !manager.pin) return res.status(403).json({ message: 'Manager PIN not set.' });

        const isPinCorrect = await manager.comparePin(managerPin);
        if (!isPinCorrect) return res.status(403).json({ message: 'Incorrect Manager PIN.' });

        // --- Manager PIN is correct ---
        // Log the meal for the specified user and set the override flag.
        await MealRecord.create({
            mess: messId,
            customer: userId,
            mealType: 'Lunch', // Simplified, could get mealType from request
            isManagerOverride: true,
        });

        res.status(201).json({ message: 'Manager override successful. Meal logged.' });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// Helper function needed by this controller
const getTodayTimeRange = () => {
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(); endOfDay.setHours(23, 59, 59, 999);
    return { startOfDay, endOfDay };
};


module.exports = {
    getActiveMembers,
    logMonthlyMeal,
    logDailyMeal,
    managerOverride,
};