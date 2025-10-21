// This file defines the data structure for logging every meal.

const mongoose = require('mongoose');

const MealRecordSchema = new mongoose.Schema({
  mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
  // **CORRECTED**: The 'membership' is the single source of truth for a monthly user.
  // If this field is null, it signifies a daily walk-in user.
  membership: { type: mongoose.Schema.Types.ObjectId, ref: 'Membership', required: false },
  date: { type: Date, required: true }, // Normalized to the start of the day in the mess's timezone.
  mealType: { type: String, enum: ['Lunch', 'Dinner'], required: true },
  isManagerOverride: { type: Boolean, default: false },
}, { timestamps: true }); // 'createdAt' serves as the exact timestamp of the entry.

// A compound unique index to prevent logging the same meal twice for a member.
// It is a sparse index, so it won't apply to daily users where 'membership' is null.
MealRecordSchema.index({ membership: 1, date: 1, mealType: 1 }, { unique: true, sparse: true });

const MealRecord = mongoose.model('MealRecord', MealRecordSchema);
module.exports = MealRecord;