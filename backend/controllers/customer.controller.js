// controllers/customer.controller.js
const Membership = require('../models/membership.model.js');
const Mess = require('../models/mess.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const Invoice = require('../models/invoice.model.js');
const User = require('../models/user.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { getTodayInMessTimezone, normalizeToStartOfDay, getMealEndDateTime } = require('../utils/timeUtils');

const getMyProfile = asyncHandler(async (req, res) => {
  res.status(200).json(req.user);
});

const getMyInvoices = asyncHandler(async (req, res) => {
  const myMemberships = await Membership.find({ customer: req.user._id }).select('_id');
  const invoices = await Invoice.find({ membership: { $in: myMemberships.map(m => m._id) } }).sort({ year: -1, month: -1 });
  res.status(200).json(invoices);
});

// Join a mess with plan freeze and capacity check
const joinMess = asyncHandler(async (req, res) => {
  const { messId, mealPlanId } = req.body;
  const mess = await Mess.findById(messId);
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }

  const memberCount = await Membership.countDocuments({ mess: messId, status: 'active' });
  if (memberCount >= mess.maxMembers) {
    res.status(400);
    throw new Error('This mess is currently at full capacity.');
  }

  const mealPlan = mess.mealPlans.id(mealPlanId);
  if (!mealPlan) {
    res.status(404);
    throw new Error('Meal plan not found');
  }

  const existing = await Membership.findOne({ customer: req.user._id, mess: messId, status: 'active' });
  if (existing) {
    res.status(400);
    throw new Error('You are already an active member of this mess.');
  }

  const currentPrice = mealPlan.priceHistory[mealPlan.priceHistory.length - 1].price;
  const membership = await Membership.create({
    customer: req.user._id,
    mess: messId,
    mealPlan: {
      name: mealPlan.name,
      price: currentPrice,
      perThaliRebateRate: mealPlan.perThaliRebateRate,
    },
  });

  res.status(201).json(membership);
});

// Formal leave within single month, with deadline + rebate rules
const markLeave = asyncHandler(async (req, res) => {
  const { startDate, endDate } = req.body;
  const { membershipId } = req.params;

  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
  if (!membership) {
    res.status(404);
    throw new Error('Membership not found or you are not authorized.');
  }

  const { mess } = membership;
  const today = getTodayInMessTimezone();
  const start = normalizeToStartOfDay(startDate);
  const end = normalizeToStartOfDay(endDate);

  if (start <= today) {
    res.status(400);
    throw new Error('Leave applications must be for a future date.');
  }

  // If leave starts tomorrow, enforce deadline time
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  if (start.getTime() === tomorrow.getTime()) {
    const deadlineStr = mess.leaveApplicationDeadlineTime || '22:00';
    const [h, m] = deadlineStr.split(':').map(Number);
    const deadline = new Date(today);
    deadline.setHours(h, m, 0, 0);
    if (new Date() > deadline) {
      res.status(400);
      throw new Error(`The deadline to apply for tomorrow's leave (${deadlineStr}) has passed.`);
    }
  }

  const leave = await Leave.create({ membership: membershipId, startDate: start, endDate: end });

  if (leave.duration >= (mess.rebateMinDays || 0)) {
    leave.isRebateEligible = true;
    // Rebate covers only meals in plan; per-thali rate already unified
    leave.rebateAmount = leave.duration * membership.mealPlan.perThaliRebateRate * (membership.mealPlan.name === 'Full Day' ? 2 : 1);
    await leave.save();
  }

  res.status(201).json({ message: 'Leave marked successfully', leave });
});

// Toggle skip with time cutoff and plan scope
const toggleMealSkip = asyncHandler(async (req, res) => {
  const { date, mealType } = req.body;
  const { membershipId } = req.params;
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
  if (!membership) { res.status(404); throw new Error('Membership not found.'); }

  // Enforce current-or-next meal rule
  const now = new Date();
  const targetDate = new Date(date);
  const parse = (t) => { const [h, s] = t.split(':'); const d = new Date(targetDate); d.setHours(parseInt(h), parseInt(s), 0, 0); return d; };
  const lunchStart = parse(membership.mess.timings.lunch.start);
  const lunchEnd   = parse(membership.mess.timings.lunch.end);
  const dinnerStart= parse(membership.mess.timings.dinner.start);
  const dinnerEnd  = parse(membership.mess.timings.dinner.end);

  const isLunchNow = now >= lunchStart && now <= lunchEnd;
  const isDinnerNow= now >= dinnerStart && now <= dinnerEnd;
  if (isLunchNow && mealType !== 'Lunch') { res.status(400); throw new Error('Cannot toggle next meal while current meal is ongoing.'); }
  if (isDinnerNow && mealType !== 'Dinner') { res.status(400); throw new Error('Cannot toggle next meal while current meal is ongoing.'); }

  // Plan constraint
  const plan = membership.mealPlan.name;
  if ((plan === 'Lunch' && mealType !== 'Lunch') || (plan === 'Dinner' && mealType !== 'Dinner')) {
    res.status(400); throw new Error(`Your meal plan (${plan}) does not include ${mealType}.`);
  }
  // Deadline at meal end
  const endTime = mealType === 'Lunch' ? lunchEnd : dinnerEnd;
  if (now > endTime) { res.status(400); throw new Error(`The cutoff time for toggling ${mealType} has passed.`); }

  const mealSkip = await MealSkip.create({
    membership: membershipId,
    date: targetDate,
    mealType,
    isRebateEligible: membership.mess.toggleSkipRebatePercentage > 0,
    rebatePercentage: membership.mess.toggleSkipRebatePercentage
  });
  res.status(201).json({ message: `Marked not eating for ${mealType}.`, mealSkip });
});

const updateMyProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  if (!user) { res.status(404); throw new Error('User not found'); }
  const { name, kioskPin } = req.body;
  if (typeof name === 'string' && name.trim()) user.name = name.trim();
  if (kioskPin !== undefined) {
    const pinStr = String(kioskPin);
    if (!/^[0-9]{4,6}$/.test(pinStr)) { res.status(400); throw new Error('Kiosk PIN must be 4-6 digits.'); }
    user.kioskPin = pinStr;
  }
  await user.save();
  res.json({ name: user.name, phone: user.phone, kioskPin: user.kioskPin });
});

const leaveMembership = asyncHandler(async (req, res) => {
  const { membershipId } = req.params;
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id });
  if (!membership) { res.status(404); throw new Error('Membership not found'); }
  const due = await Invoice.countDocuments({ membership: membershipId, status: 'due' });
  if (due > 0) { res.status(400); throw new Error('Clear dues before leaving.'); }
  membership.status = 'inactive';
  await membership.save();
  res.json({ message: 'Membership left successfully' });
});

const getAttendance = async (req, res) => {
  const { membershipId } = req.params;
  const { year, month } = req.query;
  const y = parseInt(year, 10);
  const m = parseInt(month, 10);
  const start = new Date(Date.UTC(y, m - 1, 1));
  const end = new Date(Date.UTC(y, m, 1));
  const MealRecord = require('../models/mealRecord.model');
  const rows = await MealRecord.find({ membership: membershipId, date: { $gte: start, $lt: end } })
    .select('date lunchStatus dinnerStatus')
    .lean();
  res.json(rows.map(r => ({ date: r.date, lunchStatus: r.lunchStatus || 'NA', dinnerStatus: r.dinnerStatus || 'NA' })));
};


const notifyPayment = asyncHandler(async (req, res) => {
  const { invoiceId } = req.params;
  const { proofUrl } = req.body;
  const invoice = await Invoice.findById(invoiceId).populate({ path: 'membership', match: { customer: req.user._id } });
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
  res.status(200).json({ message: 'Manager has been notified of your payment.' });
});

const getMyMemberships = asyncHandler(async (req, res) => {
  const memberships = await Membership.find({ customer: req.user._id, status: 'active' }).populate('mess', 'name address');
  res.status(200).json(memberships);
});

module.exports = {
  getAttendance,
  leaveMembership,
  getMyProfile,
  updateMyProfile,
  getMyInvoices,
  joinMess,
  markLeave,
  toggleMealSkip,
  notifyPayment,
  getMyMemberships,
};
