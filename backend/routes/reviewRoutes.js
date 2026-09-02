// new_backend/routes/reviewRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { validateBody, validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const reviewController = require('../controllers/reviewController');

const router = express.Router();

router.get(
  '/:messId',
  protect,
  validateQuery(schemas.pageQuery),
  asyncHandler(reviewController.listReviews)
);
router.get(
  '/:messId/mine',
  protect,
  authorize('Customer'),
  asyncHandler(reviewController.getMyReview)
);

// One endpoint covers writing and editing: a customer has at most one review
// per mess, so "save my review" is the only action that exists.
router.put(
  '/:messId',
  protect,
  authorize('Customer'),
  validateBody(schemas.upsertReview),
  asyncHandler(reviewController.upsertMyReview)
);

module.exports = router;
