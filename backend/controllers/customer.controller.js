// This file contains the final logic for all customer-specific actions.

const Membership = require('../models/membership.model.js');
const Mess = require('../models/mess.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const Invoice = require('../models/invoice.model.js');
const User = require('../models/user.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { getTodayInMessTimezone } = require('../utils/timeUtils'); // We will create this helper

// @desc    Customer joins a mess by creating a new membership.
// @route   POST /api/customers/memberships
// @access  Private (Customer only)
const joinMess = asyncHandler(async (req, res) => {
    const { messId, mealPlanId } = req.body;
    
    const mess = await Mess.findById(messId);
    if (!mess) {
        res.status(404);
        throw new Error("Mess not found");
    }

    // Loophole Resolution: Check mess capacity
    const memberCount = await Membership.countDocuments({ mess: messId, status: 'active' });
    if (memberCount >= mess.maxMembers) {
        res.status(400);
        throw new Error("This mess is currently at full capacity.");
    }

    const mealPlan = mess.mealPlans.id(mealPlanId);
    if (!mealPlan) {
        res.status(404);
        throw new Error("Meal plan not found");
    }

    const existingMembership = await Membership.findOne({ customer: req.user._id, mess: messId });
    if (existingMembership && existingMembership.status === 'active') {
        res.status(400);
        throw new Error("You are already an active member of this mess.");
    }

    const membership = await Membership.create({
        customer: req.user._id,
        mess: messId,
        mealPlan: {
            name: mealPlan.name,
            price: mealPlan.priceHistory[mealPlan.priceHistory.length - 1].price,
            perThaliRebateRate: mealPlan.perThaliRebateRate,
        },
    });

    // TODO: Implement pro-rata billing logic to create the first invoice.
    res.status(201).json(membership);
});

// @desc    Customer marks a formal leave for a membership.
// @route   POST /api/customers/memberships/:membershipId/leaves
// @access  Private (Customer only)
const markLeave = asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.body;
    const { membershipId } = req.params;

    const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
    if (!membership) {
        res.status(404);
        throw new Error("Membership not found or you are not authorized.");
    }
    
    const { mess } = membership;
    const today = getTodayInMessTimezone(); // Helper to get today's date correctly
    const leaveStartDate = new Date(startDate);
    
    // Check #1: Leave must be for the future.
    if (leaveStartDate <= today) {
        res.status(400);
        throw new Error("Leave applications must be for a future date.");
    }
    
    // Check #2: Check against the daily deadline for applying for tomorrow's leave.
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    if (leaveStartDate.getTime() === tomorrow.getTime()) {
        const now = new Date();
        const deadlineTime = mess.leaveApplicationDeadlineTime; // e.g., "22:00"
        const [hours, minutes] = deadlineTime.split(':');
        const deadline = new Date(today);
        deadline.setHours(parseInt(hours), parseInt(minutes), 0, 0);
        if (now > deadline) {
            res.status(400);
            throw new Error(`The deadline to apply for tomorrow's leave (${deadlineTime}) has passed.`);
        }
    }

    const leave = await Leave.create({ membership: membershipId, startDate, endDate });

    // Business Logic: Determine if the leave is rebate-eligible
    if (leave.duration >= mess.rebateMinDays) {
        leave.isRebateEligible = true;
        leave.rebateAmount = leave.duration * membership.mealPlan.perThaliRebateRate;
        await leave.save();
    }

    res.status(201).json({ message: 'Leave marked successfully', leave });
});

// @desc    Customer toggles "Not Eating" for a single meal.
// @route   POST /api/customers/memberships/:membershipId/toggle-meal
// @access  Private (Customer only)
const toggleMealSkip = asyncHandler(async (req, res) => {
    const { date, mealType } = req.body;
    const { membershipId } = req.params;

    const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
    if (!membership) {
        res.status(404);
        throw new Error("Membership not found.");
    }

    // Check #6: Plan-specific meal skips
    const planName = membership.mealPlan.name;
    if ((planName === 'Lunch' && mealType !== 'Lunch') || (planName === 'Dinner' && mealType !== 'Dinner')) {
        res.status(400);
        throw new Error(`Your meal plan (${planName}) does not include ${mealType}.`);
    }

    // Check #1: Time-based cutoff for the toggle
    const { mess } = membership;
    const now = new Date();
    const targetDate = new Date(date);
    const mealEndTime = mealType === 'Lunch' ? mess.timings.lunch.end : mess.timings.dinner.end;
    const [hours, minutes] = mealEndTime.split(':');
    const deadline = new Date(targetDate);
    deadline.setHours(parseInt(hours), parseInt(minutes), 0, 0);
    
    if (now > deadline) {
        res.status(400);
        throw new Error(`The cutoff time for toggling ${mealType} has passed.`);
    }

    let isRebateEligible = mess.toggleSkipRebatePercentage > 0;
    
    const mealSkip = await MealSkip.create({
        membership: membershipId,
        date: targetDate,
        mealType,
        isRebateEligible,
        rebatePercentage: mess.toggleSkipRebatePercentage,
    });

    res.status(201).json({ message: `You have been marked as 'Not Eating' for ${mealType}.`, mealSkip });
});

// @desc    Customer notifies manager that a bill has been paid.
// @route   POST /api/customers/invoices/:invoiceId/notify-payment
// @access  Private (Customer only)
const notifyPayment = asyncHandler(async (req, res) => {
    const { invoiceId } = req.params;
    const { proofUrl } = req.body;

    const invoice = await Invoice.findById(invoiceId).populate({
        path: 'membership',
        match: { customer: req.user._id }
    });

    if (!invoice || !invoice.membership) {
        res.status(404);
        throw new Error('Invoice not found or you are not authorized.');
    }
    if (invoice.status !== 'due') {
        res.status(400);
        throw new Error(`This invoice is not currently due. Its status is '${invoice.status}'.`);
    }
    
    invoice.status = 'pending_approval';
    invoice.proofUrl = proofUrl;
    await invoice.save();

    // TODO: Trigger a push notification to the manager.

    res.status(200).json({ message: 'Manager has been notified of your payment.' });
});

// @desc    Get all active memberships for the logged-in customer
const getMyMemberships = asyncHandler(async (req, res) => {
    const memberships = await Membership.find({ customer: req.user._id, status: 'active' })
        .populate('mess', 'name address');
    res.status(200).json(memberships);
});

module.exports = {
    joinMess,
    markLeave,
    toggleMealSkip,
    notifyPayment,
    getMyMemberships,
};