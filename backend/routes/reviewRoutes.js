// routes/reviewRoutes.js

const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { reviewSchema } = require('../middleware/schemas');

// List reviews for a mess (public or protected as per your policy)
router.get('/:messId', reviewController.getReviews);

// Current user's review (prefill editor)
router.get('/:messId/me', protect, authorize('Customer'), reviewController.getMyReview);

// Add new review (legacy)
router.post('/:messId', protect, authorize('Customer'), validate(reviewSchema), reviewController.addReview);

// Upsert (add or update in one endpoint)
router.put('/:messId', protect, authorize('Customer'), validate(reviewSchema), reviewController.upsertMyReview);

module.exports = router;
