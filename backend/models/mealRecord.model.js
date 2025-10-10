// This file defines the data structure for logging every meal.

const mongoose = require('mongoose');

const MealRecordSchema = new mongoose.Schema({
  // Reference to the User who ate the meal.
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    required: false,
    ref: 'User',
  },
  // Reference to the Mess where the meal was eaten.
  mess: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Mess',
  },
  // The type of meal that was eaten (e.g., Lunch, Dinner).
  mealType: {
      type: String,
      enum: ['Lunch', 'Dinner'], // Assuming only these two for simplicity
      required: true,
  }
}, { timestamps: true }); // The 'createdAt' field will serve as the meal timestamp.

// Create the MealRecord model from the schema.
const MealRecord = mongoose.model('MealRecord', MealRecordSchema);

// Export the model.
module.exports = MealRecord;