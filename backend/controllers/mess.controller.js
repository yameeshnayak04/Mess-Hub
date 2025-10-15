// This file contains the final logic for creating, discovering, and interacting with Mess profiles.

const Mess = require('../models/mess.model.js');
const Review = require('../models/review.model.js');
const WeeklyMenu = require('../models/weeklyMenu.model.js');
const Membership = require('../models/membership.model.js');

// @desc    Register a new mess profile
// @route   POST /api/messes
// @access  Private (Manager only)
const registerMess = async (req, res) => {
    // req.user is attached by the 'protect' & 'isManager' middlewares.
    try {
        const existingMess = await Mess.findOne({ owner: req.user._id });
        if (existingMess) {
            return res.status(400).json({ message: "You have already registered a mess." });
        }
        // Create a new mess and link it to the logged-in manager.
        const mess = await Mess.create({ ...req.body, owner: req.user._id });
        res.status(201).json(mess);
    } catch (error) {
        // Handle potential validation errors from the Mongoose schema.
        res.status(500).json({ message: "Server error during mess registration.", error: error.message });
    }
};

// @desc    Get nearby messes based on location and filters
// @route   GET /api/messes/nearby
// @access  Private (Customer only)
const getNearbyMesses = async (req, res) => {
    // Default radius is 10km if not provided.
    const { lat, lng, radius = 10, filter } = req.query; 
    if (!lat || !lng) {
        return res.status(400).json({ message: "Latitude and longitude are required." });
    }
    const radiusInMeters = parseFloat(radius) * 1000;
    
    // Build the main query object for the geospatial search.
    let query = {
        location: {
            $nearSphere: {
                $geometry: { type: "Point", coordinates: [parseFloat(lng), parseFloat(lat)] },
                $maxDistance: radiusInMeters
            }
        },
        status: 'active' // Only show messes that are currently active.
    };

    // Add optional filters to the query.
    if (filter) {
        query.cuisine = filter; // e.g., filter=Veg
    }
    
    try {
        // Select only the fields needed for the list view to optimize the response size.
        const messes = await Mess.find(query).select('name address serviceType dailyThaliRate averageRating location');
        res.status(200).json(messes);
    } catch (error) {
        res.status(500).json({ message: "Server error while fetching nearby messes.", error: error.message });
    }
};

// @desc    Get the full public profile of a single mess
// @route   GET /api/messes/:messId
// @access  Public
const getMessProfile = async (req, res) => {
    try {
        // Fetch the mess and populate its owner's public details.
        const mess = await Mess.findById(req.params.messId).populate('owner', 'name photoUrl');
        if (!mess) return res.status(404).json({ message: "Mess not found" });
        res.status(200).json(mess);
    } catch (error) {
        res.status(500).json({ message: "Server error while fetching mess profile.", error: error.message });
    }
};

// @desc    Customer posts a review for a mess
// @route   POST /api/messes/:messId/reviews
// @access  Private (Customer only)
const createReview = async (req, res) => {
    const { rating, comment } = req.body;
    const { messId } = req.params;
    try {
        const mess = await Mess.findById(messId);
        if (!mess) return res.status(404).json({ message: 'Mess not found.' });

        // A critical business rule: Only active members of a mess can post a review.
        const isMember = await Membership.findOne({ mess: messId, customer: req.user._id, status: 'active' });
        if (!isMember) return res.status(403).json({ message: 'Only active members can post reviews.' });

        // Create the new review document.
        const review = await Review.create({ customer: req.user._id, mess: messId, rating, comment });

        // This is a crucial operation: update the mess's average rating in real-time.
        // It is more efficient to store this calculated value than to compute it on every request.
        const reviews = await Review.find({ mess: messId });
        mess.reviewCount = reviews.length;
        // Calculate the new average by summing all ratings and dividing by the count.
        mess.averageRating = reviews.reduce((acc, item) => item.rating + acc, 0) / reviews.length;
        await mess.save();

        res.status(201).json(review);
    } catch (error) {
        res.status(500).json({ message: 'Server error while creating review.', error: error.message });
    }
};

// @desc    Get all reviews for a mess
// @route   GET /api/messes/:messId/reviews
// @access  Public
const getMessReviews = async (req, res) => {
    try {
        // Fetch reviews and populate the customer's public details. Sort by newest first.
        const reviews = await Review.find({ mess: req.params.messId })
            .populate('customer', 'name photoUrl')
            .sort({ createdAt: -1 });
        res.status(200).json(reviews);
    } catch (error) {
        res.status(500).json({ message: 'Server error while fetching reviews.', error: error.message });
    }
};

// @desc    Get the weekly menu for a mess
// @route   GET /api/messes/:messId/menu
// @access  Public
const getWeeklyMenu = async (req, res) => {
    try {
        // In a real application, you would dynamically calculate the current week's identifier.
        // For example: "2025-W42" for the 42nd week of 2025.
        const currentWeekIdentifier = "2025-W42"; // Placeholder
        const menu = await WeeklyMenu.findOne({ mess: req.params.messId, weekIdentifier: currentWeekIdentifier });
        if (!menu) return res.status(404).json({ message: 'Menu has not been set for this week.' });
        res.status(200).json(menu);
    } catch (error) {
        res.status(500).json({ message: 'Server error while fetching menu.', error: error.message });
    }
};

module.exports = {
    registerMess,
    getNearbyMesses,
    getMessProfile,
    createReview,
    getMessReviews,
    getWeeklyMenu,
};