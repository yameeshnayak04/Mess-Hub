// controllers/manager.controller.js

const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Invoice = require('../models/invoice.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const Review = require('../models/review.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { getTodayDateRange, normalizeToStartOfDay } = require('../utils/timeUtils');

// @desc    Get manager's own mess profile
// @route   GET /api/manager/my-mess
// @access  Private (Manager only)
// controllers/manager.controller.js - getMyMess function

const getMyMess = asyncHandler(async (req, res) => {
  console.log('🔍 getMyMess called for user:', req.user._id);
  
  const mess = await Mess.findOne({ owner: req.user._id })
    .populate('owner', 'name phone')
    .populate('mealPlans');

  if (!mess) {
    console.log('❌ No mess found for user:', req.user._id);
    res.status(404);
    throw new Error('You have not created a mess yet.');
  }

  console.log('✅ Mess found:', mess._id, mess.name);

  // Calculate stats for the mess
  const totalMembers = await Membership.countDocuments({ 
    mess: mess._id, 
    status: 'active' 
  });
  
  const reviews = await Review.find({ mess: mess._id });
  const totalRatings = reviews.length;
  const averageRating = totalRatings > 0 
    ? reviews.reduce((sum, r) => sum + r.rating, 0) / totalRatings 
    : 0;

  console.log('📊 Stats - Members:', totalMembers, 'Ratings:', totalRatings);

  // Return enhanced mess data with ALL required fields
  res.status(200).json({
    _id: mess._id,
    name: mess.name,
    address: mess.address,
    city: mess.city || 'Unknown', // ADDED: Ensure city exists
    cuisine: mess.cuisine || 'Mixed', // ADDED: Ensure cuisine exists
    serviceType: mess.serviceType,
    dailyThaliRate: mess.dailyThaliRate,
    mealPlans: mess.mealPlans,
    totalMembers,
    totalRatings,
    averageRating: Math.round(averageRating * 10) / 10,
  });
});

// @desc    Update mess profile
// @route   PUT /api/manager/my-mess
// @access  Private (Manager only)
const updateMyMess = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  const allowedUpdates = ['name', 'address', 'city', 'cuisine', 'serviceType', 'dailyThaliRate'];
  allowedUpdates.forEach(field => {
    if (req.body[field] !== undefined) {
      mess[field] = req.body[field];
    }
  });

  await mess.save();
  res.status(200).json(mess);
});

// @desc    Get dashboard stats
// @route   GET /api/manager/my-mess/dashboard-stats
// @access  Private (Manager only)
const getDashboardStats = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  const { start: todayStart, end: todayEnd } = getTodayDateRange();

  const totalMembers = await Membership.countDocuments({
    mess: mess._id,
    status: 'active',
  });

  const todayAttendance = await MealRecord.countDocuments({
    mess: mess._id,
    date: { $gte: todayStart, $lt: todayEnd },
  });

  const pendingPayments = await Invoice.countDocuments({
    mess: mess._id,
    status: 'pending',
  });

  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const monthlyRevenue = await Invoice.aggregate([
    {
      $match: {
        mess: mess._id,
        status: 'paid',
        createdAt: { $gte: startOfMonth },
      },
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$amount' },
      },
    },
  ]);

  res.status(200).json({
    totalMembers,
    todayAttendance,
    pendingPayments,
    monthlyRevenue: monthlyRevenue[0]?.total || 0,
  });
});

// @desc    Get all members
// @route   GET /api/manager/my-mess/members
// @access  Private (Manager only)
const getMessMembers = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  const members = await Membership.find({ mess: mess._id })
    .populate('customer', 'name phone')
    .populate('plan', 'name price');

  res.status(200).json(members);
});

// @desc    Update weekly menu
// @route   PUT /api/manager/my-mess/menu
// @access  Private (Manager only)
const updateWeeklyMenu = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  const { menuData } = req.body;

  const menu = await WeeklyMenu.findOneAndUpdate(
    { mess: mess._id },
    { menuData },
    { new: true, upsert: true }
  );

  res.status(200).json(menu);
});

// @desc    Get payment approvals
// @route   GET /api/manager/my-mess/payment-approvals
// @access  Private (Manager only)
const getPaymentApprovals = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  const pendingInvoices = await Invoice.find({
    mess: mess._id,
    status: 'pending',
  })
    .populate('membership')
    .populate('customer', 'name phone');

  res.status(200).json(pendingInvoices);
});

// @desc    Update invoice status (approve/reject)
// @route   PUT /api/manager/my-mess/invoices/:invoiceId/status
// @access  Private (Manager only)
const updateInvoiceStatus = asyncHandler(async (req, res) => {
  const { invoiceId } = req.params;
  const { status } = req.body;

  const invoice = await Invoice.findById(invoiceId).populate('mess');

  if (!invoice) {
    res.status(404);
    throw new Error('Invoice not found');
  }

  if (invoice.mess.owner.toString() !== req.user._id.toString()) {
    res.status(403);
    throw new Error('Not authorized');
  }

  invoice.status = status;
  await invoice.save();

  res.status(200).json(invoice);
});

// @desc    Get monthly analytics
// @route   GET /api/manager/my-mess/analytics
// @access  Private (Manager only)
const getAnalytics = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  res.status(200).json({ message: 'Analytics coming soon' });
});

// @desc    Run billing for a month
// @route   POST /api/manager/my-mess/billing/run
// @access  Private (Manager only)
const runBillingForMonth = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  res.status(200).json({ message: 'Billing process started' });
});

module.exports = {
  getMyMess,
  updateMyMess,
  getDashboardStats,
  getMessMembers,
  updateWeeklyMenu,
  getPaymentApprovals,
  updateInvoiceStatus,
  getAnalytics,
  runBillingForMonth,
};
