// **NEW FILE**
// This file defines the data structure for logging an informal "Not Eating" toggle.

const mongoose = require('mongoose');

const MealSkipSchema = new mongoose.Schema({
  // A reference to the specific membership this skip belongs to.
  membership: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Membership',
  },
  // The specific date of the skipped meal.
  date: {
    type: Date,
    required: true,
  },
  // The type of meal that was skipped.
  mealType: {
    type: String,
    enum: ['Lunch', 'Dinner'],
    required: true,
  },
  // A flag to mark if this skip qualifies for a rebate, based on the mess's policy.
  // This will be calculated by the backend logic when the record is created.
  isRebateEligible: {
    type: Boolean,
    required: true,
  },
  // Stores the percentage of rebate applied (e.g., 100 for Full, 50 for Partial, 0 for None).
  rebatePercentage: {
    type: Number,
    required: true,
  }
}, { timestamps: true });

// To prevent a user from skipping the same meal twice, we create a compound unique index.
// No two documents can have the same combination of membership, date, and mealType.
MealSkipSchema.index({ membership: 1, date: 1, mealType: 1 }, { unique: true });

const MealSkip = mongoose.model('MealSkip', MealSkipSchema);
module.exports = MealSkip;