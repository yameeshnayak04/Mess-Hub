// This file defines the advanced data structure for a mess profile.

const mongoose = require('mongoose');

// Define a sub-schema for the price history of a meal plan.
// This allows the manager to change prices without affecting old records.
const PriceHistorySchema = new mongoose.Schema({
  // The price value.
  price: { type: Number, required: true },
  // The date from which this price is effective.
  effectiveDate: { type: Date, default: Date.now },
});

// Define an updated sub-schema for individual meal plans.
const MealPlanSchema = new mongoose.Schema({
  // The name of the plan is now restricted to specific values.
  name: {
    type: String,
    enum: ['Lunch', 'Dinner', 'Full Day'],
    required: true,
  },
  // The price is now an array to track changes over time.
  // The current price is the last one in the array.
  priceHistory: [PriceHistorySchema],
  // The specific per-day rate to be deducted for this plan during eligible leaves.
  perDayRebateRate: { type: Number, required: true },
});

// Define a sub-schema for the mess's operating hours.
const TimingsSchema = new mongoose.Schema({
    lunch: {
        start: { type: String, default: '11:00' }, // e.g., "11:00"
        end: { type: String, default: '14:00' },   // e.g., "14:00"
    },
    dinner: {
        start: { type: String, default: '19:00' }, // e.g., "19:00"
        end: { type: String, default: '22:00' },   // e.g., "22:00"
    }
});


// Define the main, updated schema for the Mess collection.
const MessSchema = new mongoose.Schema({
  // --- Basic Profile Information ---
  name: { type: String, required: true },
  address: { type: String, required: true },
  // The manager's public contact number.
  managerContact: { type: String, required: true },
  // Geolocation for map features. Uses GeoJSON format.
  location: {
    type: {
      type: String,
      enum: ['Point'], // 'location.type' must be 'Point'
      required: true,
    },
    coordinates: {
      type: [Number], // Array of numbers for [longitude, latitude]
      required: true,
    },
  },
  // Defines who the mess serves.
  serviceType: {
    type: String,
    enum: ['Daily Only', 'Monthly Only', 'Both'],
    required: true,
  },
  // A reference to the User who owns/manages this mess.
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'User',
  },

  // --- Pricing & Plans ---
  // The rate for a single thali for non-monthly, walk-in customers.
  dailyThaliRate: {
    type: Number,
    // Only required if the mess serves daily users.
    required: function() { return this.serviceType === 'Daily Only' || this.serviceType === 'Both'; }
  },
  // An array of monthly meal plans offered.
  mealPlans: [MealPlanSchema],

  // --- Operational Rules & Timings ---
  timings: TimingsSchema,
  // The day of the month (e.g., 26) after which leaves for the current month cannot be marked.
  leaveCutoffDay: { type: Number, default: 26 },
  // The time on the cutoff day.
  leaveCutoffTime: { type: String, default: '22:00' },
  // The minimum number of consecutive days for a leave to be rebate-eligible.
  rebateMinDays: { type: Number, default: 4 },

}, { timestamps: true });

// Create a 2dsphere index on the location field to enable geospatial queries (like "find nearby").
MessSchema.index({ location: '2dsphere' });

// Create the Mess model from the schema.
const Mess = mongoose.model('Mess', MessSchema);

// Export the model.
module.exports = Mess;