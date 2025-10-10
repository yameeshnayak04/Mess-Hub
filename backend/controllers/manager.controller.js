// This file contains all logic for the Mess Manager's dashboard and management tasks.

const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');

// @desc    Get the profile of the manager's own mess
// @route   GET /api/managers/my-mess
// @access  Private (Manager only)
const getMyMess = async (req, res) => {
  // The 'protect' and 'isManager' middlewares ensure req.user is a manager.
  try {
    // Find the mess that is owned by the currently logged-in manager.
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
      // This case handles a manager who has registered but not yet created their mess profile.
      return res.status(404).json({ message: 'Mess profile not found for this manager.' });
    }
    res.status(200).json(mess);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};


// @desc    Get live dashboard stats for the manager's mess
// @route   GET /api/managers/my-mess/dashboard-stats
// @access  Private (Manager only)
const getDashboardStats = async (req, res) => {
    try {
        const mess = await Mess.findOne({ owner: req.user._id });
        if (!mess) {
            return res.status(404).json({ message: 'Mess not found.' });
        }

        // --- Calculate Stats ---

        // 1. Get total number of monthly members.
        const totalMembers = await Membership.countDocuments({ mess: mess._id, status: 'active' });

        // 2. Get members on leave today (this is a simplified logic for demonstration).
        // A real implementation would query the Leaves collection for today's date.
        const membersOnLeave = 0; // Placeholder for leave calculation logic.

        // 3. Calculate meals to prepare.
        const mealsToPrepare = totalMembers - membersOnLeave;

        // 4. Get meals eaten today. We need to query for records created today.
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);

        const mealsEatenToday = await MealRecord.countDocuments({
            mess: mess._id,
            createdAt: { $gte: startOfDay, $lte: endOfDay }
        });

        // 5. Get count of monthly vs daily users eaten today.
        const monthlyEaten = await MealRecord.countDocuments({
            mess: mess._id,
            customer: { $ne: null }, // '$ne: null' means the customer field exists.
            createdAt: { $gte: startOfDay, $lte: endOfDay }
        });
        const dailyEaten = mealsEatenToday - monthlyEaten;


        // Assemble the response object.
        const stats = {
            totalMembers,
            membersOnLeave,
            mealsToPrepare,
            totalMealsEaten: mealsEatenToday,
            monthlyMembersEaten: monthlyEaten,
            dailyUsersEaten: dailyEaten,
            membersRemaining: mealsToPrepare - monthlyEaten,
        };

        res.status(200).json(stats);

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Update the rules for the manager's mess
// @route   PUT /api/managers/my-mess/rules
// @access  Private (Manager only)
const updateMyMessRules = async (req, res) => {
    // Get the new rules from the request body.
    const { leaveCutoffDay, leaveCutoffTime, rebateMinDays } = req.body;
    try {
        // Find the manager's mess and update it with the new values.
        // 'new: true' ensures the updated document is returned.
        const updatedMess = await Mess.findOneAndUpdate(
            { owner: req.user._id },
            { $set: { leaveCutoffDay, leaveCutoffTime, rebateMinDays } },
            { new: true }
        );

        if (!updatedMess) {
            return res.status(404).json({ message: 'Mess not found.' });
        }
        res.status(200).json({ message: 'Rules updated successfully.', mess: updatedMess });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


module.exports = {
    getMyMess,
    getDashboardStats,
    updateMyMessRules,
};