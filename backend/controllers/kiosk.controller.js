// This file contains logic for the on-premise Kiosk tablet.

const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');

// @desc    Get the list of active members for the Kiosk grid
// @route   GET /api/kiosk/messes/:messId/active-members
// @access  Public (but should be network-restricted in production)
const getActiveMembers = async (req, res) => {
    try {
        const { messId } = req.params;

        // Find all active memberships for the given mess.
        const memberships = await Membership.find({ mess: messId, status: 'active' })
            .populate('customer', 'name photoUrl'); // Populate customer details.

        // TODO: Filter out members who are on leave today. This requires querying the Leave collection.
        // For now, we return all active members.
        
        // Map the data to a clean format for the Kiosk UI.
        const activeMembers = memberships.map(mem => ({
            userId: mem.customer._id,
            name: mem.customer.name,
            photoUrl: mem.customer.photoUrl,
        }));
        
        res.status(200).json(activeMembers);

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Log a meal for a monthly member
// @route   POST /api/kiosk/messes/:messId/log-monthly
// @access  Public (Kiosk)
const logMonthlyMeal = async (req, res) => {
    const { messId } = req.params;
    const { customerId, mealType } = req.body; // mealType will be 'Lunch' or 'Dinner'

    try {
        // --- VALIDATION ---
        // 1. Check if this user is an active member of this mess.
        const membership = await Membership.findOne({ customer: customerId, mess: messId, status: 'active' });
        if (!membership) {
            return res.status(403).json({ message: 'This user is not an active member of this mess.' });
        }

        // 2. Check if the user has already eaten this meal today.
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);

        const existingRecord = await MealRecord.findOne({
            customer: customerId,
            mess: messId,
            mealType: mealType,
            createdAt: { $gte: startOfDay, $lte: endOfDay }
        });

        if (existingRecord) {
            return res.status(400).json({ message: 'Meal already logged for this user today.' });
        }
        
        // --- LOG MEAL ---
        // Create a new meal record.
        await MealRecord.create({
            customer: customerId,
            mess: messId,
            mealType: mealType,
        });

        res.status(201).json({ message: 'Meal logged successfully.' });

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

    // To log a daily user, we create a meal record without a customer ID.
    // First, let's make sure the mess exists.
    const messExists = await Mess.findById(messId);
    if (!messExists) {
        return res.status(404).json({ message: "Mess not found." });
    }

    try {
        await MealRecord.create({
            mess: messId,
            mealType: mealType,
            // 'customer' field is intentionally left null for daily users.
        });

        res.status(201).json({ message: 'Daily meal logged successfully.' });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

module.exports = {
    getActiveMembers,
    logMonthlyMeal,
    logDailyMeal,
};