// This file contains the logic for creating and discovering messes.

const Mess = require('../models/mess.model.js');
const User = require('../models/user.model.js');

// @desc    Register a new mess
// @route   POST /api/messes
// @access  Private (Manager only)
const registerMess = async (req, res) => {
    // The 'protect' and 'isManager' middlewares will run before this,
    // so req.user will contain the authenticated manager's data.

    // Destructure all required mess details from the request body.
    const {
        name,
        address,
        managerContact,
        location, // Should be { type: "Point", coordinates: [lng, lat] }
        serviceType,
        dailyThaliRate,
        mealPlans,
        timings
    } = req.body;

    // Basic validation
    if (!name || !address || !location || !serviceType || !managerContact) {
        return res.status(400).json({ message: "Please provide all required mess details." });
    }

    try {
        // Check if this manager already owns a mess.
        const existingMess = await Mess.findOne({ owner: req.user._id });
        if (existingMess) {
            return res.status(400).json({ message: "You have already registered a mess." });
        }

        // Create a new mess document in the database.
        const mess = await Mess.create({
            name,
            address,
            managerContact,
            location,
            serviceType,
            dailyThaliRate,
            mealPlans,
            timings,
            owner: req.user._id, // Link the mess to the logged-in manager.
        });

        res.status(201).json(mess);

    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// @desc    Get nearby messes based on user's location
// @route   GET /api/messes/nearby?lat=...&lng=...&radius=...
// @access  Private (Customer only)
const getNearbyMesses = async (req, res) => {
    // Get latitude, longitude, and radius from the query parameters.
    const { lat, lng, radius } = req.query; // radius is in kilometers

    if (!lat || !lng) {
        return res.status(400).json({ message: "Latitude and longitude are required." });
    }

    // Convert radius from kilometers to meters for MongoDB's $maxDistance operator.
    const radiusInMeters = (radius || 10) * 1000; // Default to 10km if no radius is provided.

    try {
        // Use a geospatial query to find messes.
        const messes = await Mess.find({
            location: {
                $nearSphere: {
                    $geometry: {
                        type: "Point",
                        coordinates: [parseFloat(lng), parseFloat(lat)] // [longitude, latitude]
                    },
                    $maxDistance: radiusInMeters
                }
            }
        });

        res.status(200).json(messes);

    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// @desc    Get the public profile of a single mess
// @route   GET /api/messes/:messId
// @access  Public
const getMessProfile = async (req, res) => {
    try {
        // Find the mess by its ID, which is passed as a URL parameter.
        // We also use .populate() to fetch the owner's details (name and phone) from the User collection.
        const mess = await Mess.findById(req.params.messId).populate('owner', 'name phone');

        if (!mess) {
            return res.status(404).json({ message: "Mess not found" });
        }

        res.status(200).json(mess);

    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

module.exports = {
    registerMess,
    getNearbyMesses,
    getMessProfile,
};