// controllers/manager.controller.js
const Mess = require('../models/mess.model.js');
const Membership = require('../models/membership.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const Leave = require('../models/leave.model.js');
const Invoice = require('../models/invoice.model.js');
const Review = require('../models/review.model.js');
const DailyMenu = require('../models/dailyMenu.model.js');
const asyncHandler = require('../utils/asynchandler.js');

const startOfDay = (d) => { const x = new Date(d); x.setHours(0,0,0,0); return x; };

const getMyMess = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('You have not created a mess yet'); }
  const totalMembers = await Membership.countDocuments({ mess: mess._id, status: 'active' });
  const reviews = await Review.find({ mess: mess._id });
  const totalRatings = reviews.length;
  const averageRating = totalRatings ? (reviews.reduce((s, r) => s + r.rating, 0) / totalRatings) : 0;
  res.status(200).json({ ...mess.toObject(), totalMembers, totalRatings, averageRating: Math.round(averageRating * 10) / 10 });
});

const updateMyMess = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  const allowed = ['name', 'address', 'city', 'cuisine', 'serviceType', 'dailyThaliRate', 'timings', 'toggleSkipRebatePercentage', 'minMonthlyCharge', 'maxMembers', 'securityDeposit', 'leaveApplicationDeadlineTime', 'specialThaliRate'];
  Object.keys(req.body).forEach((k) => { if (allowed.includes(k)) mess[k] = req.body[k]; });
  if (!['Monthly Only', 'Both'].includes(mess.serviceType)) { res.status(400); throw new Error('Invalid serviceType'); }
  if (mess.serviceType === 'Both' && (mess.dailyThaliRate === undefined || mess.dailyThaliRate === null)) { res.status(400); throw new Error('dailyThaliRate required when serviceType is Both'); }
  await mess.save();
  res.status(200).json(mess);
});

const getDashboardStats = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  const today = startOfDay(new Date());
  const tomorrow = startOfDay(new Date(Date.now() + 86400000));
  const totalMembers = await Membership.countDocuments({ mess: mess._id, status: 'active' });
  const todayAttendance = await MealRecord.countDocuments({ mess: mess._id, date: { $gte: today, $lt: tomorrow } });
  const pendingApprovals = await Invoice.countDocuments({ status: 'pending_approval', membership: { $in: (await Membership.find({ mess: mess._id }).select('_id')).map(x => x._id) } });
  const startOfMonth = new Date(); startOfMonth.setDate(1); startOfMonth.setHours(0,0,0,0);
  const paid = await Invoice.aggregate([
    { $match: { status: 'paid', year: new Date().getFullYear(), month: new Date().getMonth() + 1, membership: { $in: (await Membership.find({ mess: mess._id }).select('_id')).map(x => x._id) } } },
    { $group: { _id: null, total: { $sum: '$amount' } } }
  ]);
  res.status(200).json({ totalMembers, todayAttendance, pendingApprovals, monthlyRevenue: paid[0]?.total || 0 });
});

const getMessMembers = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  const members = await Membership.find({ mess: mess._id }).populate('customer', 'name phone');
  res.status(200).json(members);
});

const getPaymentApprovals = asyncHandler(async (req, res) => {
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  const memberIds = (await Membership.find({ mess: mess._id }).select('_id')).map(x => x._id);
  const pending = await Invoice.find({ status: 'pending_approval', membership: { $in: memberIds } }).populate({ path: 'membership', populate: { path: 'customer', select: 'name phone' } });
  res.status(200).json(pending);
});

const updateInvoiceStatus = asyncHandler(async (req, res) => {
  const { invoiceId } = req.params;
  const invoice = await Invoice.findById(invoiceId).populate('membership');
  if (!invoice) { res.status(404); throw new Error('Invoice not found'); }
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  if (String(invoice.membership.mess) !== String(mess._id)) { res.status(403); throw new Error('Not authorized'); }
  const { status, rejectionReason } = req.body;
  if (!['paid', 'rejected'].includes(status)) { res.status(400); throw new Error('Status must be paid or rejected'); }
  invoice.status = status;
  if (status === 'rejected') invoice.rejectionReason = rejectionReason || 'Insufficient proof';
  await invoice.save();
  res.status(200).json(invoice);
});

// Run billing for a month
const runBillingForMonth = asyncHandler(async (req, res) => {
  const { month, year } = req.body; // month 1-12
  if (!month || !year) { res.status(400); throw new Error('month and year are required'); }
  const mess = await Mess.findOne({ owner: req.user._id });
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  const members = await Membership.find({ mess: mess._id, status: 'active' });
  const from = new Date(Date.UTC(year, month - 1, 1)); const to = new Date(Date.UTC(year, month, 1));
  const results = [];
  for (const mem of members) {
    const base = mem.mealPlan.price; // monthly fee
    // Rebates within the month
    const [skips, leaves] = await Promise.all([
      MealSkip.find({ membership: mem._id, date: { $gte: from, $lt: to }, isRebateEligible: true }).lean(),
      Leave.find({ membership: mem._id, startDate: { $lt: to }, endDate: { $gte: from }, isRebateEligible: true }).lean(),
    ]);
    const skipRebate = skips.reduce((s, x) => s + (mem.mealPlan.perThaliRebateRate * (x.rebatePercentage / 100)), 0);
    const mealsPerDay = mem.mealPlan.name === 'Full Day' ? 2 : 1;
    const leaveRebate = leaves.reduce((s, l) => s + (l.duration * mealsPerDay * mem.mealPlan.perThaliRebateRate), 0);
    let amount = Math.max(0, base - (skipRebate + leaveRebate));
    if (amount < (mess.minMonthlyCharge || 0)) amount = mess.minMonthlyCharge || 0;
    const invoice = await Invoice.findOneAndUpdate(
      { membership: mem._id, month, year },
      { membership: mem._id, month, year, amount, status: 'due' },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    results.push(invoice);
  }
  res.status(200).json({ message: 'Billing complete', invoices: results });
});

module.exports = {
  getMyMess,
  updateMyMess,
  getDashboardStats,
  getMessMembers,
  getPaymentApprovals,
  updateInvoiceStatus,
  runBillingForMonth,
};
