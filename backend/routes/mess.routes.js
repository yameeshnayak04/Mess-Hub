// This file defines the API routes for discovering and interacting with Mess profiles.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    registerMess,
    getNearbyMesses,
    getMessProfile,
    createReview,    // <-- New
    getMessReviews,  // <-- New
    getWeeklyMenu,   // <-- New
} = require('../controllers/mess.controller.js');

// Import our security middleware.
const { protect, isManager, isCustomer } = require('../middlewares/auth.middleware.js');

// --- ROUTES ---

// A Manager registers their mess.
router.post('/', protect, isManager, registerMess);

// A Customer finds nearby messes.
router.get('/nearby', protect, isCustomer, getNearbyMesses);

// Anyone can view the public profile of a mess.
router.get('/:messId', getMessProfile);

// A Customer posts a review for a mess.
router.post('/:messId/reviews', protect, isCustomer, createReview);

// Anyone can read the reviews for a mess.
router.get('/:messId/reviews', getMessReviews);

// Anyone can see the weekly menu for a mess.
router.get('/:messId/menu', getWeeklyMenu);


module.exports = router;