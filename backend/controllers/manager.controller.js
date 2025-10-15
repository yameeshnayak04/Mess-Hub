// This file contains all logic for the Mess Manager's dashboard and management tasks.

// Import all necessary models
const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Invoice = require('../models/invoice.model.js');
const Leave = require('../models/leave.model.js');

// --- Helper function to get start and end of the current day ---
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
    // Find the mess owned by the currently logged-in manager.
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

        // Perform multiple database queries in parallel for efficiency.
        const [
            totalMembers,
            membersOnLeave,
            mealsEatenTodayRecords,
        ] = await Promise.all([
            Membership.countDocuments({ mess: mess._id, status: 'active' }),
            Leave.countDocuments({ 'membership.mess': mess._id, startDate: { $lte: startOfDay }, endDate: { $gte: endOfDay } }), // Simplified logic
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
            .populate('customer', 'name phone photoUrl');
        
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
            { mess: mess._id, weekIdentifier },
            { days },
            { new: true, upsert: true } // Upsert: create if it doesn't exist
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
                match: { mess: mess._id },
                populate: { path: 'customer', select: 'name photoUrl' }
            });
            
        // Filter out invoices that don't belong to this mess
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
    const { status, reason } = req.body; // status can be 'paid' or 'rejected'
    const { invoiceId } = req.params;
    try {
        const invoice = await Invoice.findById(invoiceId);
        if (!invoice) return res.status(404).json({ message: 'Invoice not found.' });
        
        // TODO: Add a check to ensure this invoice belongs to the manager's mess.

        invoice.status = status;
        if (status === 'rejected') {
            invoice.rejectionReason = reason;
        }
        await invoice.save();
        
        // TODO: Send a push notification to the customer.

        res.status(200).json({ message: `Payment status updated to ${status}.`, invoice });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


module.exports = {
    getMyMess,
    updateMyMess,
    getDashboardStats,
    getMessMembers,
    updateWeeklyMenu,
    getPaymentApprovals,
    updateInvoiceStatus,
};