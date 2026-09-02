// new_backend/controllers/reviewController.js
const reviewService = require('../services/reviewService');
const { readPagination } = require('../utils/pagination');

async function listReviews(req, res) {
  const { page, limit, offset } = readPagination(req.validatedQuery || {});
  const result = await reviewService.listReviews(req.params.messId, { page, limit, offset });
  res.json({ success: true, data: result.data, meta: result.meta });
}

// One endpoint for both writing and editing a review - a customer only ever
// has one review per mess, so "save my review" is the only action needed.
async function upsertMyReview(req, res) {
  const review = await reviewService.upsertReview(req.user.id, req.params.messId, req.body);
  res.json({ success: true, data: review });
}

async function getMyReview(req, res) {
  const review = await reviewService.getMyReview(req.user.id, req.params.messId);
  res.json({ success: true, data: review });
}

module.exports = { listReviews, upsertMyReview, getMyReview };
