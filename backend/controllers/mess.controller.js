// backend/controllers/mess.controller.js

const Mess = require('../models/mess.model.js');
const Review = require('../models/review.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Membership = require('../models/membership.model.js');
const asyncHandler = require('../utils/asynchandler.js');

// @desc    Register a new mess profile
const registerMess = asyncHandler(async (req, res) => {
    const existingMess = await Mess.findOne({ owner: req.user._id });
    if (existingMess) {
        res.status(400);
        throw new Error("You have already registered a mess.");
    }
    const mess = await Mess.create({ ...req.body, owner: req.user._id });
    res.status(201).json(mess);
});

// @desc    Get nearby messes
const getNearbyMesses = asyncHandler(async (req, res) => {
    const { lat, lng, radius = 50, filter } = req.query; // Default to a large 50km radius
    if (!lat || !lng) {
        res.status(400);
        throw new Error("Latitude and longitude are required.");
    }
    const radiusInMeters = parseFloat(radius) * 1000;
    let query = {
        location: {
            $nearSphere: {
                $geometry: { type: "Point", coordinates: [parseFloat(lng), parseFloat(lat)] },
                $maxDistance: radiusInMeters
            }
        },
        status: 'active'
    };
    if (filter) query.cuisine = filter;
    
    const messes = await Mess.find(query).select('name address serviceType dailyThaliRate averageRating location cuisine');
    res.status(200).json(messes);
});

// @desc    Get the full public profile of a single mess
const getMessProfile = asyncHandler(async (req, res) => {
    const mess = await Mess.findById(req.params.messId).populate('owner', 'name photoUrl');
    if (!mess) {
        res.status(404);
        throw new Error("Mess not found");
    }
    res.status(200).json(mess);
});

// @desc    Customer posts a review for a mess
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

    // Update the mess's average rating in real-time
    const reviews = await Review.find({ mess: messId });
    mess.reviewCount = reviews.length;
    mess.averageRating = reviews.reduce((acc, item) => item.rating + acc, 0) / reviews.length;
    await mess.save();

    res.status(201).json(review);
});

// @desc    Get all reviews for a mess
const getMessReviews = asyncHandler(async (req, res) => {
    const reviews = await Review.find({ mess: req.params.messId })
        .populate('customer', 'name photoUrl')
        .sort({ createdAt: -1 });
    res.status(200).json(reviews);
});

// @desc    Get the weekly menu for a mess
const getWeeklyMenu = asyncHandler(async (req, res) => {
    // A real implementation would dynamically calculate the current weekIdentifier
    const currentWeekIdentifier = "2025-W42"; // Placeholder
    const menu = await WeeklyMenu.findOne({ mess: req.params.messId, weekIdentifier: currentWeekIdentifier });
    if (!menu) {
        res.status(404);
        throw new Error('Menu has not been set for this week.');
    }
    res.status(200).json(menu);
});

module.exports = { registerMess, getNearbyMesses, getMessProfile, createReview, getMessReviews, getWeeklyMenu };