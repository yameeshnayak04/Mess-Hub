const mongoose = require('mongoose');

const MealRecordSchema = new mongoose.Schema({
  mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false },
  mealType: { type: String, enum: ['Lunch', 'Dinner'], required: true },
  
  // **NEW**: A flag for auditing purposes to track manager overrides.
  isManagerOverride: {
    type: Boolean,
    default: false,
  },
}, { 
  timestamps: true 
});

const MealRecord = mongoose.model('MealRecord', MealRecordSchema);
module.exports = MealRecord;