const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5,
  },
  comment: { type: String },
}, { timestamps: true });

const Review = mongoose.model('Review', ReviewSchema);
module.exports = Review;