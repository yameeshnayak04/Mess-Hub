// controllers/mess.controller.js
const Mess = require('../models/mess.model.js');
const Review = require('../models/review.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Membership = require('../models/membership.model.js');
const asyncHandler = require('../utils/asynchandler.js');
const { getISOWeekIdentifier } = require('../utils/timeUtils');

const registerMess = asyncHandler(async (req, res) => {
  const existing = await Mess.findOne({ owner: req.user._id });
  if (existing) {
    res.status(400);
    throw new Error('You have already registered a mess.');
  }
  const mess = await Mess.create({ ...req.body, owner: req.user._id });
  res.status(201).json(mess);
});

const getNearbyMesses = asyncHandler(async (req, res) => {
  const { lat, lng, radius = 50, filter } = req.query;
  if (!lat || !lng) {
    res.status(400);
    throw new Error('Latitude and longitude are required.');
  }
  const radiusInMeters = parseFloat(radius) * 1000;
  const query = {
    location: {
      $nearSphere: {
        $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
        $maxDistance: radiusInMeters,
      },
    },
    status: 'active',
  };
  if (filter) query.cuisine = filter;
  const messes = await Mess.find(query).select('name address serviceType dailyThaliRate averageRating location cuisine');
  res.status(200).json(messes);
});

const getMessProfile = asyncHandler(async (req, res) => {
  const mess = await Mess.findById(req.params.messId).populate('owner', 'name photoUrl');
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found');
  }
  res.status(200).json(mess);
});

const createReview = asyncHandler(async (req, res) => {
  const { rating, comment } = req.body;
  const { messId } = req.params;
  const mess = await Mess.findById(messId);
  if (!mess) {
    res.status(404);
    throw new Error('Mess not found.');
  }
  const isMember = await Membership.findOne({ mess: messId, customer: req.user._id, status: 'active' });
  if (!isMember) {
    res.status(403);
    throw new Error('Only active members can post reviews.');
  }
  const review = await Review.create({ customer: req.user._id, mess: messId, rating, comment });

  const reviews = await Review.find({ mess: messId });
  mess.reviewCount = reviews.length;
  mess.averageRating = reviews.reduce((acc, item) => item.rating + acc, 0) / (reviews.length || 1);
  await mess.save();

  res.status(201).json(review);
});

const getMessReviews = asyncHandler(async (req, res) => {
  const reviews = await Review.find({ mess: req.params.messId }).populate('customer', 'name photoUrl').sort({ createdAt: -1 });
  res.status(200).json(reviews);
});

const getWeeklyMenu = asyncHandler(async (req, res) => {
  const currentWeekIdentifier = getISOWeekIdentifier(new Date());
  const menu = await WeeklyMenu.findOne({ mess: req.params.messId, weekIdentifier: currentWeekIdentifier });
  if (!menu) {
    res.status(404);
    throw new Error('Menu has not been set for this week.');
  }
  res.status(200).json(menu);
});

module.exports = { registerMess, getNearbyMesses, getMessProfile, createReview, getMessReviews, getWeeklyMenu };
