const Review = require('../models/Review');
const Mess = require('../models/Mess');
const Membership = require('../models/Membership');

// @desc    Add review for a mess
// @route   POST /api/reviews/:messId
// @access  Private (Customer only)
exports.addReview = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const { rating, comment } = req.body;

    // Check if mess exists
    const mess = await Mess.findById(messId);

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'Mess not found'
      });
    }

    // Check if user has active or past membership
    const membership = await Membership.findOne({
      user: req.user.id,
      mess: messId,
      status: { $in: ['Active', 'Inactive'] }
    });

    if (!membership) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of this mess to leave a review'
      });
    }

    // Create review (unique index will prevent duplicates)
    const review = await Review.create({
      user: req.user.id,
      mess: messId,
      rating,
      comment
    });

    const populatedReview = await Review.findById(review._id)
      .populate('user', 'name');

    res.status(201).json({
      success: true,
      data: populatedReview,
      message: 'Review added successfully'
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this mess'
      });
    }
    next(error);
  }
};

// @desc    Get reviews for a mess
// @route   GET /api/reviews/:messId
// @access  Private
exports.getReviews = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const reviews = await Review.find({ mess: messId })
      .populate('user', 'name')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Review.countDocuments({ mess: messId });

    // Calculate average rating
    const allReviews = await Review.find({ mess: messId });
    const averageRating = allReviews.length > 0
      ? allReviews.reduce((sum, review) => sum + review.rating, 0) / allReviews.length
      : 0;

    res.status(200).json({
      success: true,
      count: reviews.length,
      total,
      averageRating: Number(averageRating.toFixed(1)),
      data: reviews
    });
  } catch (error) {
    next(error);
  }
};

// Update or create (upsert) a user's review for a mess
// @route PUT /api/reviews/:messId
// @access Private (Customer)
exports.upsertMyReview = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const { rating, comment } = req.body;

    const mess = await Mess.findById(messId);
    if (!mess) {
      return res.status(404).json({ success: false, message: 'Mess not found' });
    }

    // Must be a current or past member
    const membership = await Membership.findOne({
      user: req.user.id,
      mess: messId,
      status: { $in: ['Active', 'Inactive'] },
    });
    if (!membership) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of this mess to leave a review',
      });
    }

    // Update if exists; else create
    const existing = await Review.findOne({ user: req.user.id, mess: messId });
    if (existing) {
      if (typeof rating === 'number') existing.rating = rating;
      if (typeof comment === 'string') existing.comment = comment;
      await existing.save();
      const populated = await Review.findById(existing._id).populate('user', 'name');
      return res.status(200).json({ success: true, data: populated, message: 'Review updated successfully' });
    } else {
      const created = await Review.create({
        user: req.user.id,
        mess: messId,
        rating,
        comment,
      });
      const populated = await Review.findById(created._id).populate('user', 'name');
      return res.status(201).json({ success: true, data: populated, message: 'Review added successfully' });
    }
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'You have already reviewed this mess' });
    }
    next(error);
  }
};

// Get current user's review for a mess (helps prefill edit form)
// @route GET /api/reviews/:messId/me
// @access Private (Customer)
exports.getMyReview = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const review = await Review.findOne({ user: req.user.id, mess: messId }).populate('user', 'name');
    if (!review) {
      return res.status(200).json({ success: true, data: null });
    }
    return res.status(200).json({ success: true, data: review });
  } catch (error) {
    next(error);
  }
};

