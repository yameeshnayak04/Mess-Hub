// controllers/mess.controller.js
const Mess = require('../models/mess.model.js');
const Review = require('../models/review.model.js');
const DailyMenu = require('../models/dailyMenu.model.js'); // new model replacing weekly
const Membership = require('../models/membership.model.js');
const asyncHandler = require('../utils/asynchandler.js');

// Register Mess
const registerMess = asyncHandler(async (req, res) => {
  const existing = await Mess.findOne({ owner: req.user._id });
  if (existing) { res.status(400); throw new Error('You have already registered a mess'); }
  const allowedService = ['Monthly Only', 'Both'];
  if (!allowedService.includes(req.body.serviceType)) { res.status(400); throw new Error('Invalid serviceType'); }
  const mess = await Mess.create({ ...req.body, owner: req.user._id });
  res.status(201).json(mess);
});

// Search Mess (name/address substring)
const searchMess = asyncHandler(async (req, res) => {
  const { q } = req.query;
  const filter = q ? { $or: [{ name: new RegExp(q, 'i') }, { address: new RegExp(q, 'i') }, { city: new RegExp(q, 'i') }] } : {};
  const rows = await Mess.find(filter).limit(200);
  res.status(200).json(rows);
});

// Nearby Messes
const getNearbyMess = asyncHandler(async (req, res) => {
  const { lat, lng, radius = 10, q } = req.query;
  if (!lat || !lng) { res.status(400); throw new Error('lat and lng are required'); }
  const pipeline = [
    { $geoNear: { near: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] }, distanceField: 'distance', spherical: true, maxDistance: parseFloat(radius) * 1000 } },
    ...(q ? [{ $match: { $or: [{ name: new RegExp(q, 'i') }, { address: new RegExp(q, 'i') }, { city: new RegExp(q, 'i') }] } }] : []),
    { $limit: 200 },
  ];
  const results = await Mess.aggregate(pipeline);
  res.status(200).json(results);
});

// Get Mess Profile
const getMessProfile = asyncHandler(async (req, res) => {
  const mess = await Mess.findById(req.params.messId).populate('owner', 'name photoUrl');
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  res.status(200).json(mess);
});

// Get Daily Menu
const getMenu = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const date = req.query.date ? new Date(req.query.date) : new Date();
  date.setHours(0,0,0,0);
  const menu = await DailyMenu.findOne({ mess: messId, date });
  res.status(200).json(menu || { mess: messId, date, lunch: '', dinner: '' });
});

// Update Daily Menu (manager-only route should use requireMessOwner)
const updateMenu = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const { date, lunch, dinner, lunchImage, dinnerImage } = req.body;
  const d = new Date(date || new Date()); d.setHours(0,0,0,0);
  const menu = await DailyMenu.findOneAndUpdate(
    { mess: messId, date: d },
    { mess: messId, date: d, lunch, dinner, lunchImage, dinnerImage },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  res.status(200).json(menu);
});

// Update Mess Profile (manager-only)
const updateMessProfile = asyncHandler(async (req, res) => {
  const { messId } = req.params;
  const allowed = ['name', 'address', 'city', 'cuisine', 'serviceType', 'dailyThaliRate', 'timings', 'toggleSkipRebatePercentage', 'minMonthlyCharge', 'maxMembers', 'securityDeposit', 'leaveApplicationDeadlineTime', 'specialThaliRate'];
  const mess = await Mess.findById(messId);
  if (!mess) { res.status(404); throw new Error('Mess not found'); }
  Object.keys(req.body).forEach((k) => { if (allowed.includes(k)) mess[k] = req.body[k]; });
  // Enforce serviceType rule and dailyThaliRate requirement for 'Both'
  if (!['Monthly Only', 'Both'].includes(mess.serviceType)) { res.status(400); throw new Error('Invalid serviceType'); }
  if (mess.serviceType === 'Both' && (mess.dailyThaliRate === undefined || mess.dailyThaliRate === null)) { res.status(400); throw new Error('dailyThaliRate required when serviceType is Both'); }
  await mess.save();
  res.status(200).json(mess);
});

module.exports = { registerMess, searchMess, getNearbyMess, getMessProfile, getMenu, updateMenu, updateMessProfile };
