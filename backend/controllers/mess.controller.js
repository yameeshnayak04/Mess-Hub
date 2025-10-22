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

// Nearby and weekly menu should reflect real data and current weekday
const getNearbyMesses = async (req, res) => {
  const { lat, lng, radius = 10, filter } = req.query;
  if (!lat || !lng) return res.status(400).json({ message: 'lat and lng are required' });
  const pipeline = [
    {
      $geoNear: {
        near: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
        distanceField: 'distance',
        spherical: true,
        maxDistance: parseFloat(radius) * 1000
      }
    },
    ...(filter ? [{ $match: { $or: [{ name: new RegExp(filter, 'i') }, { address: new RegExp(filter, 'i') }] } }] : []),
    { $limit: 200 }
  ];
  const results = await require('../models/mess.model').aggregate(pipeline);
  res.json(results);
};

const getWeeklyMenu = async (req, res) => {
  const Mess = require('../models/mess.model');
  const { messId } = req.params;
  const { day } = req.query;
  const mess = await Mess.findById(messId);
  if (!mess) return res.status(404).json({ message: 'Mess not found' });
  const weekday = day || ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][new Date().getDay()];
  res.json(mess.weeklyMenu?.[weekday] || {});
};


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

module.exports = { registerMess, getNearbyMesses, getMessProfile, createReview, getMessReviews, getWeeklyMenu };
