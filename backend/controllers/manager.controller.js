// controllers/manager.controller.js
const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Invoice = require('../models/invoice.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { getTodayDateRange, normalizeToStartOfDay } = require('../utils/timeUtils');

// Manager's own mess profile
const getMyMess = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess profile not found. Please create one.');
  }
  res.status(200).json(mess);
});

// Update mess profile
const updateMyMess = asyncHandler(async (req, res) => {
  const mess = await Mess.findOneAndUpdate({ owner: req.user._id }, req.body, { new: true, runValidators: true });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  res.status(200).json(mess);
});

// Live stats (aligned to membership-based records)
const getDashboardStats = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const { startOfDay, endOfDay } = getTodayDateRange();
  const [totalMembers, mealsToday] = await Promise.all([
    Membership.countDocuments({ mess: mess._id, status: 'active' }),
    MealRecord.find({ mess: mess._id, createdAt: { $gte: startOfDay, $lte: endOfDay } }),
  ]);
  const monthlyMembersEaten = mealsToday.filter(r => r.membership).length;
  res.status(200).json({
    totalMembers,
    membersOnLeave: 0, // can be enriched by querying Leave for today if needed
    mealsToPrepare: totalMembers, // can subtract toggles/leaves if desired
    totalMealsEaten: mealsToday.length,
    monthlyMembersEaten,
    dailyUsersEaten: mealsToday.length - monthlyMembersEaten,
    membersRemaining: totalMembers - monthlyMembersEaten,
  });
});

// Members listing
const getMessMembers = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const memberships = await Membership.find({ mess: mess._id, status: 'active' }).populate('customer', 'name phone photoUrl');
  res.status(200).json(memberships);
});

// Weekly menu upsert
const updateWeeklyMenu = asyncHandler(async (req, res) => {
  const { weekIdentifier, days } = req.body;
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const menu = await WeeklyMenu.findOneAndUpdate({ mess: mess._id, weekIdentifier }, { days }, { new: true, upsert: true });
  res.status(200).json(menu);
});

// Payment approvals
const getPaymentApprovals = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const invoices = await Invoice.find({ status: 'pending_approval' }).populate({
    path: 'membership',
    match: { mess: mess._id },
    populate: { path: 'customer', select: 'name photoUrl' },
  });
  res.status(200).json(invoices.filter(inv => inv.membership));
});

const updateInvoiceStatus = asyncHandler(async (req, res) => {
  const { status, rejectionReason } = req.body;
  const { invoiceId } = req.params;
  const invoice = await Invoice.findById(invoiceId).populate('membership');
  if (!invoice) {
    res.status(404);
    throw new Error('Invoice not found.');
  }
  // Optional: Verify invoice.membership.mess belongs to this manager
  invoice.status = status;
  if (status === 'rejected') invoice.rejectionReason = rejectionReason;
  await invoice.save();
  res.status(200).json({ message: `Payment status updated to ${status}.`, invoice });
});

// Month analytics (paid revenue & daily users)
const getAnalytics = asyncHandler(async (req, res) => {
  const { month, year } = req.query;
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const revenueData = await Invoice.aggregate([
    { $match: { status: 'paid', month: parseInt(month, 10), year: parseInt(year, 10) } },
    { $lookup: { from: 'memberships', localField: 'membership', foreignField: '_id', as: 'm' } },
    { $unwind: '$m' },
    { $match: { 'm.mess': mess._id } },
    { $group: { _id: null, totalRevenue: { $sum: '$amount' } } },
  ]);
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);
  const dailyUsersCount = await MealRecord.countDocuments({ mess: mess._id, membership: null, createdAt: { $gte: start, $lt: end } });
  res.status(200).json({ totalRevenue: revenueData[0]?.totalRevenue || 0, totalDailyUsers: dailyUsersCount });
});

// --- Billing engine: compute and upsert monthly invoices ---
const computeInvoiceAmount = async (membership, month, year, mess) => {
  const baseMonthly = membership.mealPlan.price || 0;

  // First-month security deposit if started within the invoice month
  let securityDeposit = 0;
  if (mess.securityDeposit && mess.securityDeposit > 0) {
    const s = membership.startedAt || membership.createdAt;
    if (s && s.getMonth() + 1 === month && s.getFullYear() === year) {
      securityDeposit = mess.securityDeposit;
    }
  }

  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);

  // Sum leave rebates (already computed per leave)
  const leaves = await Leave.find({
    membership: membership._id,
    startDate: { $gte: start, $lt: end },
    endDate: { $gte: start, $lt: end },
    isRebateEligible: true,
  });
  const leaveRebate = leaves.reduce((sum, l) => sum + (l.rebateAmount || 0), 0);

  // Sum toggle rebates
  const skips = await MealSkip.find({
    membership: membership._id,
    date: { $gte: start, $lt: end },
    isRebateEligible: true,
  });
  const perThali = membership.mealPlan.perThaliRebateRate || 0;
  const toggleRebate = skips.reduce((sum, s) => sum + (perThali * (s.rebatePercentage / 100)), 0);

  // Apply special thali rate for daily users is out of scope for monthly invoice; ignore here

  let computed = baseMonthly - (leaveRebate + toggleRebate);
  if (computed < (mess.minMonthlyCharge || 0)) computed = mess.minMonthlyCharge || 0;
  computed += securityDeposit; // add-on for first month if applicable

  return Math.max(0, Math.round(computed));
};

const runBillingForMonth = asyncHandler(async (req, res) => {
  const { month, year } = req.body;
  if (!month || !year) {
    res.status(400);
    throw new Error('Please provide month and year.');
  }
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }

  // Memberships active at any point during the month
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);
  const memberships = await Membership.find({
    mess: mess._id,
    $or: [
      { status: 'active' },
      { status: 'cancelled', endedAt: { $gte: start, $lt: end } },
    ],
  });

  const results = [];
  for (const m of memberships) {
    const amount = await computeInvoiceAmount(m, month, year, mess);
    const invoice = await Invoice.findOneAndUpdate(
      { membership: m._id, month, year },
      { $set: { amount }, $setOnInsert: { status: 'due' } },
      { new: true, upsert: true }
    );
    results.push(invoice);
  }

  res.status(200).json({ message: 'Billing completed', count: results.length, invoices: results });
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
