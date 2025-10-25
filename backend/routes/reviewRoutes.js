const express = require('express');
const { addReview, getReviews } = require('../controllers/reviewController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { reviewSchema } = require('../middleware/schemas');

const router = express.Router();

router.post('/:messId', protect, authorize('Customer'), validate(reviewSchema), addReview);

router.get('/:messId', protect, getReviews);

module.exports = router;
