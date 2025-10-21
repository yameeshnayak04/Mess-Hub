// backend/controllers/manager.controller.js

const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Invoice = require('../models/invoice.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { getTodayDateRange } = require('../utils/timeUtils');

// @desc    Get the profile of the manager's own mess
const getMyMess = asyncHandler(async (req, res) => {
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
        res.status(404);
        throw new Error('Mess profile not found. Please create one.');
    }
    res.status(200).json(mess);
});

// @desc    Update the manager's own mess profile
const updateMyMess = asyncHandler(async (req, res) => {
    const mess = await Mess.findOneAndUpdate(
        { owner: req.user._id },
        req.body,
        { new: true, runValidators: true }
    );
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }
    res.status(200).json(mess);
});

// @desc    Get live dashboard stats for the manager's mess
const getDashboardStats = asyncHandler(async (req, res) => {
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }
    const { startOfDay, endOfDay } = getTodayDateRange();
    const [totalMembers, mealsEatenTodayRecords] = await Promise.all([
        Membership.countDocuments({ mess: mess._id, status: 'active' }),
        MealRecord.find({ mess: mess._id, createdAt: { $gte: startOfDay, $lte: endOfDay } }),
    ]);
    // Simplified leave calculation
    const membersOnLeave = 0;
    const mealsToPrepare = totalMembers - membersOnLeave;
    const totalMealsEaten = mealsEatenTodayRecords.length;
    const monthlyMembersEaten = mealsEatenTodayRecords.filter(r => r.membership).length;

    res.status(200).json({
        totalMembers, membersOnLeave, mealsToPrepare, totalMealsEaten,
        monthlyMembersEaten, dailyUsersEaten: totalMealsEaten - monthlyMembersEaten,
        membersRemaining: mealsToPrepare - monthlyMembersEaten,
    });
});

// @desc    Get a list of all current members of the mess
const getMessMembers = asyncHandler(async (req, res) => {
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }
    const memberships = await Membership.find({ mess: mess._id, status: 'active' }).populate('customer', 'name phone photoUrl');
    res.status(200).json(memberships);
});

// @desc    Manager creates or updates the weekly menu
const updateWeeklyMenu = asyncHandler(async (req, res) => {
    const { weekIdentifier, days } = req.body;
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }
    const menu = await WeeklyMenu.findOneAndUpdate(
        { mess: mess._id, weekIdentifier }, { days }, { new: true, upsert: true }
    );
    res.status(200).json(menu);
});

// @desc    Manager gets a list of payments pending approval
const getPaymentApprovals = asyncHandler(async (req, res) => {
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }
    const invoices = await Invoice.find({ status: 'pending_approval' }).populate({
        path: 'membership',
        match: { mess: mess._id },
        populate: { path: 'customer', select: 'name photoUrl' }
    });
    const relevantInvoices = invoices.filter(inv => inv.membership);
    res.status(200).json(relevantInvoices);
});

// @desc    Manager approves or rejects a payment
const updateInvoiceStatus = asyncHandler(async (req, res) => {
    const { status, rejectionReason } = req.body;
    const { invoiceId } = req.params;
    
    const invoice = await Invoice.findById(invoiceId);
    if (!invoice) {
        res.status(404);
        throw new Error('Invoice not found.');
    }
    // TODO: Add a robust check to ensure this invoice belongs to the manager's mess.
    invoice.status = status;
    if (status === 'rejected') invoice.rejectionReason = rejectionReason;
    await invoice.save();
    
    // TODO: Trigger a push notification to the customer.
    res.status(200).json({ message: `Payment status updated to ${status}.`, invoice });
});

// @desc    Get simple analytics for the manager's mess
const getAnalytics = asyncHandler(async (req, res) => {
    const { month, year } = req.query;
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
        res.status(404);
        throw new Error('Mess not found.');
    }

    const revenueData = await Invoice.aggregate([
        { $match: { status: 'paid', month: parseInt(month), year: parseInt(year) } },
        { $group: { _id: null, totalRevenue: { $sum: '$amount' } } }
    ]);

    const dailyUsersCount = await MealRecord.countDocuments({
        mess: mess._id,
        membership: null,
        createdAt: { $gte: new Date(year, month - 1, 1), $lt: new Date(year, month, 1) }
    });

    res.status(200).json({
        totalRevenue: revenueData.length > 0 ? revenueData[0].totalRevenue : 0,
        totalDailyUsers: dailyUsersCount,
    });
});

module.exports = { getMyMess, updateMyMess, getDashboardStats, getMessMembers, updateWeeklyMenu, getPaymentApprovals, updateInvoiceStatus, getAnalytics };