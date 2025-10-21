// models/mealSkip.model.js
const mongoose = require('mongoose');

const MealSkipSchema = new mongoose.Schema(
  {
    membership: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Membership' },
    date: { type: Date, required: true }, // normalized to start of day
    mealType: { type: String, enum: ['Lunch', 'Dinner'], required: true },
    isRebateEligible: { type: Boolean, required: true },
    // percentage: 0-100 applied to perThaliRebateRate
    rebatePercentage: { type: Number, required: true },
  },
  { timestamps: true }
);

MealSkipSchema.index({ membership: 1, date: 1, mealType: 1 }, { unique: true });

module.exports = mongoose.model('MealSkip', MealSkipSchema);
