// models/mess.model.js
const mongoose = require('mongoose');

const PriceHistorySchema = new mongoose.Schema({
  price: { type: Number, required: true },
  effectiveDate: { type: Date, default: Date.now },
});

const MealPlanSchema = new mongoose.Schema({
  name: { type: String, enum: ['Lunch', 'Dinner', 'Full Day'], required: true },
  priceHistory: [PriceHistorySchema],
  // Per-thali rebate base for all rebates (unified)
  perThaliRebateRate: { type: Number, required: true, min: 0 },
});

const TimingsSchema = new mongoose.Schema({
  lunch: { start: String, end: String },
  dinner: { start: String, end: String },
});

const MessSchema = new mongoose.Schema(
  {
    // Profile
    name: { type: String, required: true, trim: true },
    owner: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },

    // Location & contact
    address: { type: String, required: true },
    city: { type: String, required: true },
    managerContact: {
      type: String,
      required: true,
      match: [/^\d{10}$/, 'Please provide a valid 10-digit phone number'],
    },
    location: {
      type: { type: String, enum: ['Point'], required: true },
      coordinates: { type: [Number], required: true }, // [lng, lat]
    },

    // Services & pricing
    cuisine: { type: String, enum: ['Veg', 'Non-Veg', 'Both'], required: true },
    serviceType: { type: String, enum: ['Monthly Only', 'Both'], required: true },
    dailyThaliRate: {
      type: Number,
      required: function () {
        return this.serviceType === 'Both';
      },
      min: 0,
    },
    specialThaliRate: { type: Number, min: 0 },
    mealPlans: {
      type: [MealPlanSchema],
      validate: {
        validator: function (v) {
          // For both Monthly Only and Both, monthly plans must exist
          return Array.isArray(v) && v.length > 0;
        },
        message: 'At least one meal plan is required',
      },
    },
    securityDeposit: { type: Number, default: 0, min: 0 },
    maxMembers: { type: Number, default: 100, min: 1 },

    // Policies
    timings: TimingsSchema,
    // Deadline time to apply for next-day leave, format HH:mm (24h)
    leaveApplicationDeadlineTime: { type: String, default: '22:00' },
    // Minimum consecutive days for leave rebate eligibility
    rebateMinDays: { type: Number, default: 4, min: 0 },
    // Toggle skip instant rebate percentage (0-100)
    toggleSkipRebatePercentage: { type: Number, min: 0, max: 100, default: 0 },
    // Monthly users are postpaid only; minMonthlyCharge applies to every month
    monthlyBillingType: { type: String, default: 'Post-Paid', enum: ['Post-Paid'] },
    minMonthlyCharge: { type: Number, default: 0, min: 0 },

    // Ratings
    averageRating: { type: Number, default: 0, min: 0, max: 5 },
    reviewCount: { type: Number, default: 0, min: 0 },
    galleryUrls: [String],
  },
  { timestamps: true }
);

MessSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Mess', MessSchema);
