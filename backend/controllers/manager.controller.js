// This file contains the final, feature-complete logic for the Mess Manager's dashboard.

const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Invoice = require('../models/invoice.model.js');
const Leave = require('../models/leave.model.js');
const User = require('../models/user.model.js');

// --- Helper function to get start and end of the current day for queries ---
const getTodayTimeRange = () => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);
    return { startOfDay, endOfDay };
};

// @desc    Get the profile of the manager's own mess
// @route   GET /api/managers/my-mess
// @access  Private (Manager only)
const getMyMess = async (req, res) => {
  try {
    const mess = await Mess.findOne({ owner: req.user._id });
    if (!mess) {
      return res.status(404).json({ message: 'Mess profile not found. Please create one.' });
    }
    res.status(200).json(mess);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Update the manager's own mess profile
// @route   PUT /api/managers/my-mess
// @access  Private (Manager only)
const updateMyMess = async (req, res) => {
    try {
        const mess = await Mess.findOneAndUpdate(
            { owner: req.user._id }, // Find the mess by the logged-in manager's ID
            req.body, // Update it with the data from the request body
            { new: true, runValidators: true } // Return the updated document and run schema validations
        );
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });
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
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        const { startOfDay, endOfDay } = getTodayTimeRange();

        // Perform multiple database queries in parallel for maximum efficiency.
        const [
            totalMembers,
            membersOnLeave, // This is a simplified logic for demonstration
            mealsEatenTodayRecords,
        ] = await Promise.all([
            Membership.countDocuments({ mess: mess._id, status: 'active' }),
            Leave.countDocuments({ 'membership.mess': mess._id, startDate: { $lte: startOfDay }, endDate: { $gte: endOfDay } }),
            MealRecord.find({ mess: mess._id, createdAt: { $gte: startOfDay, $lte: endOfDay } }),
        ]);

        const mealsToPrepare = totalMembers - membersOnLeave;
        const totalMealsEaten = mealsEatenTodayRecords.length;
        const monthlyMembersEaten = mealsEatenTodayRecords.filter(record => record.customer).length;
        const dailyUsersEaten = totalMealsEaten - monthlyMembersEaten;

        const stats = {
            totalMembers, membersOnLeave, mealsToPrepare, totalMealsEaten,
            monthlyMembersEaten, dailyUsersEaten,
            membersRemaining: mealsToPrepare - monthlyMembersEaten,
        };
        res.status(200).json(stats);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Get a list of all current members of the mess
// @route   GET /api/managers/my-mess/members
// @access  Private (Manager only)
const getMessMembers = async (req, res) => {
    try {
        const mess = await Mess.findOne({ owner: req.user._id });
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        const memberships = await Membership.find({ mess: mess._id, status: 'active' })
            .populate('customer', 'name phone photoUrl'); // Populate customer's public details
        
        res.status(200).json(memberships);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Manager creates or updates the weekly menu
// @route   PUT /api/managers/my-mess/menu
// @access  Private (Manager only)
const updateWeeklyMenu = async (req, res) => {
    const { weekIdentifier, days } = req.body;
    try {
        const mess = await Mess.findOne({ owner: req.user._id });
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        const menu = await WeeklyMenu.findOneAndUpdate(
            { mess: mess._id, weekIdentifier }, // Find menu by mess and week
            { days }, // Update the days
            { new: true, upsert: true } // Upsert: create a new document if one doesn't exist
        );
        res.status(200).json(menu);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Manager gets a list of payments pending approval
// @route   GET /api/managers/my-mess/payment-approvals
// @access  Private (Manager only)
const getPaymentApprovals = async (req, res) => {
    try {
        const mess = await Mess.findOne({ owner: req.user._id });
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });
        
        const invoices = await Invoice.find({ status: 'pending_approval' })
            .populate({
                path: 'membership',
                match: { mess: mess._id }, // Ensure the membership belongs to this mess
                populate: { path: 'customer', select: 'name photoUrl' } // Populate the customer's details
            });
            
        // Filter out invoices where the membership didn't match (a security check)
        const relevantInvoices = invoices.filter(inv => inv.membership);

        res.status(200).json(relevantInvoices);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Manager approves or rejects a payment
// @route   PUT /api/managers/my-mess/invoices/:invoiceId/status
// @access  Private (Manager only)
const updateInvoiceStatus = async (req, res) => {
    const { status, rejectionReason } = req.body; // status must be 'paid' or 'rejected'
    const { invoiceId } = req.params;
    try {
        const invoice = await Invoice.findById(invoiceId);
        if (!invoice) return res.status(404).json({ message: 'Invoice not found.' });
        
        // TODO: Add a robust check to ensure this invoice belongs to the manager's mess.

        invoice.status = status;
        if (status === 'rejected') {
            invoice.rejectionReason = rejectionReason;
        }
        await invoice.save();
        
        // TODO: Trigger a push notification to the customer with the status update.

        res.status(200).json({ message: `Payment status updated to ${status}.`, invoice });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Get simple analytics for the manager's mess
// @route   GET /api/managers/my-mess/analytics
// @access  Private (Manager only)
const getAnalytics = async (req, res) => {
    const { month, year } = req.query; // e.g., month=10, year=2025
    try {
        const mess = await Mess.findOne({ owner: req.user._id });
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        // Calculate total revenue from paid invoices for the given month and year
        const revenueData = await Invoice.aggregate([
            { $match: { status: 'paid', month: parseInt(month), year: parseInt(year) } },
            { $group: { _id: null, totalRevenue: { $sum: '$amount' } } }
        ]);

        // Count daily users for the given month and year
        const dailyUsersCount = await MealRecord.countDocuments({
            mess: mess._id,
            customer: null, // customer is null for daily users
            createdAt: { 
                $gte: new Date(year, month - 1, 1),
                $lt: new Date(year, month, 1)
            }
        });

        res.status(200).json({
            totalRevenue: revenueData.length > 0 ? revenueData[0].totalRevenue : 0,
            totalDailyUsers: dailyUsersCount,
        });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// controllers/manager.controller.js (optional)
const setManagerPin = async (req, res, next) => {
  try {
    const { pin } = req.body;
    if (!/^\d{4,6}$/.test(pin || '')) return res.status(400).json({ message: 'PIN must be 4–6 digits' });
    const mess = await Mess.findOne({ owner: req.user._id });
    const salt = await bcrypt.genSalt(12);
    mess.managerPinHash = await bcrypt.hash(pin, salt);
    await mess.save();
    res.status(200).json({ message: 'Manager PIN set' });
  } catch (e) { next(e); }
};



module.exports = {
    setManagerPin,
    getMyMess,
    updateMyMess,
    getDashboardStats,
    getMessMembers,
    updateWeeklyMenu,
    getPaymentApprovals,
    updateInvoiceStatus,
    getAnalytics,
};