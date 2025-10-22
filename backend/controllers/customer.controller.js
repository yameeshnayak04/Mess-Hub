// controllers/customer.controller.js
const Membership = require('../models/membership.model.js');
const Mess = require('../models/mess.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const MealRecord = require('../models/mealRecord.model.js');
const Invoice = require('../models/invoice.model.js');
const Review = require('../models/review.model.js');
const User = require('../models/user.model.js');
const asyncHandler = require('../utils/asynchandler.js');

// Helpers
const startOfDay = (d) => { const x = new Date(d); x.setHours(0,0,0,0); return x; };
const endOfDay = (d) => { const x = new Date(d); x.setHours(23,59,59,999); return x; };
const parseHHmmOn = (date, hhmm) => { const d = new Date(date); const [h,m] = (hhmm||'00:00').split(':').map(Number); d.setHours(h,m,0,0); return d; };

const getProfile = asyncHandler(async (req, res) => {
  res.status(200).json({ _id: req.user._id, name: req.user.name, phone: req.user.phone, role: req.user.role, photoUrl: req.user.photoUrl || '' });
});

const setKioskPin = asyncHandler(async (req, res) => {
  if (req.user.role !== 'customer') { res.status(403); throw new Error('Only customers can set a kiosk PIN.'); }
  const { pin } = req.body;
  if (!pin || !/^\d{4}$/.test(pin)) { res.status(400); throw new Error('A 4-digit PIN is required.'); }
  const user = await User.findById(req.user._id).select('+pin');
  if (!user) { res.status(404); throw new Error('User not found'); }
  user.pin = pin; // hashed by model
  await user.save();
  res.status(200).json({ message: 'PIN set successfully.' });
});

const updateKioskPin = setKioskPin;

const updateProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  if (!user) { res.status(404); throw new Error('User not found'); }
  const { name, photoUrl } = req.body;
  if (typeof name === 'string' && name.trim()) user.name = name.trim();
  if (typeof photoUrl === 'string') user.photoUrl = photoUrl;
  await user.save();
  res.status(200).json({ _id: user._id, name: user.name, phone: user.phone, photoUrl: user.photoUrl });
});

// Join Mess
const joinMess = asyncHandler(async (req, res) => {
  const { messId, mealPlanId } = req.body;
  const mess = await Mess.findById(messId);
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  // Only 'Monthly Only' or 'Both' are allowed
  if (!['Monthly Only', 'Both'].includes(mess.serviceType)) { res.status(400); throw new Error('Invalid mess service type'); }
  const activeCount = await Membership.countDocuments({ mess: messId, status: 'active' });
  if (activeCount >= mess.maxMembers) { res.status(400); throw new Error('This mess is at full capacity'); }
  const plan = mess.mealPlans.id(mealPlanId);
  if (!plan) { res.status(404); throw new Error('Meal plan not found'); }
  const existing = await Membership.findOne({ customer: req.user._id, mess: messId, status: 'active' });
  if (existing) { res.status(400); throw new Error('Already an active member'); }
  const currentPrice = plan.priceHistory[plan.priceHistory.length - 1].price;
  const membership = await Membership.create({
    customer: req.user._id,
    mess: messId,
    mealPlan: {
      name: plan.name,
      price: currentPrice,
      perThaliRebateRate: plan.perThaliRebateRate,
    },
  });
  res.status(201).json(membership);
});

// Get My Memberships
const getMyMemberships = asyncHandler(async (req, res) => {
  const memberships = await Membership.find({ customer: req.user._id, status: 'active' }).populate('mess', 'name address city serviceType dailyThaliRate');
  res.status(200).json(memberships);
});

// Get Membership Details
const getMembershipDetails = asyncHandler(async (req, res) => {
  const { membershipId } = req.params;
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
  if (!membership) { res.status(404); throw new Error('Membership not found'); }
  const invoices = await Invoice.find({ membership: membership._id }).sort({ year: -1, month: -1 });
  res.status(200).json({ membership, invoices });
});

// Toggle Meal Skip
const toggleMealSkip = asyncHandler(async (req, res) => {
  const { membershipId } = req.params;
  const { date, mealType } = req.body; // Lunch or Dinner
  if (!['Lunch', 'Dinner'].includes(mealType)) { res.status(400); throw new Error('Invalid mealType'); }
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
  if (!membership) { res.status(404); throw new Error('Membership not found'); }
  // Plan constraint
  const plan = membership.mealPlan.name;
  if ((plan === 'Lunch' && mealType !== 'Lunch') || (plan === 'Dinner' && mealType !== 'Dinner')) { res.status(400); throw new Error(`Your meal plan (${plan}) does not include ${mealType}`); }
  const d = startOfDay(date || new Date());
  // Not allowed after meal end
  const endHHmm = mealType === 'Lunch' ? membership.mess.timings?.lunch?.end : membership.mess.timings?.dinner?.end;
  if (!endHHmm) { res.status(400); throw new Error('Mess timings not configured'); }
  const cutoff = parseHHmmOn(d, endHHmm);
  if (new Date() > cutoff) { res.status(400); throw new Error(`Cutoff to toggle ${mealType} has passed`); }
  // Cannot toggle if on leave that date
  const onLeave = await Leave.findOne({ membership: membership._id, startDate: { $lte: d }, endDate: { $gte: d } });
  if (onLeave) { res.status(400); throw new Error('Cannot toggle skip while on leave'); }
  const doc = await MealSkip.findOneAndUpdate(
    { membership: membership._id, date: d, mealType },
    {
      membership: membership._id,
      date: d,
      mealType,
      isRebateEligible: (membership.mess.toggleSkipRebatePercentage || 0) > 0,
      rebatePercentage: membership.mess.toggleSkipRebatePercentage || 0,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  res.status(200).json({ message: `Skip marked for ${mealType}`, mealSkip: doc });
});

// Mark Leave (single month, deadline, rebate eligibility)
const markLeave = asyncHandler(async (req, res) => {
  const { membershipId } = req.params;
  const { startDate, endDate } = req.body;
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id }).populate('mess');
  if (!membership) { res.status(404); throw new Error('Membership not found'); }
  const mess = membership.mess;
  const start = startOfDay(startDate);
  const end = startOfDay(endDate);
  if (start > end) { res.status(400); throw new Error('End date must be on or after start date'); }
  // Cannot span months (model validates too)
  if (start.getMonth() !== end.getMonth() || start.getFullYear() !== end.getFullYear()) { res.status(400); throw new Error('Leave cannot span across months'); }
  // Enforce deadline for tomorrow start
  const today = startOfDay(new Date());
  const tomorrow = new Date(today); tomorrow.setDate(tomorrow.getDate() + 1);
  if (start.getTime() === tomorrow.getTime()) {
    const deadlineStr = mess.leaveApplicationDeadlineTime || '22:00';
    const deadline = parseHHmmOn(today, deadlineStr);
    if (new Date() > deadline) { res.status(400); throw new Error(`Deadline to apply for tomorrow's leave (${deadlineStr}) has passed`); }
  }
  // Cannot overlap existing leaves
  const overlap = await Leave.findOne({ membership: membership._id, $or: [{ startDate: { $lte: end }, endDate: { $gte: start } }] });
  if (overlap) { res.status(400); throw new Error('Leave dates overlap with existing leave'); }
  const leave = await Leave.create({ membership: membership._id, startDate: start, endDate: end, duration: 1 }); // duration set by pre-validate hook
  // Rebate eligibility
  if (leave.duration >= (mess.rebateMinDays || 0)) {
    leave.isRebateEligible = true;
    const mealsPerDay = membership.mealPlan.name === 'Full Day' ? 2 : 1;
    leave.rebateAmount = leave.duration * mealsPerDay * membership.mealPlan.perThaliRebateRate;
    await leave.save();
  }
  res.status(201).json({ message: 'Leave marked', leave });
});

// Attendance calendar
const getAttendance = asyncHandler(async (req, res) => {
  const { membershipId } = req.params;
  const { year, month } = req.query; // month 1-12
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id });
  if (!membership) { res.status(404); throw new Error('Membership not found'); }
  const y = parseInt(year, 10), m = parseInt(month, 10);
  if (!y || !m) { res.status(400); throw new Error('year and month are required'); }
  const from = new Date(Date.UTC(y, m - 1, 1)); const to = new Date(Date.UTC(y, m, 1));
  const [records, skips, leaves] = await Promise.all([
    MealRecord.find({ membership: membership._id, date: { $gte: from, $lt: to } }).select('date mealType').lean(),
    MealSkip.find({ membership: membership._id, date: { $gte: from, $lt: to } }).select('date mealType').lean(),
    Leave.find({ membership: membership._id, $or: [{ startDate: { $lte: to }, endDate: { $gte: from } }] }).select('startDate endDate').lean(),
  ]);
  const recSet = new Set(records.map(r => `${startOfDay(r.date).toISOString()}|${r.mealType}`));
  const skipSet = new Set(skips.map(r => `${startOfDay(r.date).toISOString()}|${r.mealType}`));
  const isOnLeave = (d) => leaves.some(l => startOfDay(d) >= startOfDay(l.startDate) && startOfDay(d) <= startOfDay(l.endDate));
  const daysInMonth = new Date(y, m, 0).getDate();
  const out = [];
  for (let day = 1; day <= daysInMonth; day++) {
    const d = new Date(Date.UTC(y, m - 1, day));
    const keyL = `${d.toISOString()}|Lunch`, keyD = `${d.toISOString()}|Dinner`;
    const lunch = recSet.has(keyL) ? 'P' : (skipSet.has(keyL) ? 'S' : (isOnLeave(d) ? 'L' : 'A'));
    const dinner = recSet.has(keyD) ? 'P' : (skipSet.has(keyD) ? 'S' : (isOnLeave(d) ? 'L' : 'A'));
    out.push({ date: d, lunchStatus: lunch, dinnerStatus: dinner });
  }
  res.status(200).json(out);
});

// Ask for payment approval
const requestPaymentApproval = asyncHandler(async (req, res) => {
  const { invoiceId } = req.params;
  const { proofUrl } = req.body;
  const invoice = await Invoice.findById(invoiceId).populate({ path: 'membership', match: { customer: req.user._id } });
  if (!invoice || !invoice.membership) { res.status(404); throw new Error('Invoice not found or unauthorized'); }
  if (invoice.status !== 'due') { res.status(400); throw new Error(`Invoice not due; current status: ${invoice.status}`); }
  invoice.status = 'pending_approval';
  invoice.proofUrl = proofUrl || '';
  await invoice.save();
  res.status(200).json({ message: 'Payment submitted for approval', invoice });
});

// Get current dues (sum of due invoices for current month)
const getCurrentDues = asyncHandler(async (req, res) => {
  const now = new Date();
  const month = now.getMonth() + 1, year = now.getFullYear();
  const myMemberships = await Membership.find({ customer: req.user._id, status: 'active' }).select('_id');
  const invoices = await Invoice.find({ membership: { $in: myMemberships.map(m => m._id) }, month, year, status: 'due' });
  const totalDue = invoices.reduce((s, x) => s + x.amount, 0);
  res.status(200).json({ month, year, totalDue, invoices });
});

// Leave Membership
const leaveMembership = asyncHandler(async (req, res) => {
  const { membershipId } = req.params;
  const membership = await Membership.findOne({ _id: membershipId, customer: req.user._id });
  if (!membership) { res.status(404); throw new Error('Membership not found'); }
  const unpaid = await Invoice.countDocuments({ membership: membershipId, status: { $in: ['due', 'pending_approval'] } });
  if (unpaid > 0) { res.status(400); throw new Error('Clear dues before leaving'); }
  membership.status = 'cancelled';
  membership.endedAt = new Date();
  await membership.save();
  res.status(200).json({ message: 'Membership cancelled' });
});

// Update or create review
const upsertReview = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { rating, comment } = req.body;
  const membership = await Membership.findOne({ mess: messId, customer: req.user._id, status: 'active' });
  if (!membership) { res.status(403); throw new Error('Only active members can review'); }
  await Review.findOneAndUpdate(
    { mess: messId, customer: req.user._id },
    { rating, comment },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  // Optionally recompute aggregate asynchronously
  res.status(200).json({ message: 'Review updated' });
});

// Get Invoice (ensure belongs to user)
const getInvoice = asyncHandler(async (req, res) => {
  const { invoiceId } = req.params;
  const invoice = await Invoice.findById(invoiceId).populate('membership');
  if (!invoice) { res.status(404); throw new Error('Invoice not found'); }
  const belongs = await Membership.exists({ _id: invoice.membership, customer: req.user._id });
  if (!belongs) { res.status(403); throw new Error('Not authorized'); }
  res.status(200).json(invoice);
});

module.exports = {
  getProfile,
  setKioskPin,
  updateKioskPin,
  updateProfile,
  joinMess,
  getMyMemberships,
  getMembershipDetails,
  toggleMealSkip,
  markLeave,
  getAttendance,
  requestPaymentApproval,
  getCurrentDues,
  leaveMembership,
  upsertReview,
  getInvoice,
};
