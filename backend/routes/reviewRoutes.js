// routes/reviewRoutes
const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { reviewSchema } = require('../middleware/schemas'); // Fixed import name

// Removed validation: getReviewsSchema is missing
router.get('/:messId', reviewController.getReviews);
router.post('/:messId', protect, authorize('Customer'), validate(reviewSchema), reviewController.addReview);

module.exports = router;