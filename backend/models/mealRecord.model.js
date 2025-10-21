// models/mealRecord.model.js
const mongoose = require('mongoose');

const MealRecordSchema = new mongoose.Schema(
  {
    mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
    // For monthly users; null for daily walk-ins
    membership: { type: mongoose.Schema.Types.ObjectId, ref: 'Membership', required: false },
    date: { type: Date, required: true }, // normalized to start of day
    mealType: { type: String, enum: ['Lunch', 'Dinner'], required: true },
    isManagerOverride: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Prevent duplicate meal entries for a member on a day/meal
MealRecordSchema.index({ membership: 1, date: 1, mealType: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('MealRecord', MealRecordSchema);
