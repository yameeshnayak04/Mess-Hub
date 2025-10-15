// This file contains the logic for all customer-specific actions.

// Import all the necessary models.
const Membership = require('../models/membership.model.js');
const Mess = require('../models/mess.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const Invoice = require('../models/invoice.model.js');
const User = require('../models/user.model.js');


// @desc    Customer joins a mess by creating a new membership.
// @route   POST /api/customers/memberships
// @access  Private (Customer only)
const joinMess = async (req, res) => {
    const { messId, mealPlanId } = req.body;
    const customerId = req.user._id; // req.user is from 'protect' middleware.

    try {
        const mess = await Mess.findById(messId);
        if (!mess) return res.status(404).json({ message: "Mess not found" });

        // --- Loophole Resolution: Check mess capacity ---
        const memberCount = await Membership.countDocuments({ mess: messId, status: 'active' });
        if (memberCount >= mess.maxMembers) {
            return res.status(400).json({ message: "This mess is currently at full capacity." });
        }

        const mealPlan = mess.mealPlans.id(mealPlanId);
        if (!mealPlan) return res.status(404).json({ message: "Meal plan not found" });

        const existingMembership = await Membership.findOne({ customer: customerId, mess: messId });
        if (existingMembership) return res.status(400).json({ message: "You are already a member of this mess." });

        const membership = await Membership.create({
            customer: customerId,
            mess: messId,
            mealPlan: {
                name: mealPlan.name,
                price: mealPlan.priceHistory[mealPlan.priceHistory.length - 1].price,
                perDayRebateRate: mealPlan.perDayRebateRate,
            },
        });

        // --- Loophole Resolution: Pro-rata billing logic ---
        // TODO: Here you would call a helper function to calculate the first month's
        // pro-rata bill based on mess.firstMonthPolicy and create the first invoice.

        res.status(201).json(membership);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer gets their own profile.
// @route   GET /api/customers/me/profile
// @access  Private (Customer only)
const getMyProfile = (req, res) => {
    // The user object is already attached to the request by the 'protect' middleware.
    // We can just send it back.
    res.status(200).json(req.user);
};

// @desc    Customer updates their profile (name, photo).
// @route   PUT /api/customers/me/profile
// @access  Private (Customer only)
const updateMyProfile = async (req, res) => {
    const { name, photoUrl } = req.body;
    try {
        const user = await User.findById(req.user.id);
        if (user) {
            user.name = name || user.name;
            user.photoUrl = photoUrl || user.photoUrl;
            const updatedUser = await user.save();
            res.status(200).json({
                _id: updatedUser._id,
                name: updatedUser.name,
                phone: updatedUser.phone,
                role: updatedUser.role,
                photoUrl: updatedUser.photoUrl,
            });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


// @desc    Customer marks a formal leave for a membership.
// @route   POST /api/customers/memberships/:membershipId/leaves
// @access  Private (Customer only)
const markLeave = async (req, res) => {
    const { startDate, endDate } = req.body;
    const { membershipId } = req.params;

    try {
        const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
        if (!membership) return res.status(404).json({ message: "Membership not found or you are not authorized." });
        
        // --- Loophole Resolution: Check against leave rules ---
        const mess = membership.mess;
        // TODO: Add complex logic here to check if the application is being made
        // before mess.leaveApplicationDeadlineTime for tomorrow's leave.

        const leave = await Leave.create({ membership: membershipId, startDate, endDate });
        res.status(201).json({ message: 'Leave marked successfully', leave });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer toggles "Not Eating" for a single meal.
// @route   POST /api/customers/memberships/:membershipId/toggle-meal
// @access  Private (Customer only)
const toggleMealSkip = async (req, res) => {
    const { date, mealType } = req.body; // mealType is 'Lunch' or 'Dinner'
    const { membershipId } = req.params;

    try {
        const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
        if (!membership) return res.status(404).json({ message: "Membership not found." });

        const mess = membership.mess;
        // --- Loophole Resolution: Check against "Not Eating" cutoff time ---
        // TODO: Add logic here to check if the current time is before the
        // mess.notEatingCutoff.lunch or mess.notEatingCutoff.dinner time for the given date.

        // Determine rebate eligibility based on mess rules
        let isRebateEligible = false;
        let rebatePercentage = 0;
        if (mess.notEatingRebatePolicy === 'Full') {
            isRebateEligible = true;
            rebatePercentage = 100;
        } else if (mess.notEatingRebatePolicy === 'Partial') {
            isRebateEligible = true;
            rebatePercentage = mess.partialRebatePercentage;
        }

        const mealSkip = await MealSkip.create({
            membership: membershipId,
            date,
            mealType,
            isRebateEligible,
            rebatePercentage,
        });

        res.status(201).json({ message: `You have been marked as 'Not Eating' for ${mealType}.`, mealSkip });
    } catch (error) {
        // Handle cases where the user tries to skip the same meal twice (due to unique index).
        if (error.code === 11000) {
            return res.status(400).json({ message: `You have already skipped this meal.` });
        }
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer notifies manager that a bill has been paid.
// @route   POST /api/customers/invoices/:invoiceId/notify-payment
// @access  Private (Customer only)
const notifyPayment = async (req, res) => {
    const { invoiceId } = req.params;
    const { proofUrl } = req.body;

    try {
        const invoice = await Invoice.findById(invoiceId).populate({
            path: 'membership',
            match: { customer: req.user._id }
        });

        if (!invoice || !invoice.membership) {
            return res.status(404).json({ message: 'Invoice not found or you are not authorized.' });
        }

        // Update the invoice status and save the proof URL.
        invoice.status = 'pending_approval';
        invoice.proofUrl = proofUrl;
        await invoice.save();

        // TODO: Here you would trigger a push notification to the manager.

        res.status(200).json({ message: 'Manager has been notified of your payment.' });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


// @desc    Get all active memberships for the logged-in customer
// @route   GET /api/customers/me/memberships
// @access  Private (Customer only)
const getMyMemberships = async (req, res) => {
    try {
        const memberships = await Membership.find({ customer: req.user._id, status: 'active' })
            .populate('mess', 'name address'); // Populate mess name and address
        res.status(200).json(memberships);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


module.exports = {
    joinMess,
    getMyProfile,
    updateMyProfile,
    markLeave,
    toggleMealSkip,
    notifyPayment,
    getMyMemberships,
};