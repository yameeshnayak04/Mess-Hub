// routes/reviewRoutes
const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { addReviewSchema, getReviewsSchema } = require('../middleware/schemas');

router.get('/:messId', validate(getReviewsSchema), reviewController.getReviews);
router.post('/:messId', protect, authorize('Customer'), validate(addReviewSchema), reviewController.addReview);

module.exports = router;
