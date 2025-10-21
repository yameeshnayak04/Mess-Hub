// This file defines the final, bulletproof data structure for a Mess Profile.

const mongoose = require('mongoose');

// Sub-schema for tracking price changes over time.
const PriceHistorySchema = new mongoose.Schema({
  price: { type: Number, required: true },
  effectiveDate: { type: Date, default: Date.now },
});

// Sub-schema for defining a specific monthly meal plan.
const MealPlanSchema = new mongoose.Schema({
  name: { type: String, enum: ['Lunch', 'Dinner', 'Full Day'], required: true },
  priceHistory: [PriceHistorySchema],
  // The per-thali rate used for calculating all rebates for this plan.
  perThaliRebateRate: { type: Number, required: true },
});

// Sub-schema for mess operating hours.
const TimingsSchema = new mongoose.Schema({
    lunch: { start: String, end: String },
    dinner: { start: String, end: String },
});

const MessSchema = new mongoose.Schema({
  // --- Core Profile Information ---
  name: { type: String, required: true },
  owner: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  status: { type: String, enum: ['active', 'inactive'], default: 'active' },

  // --- Location & Contact ---
  address: { type: String, required: true },
  city: { type: String, required: true },
  managerContact: { type: String, required: true },
  location: {
    type: { type: String, enum: ['Point'], required: true },
    coordinates: { type: [Number], required: true }, // [longitude, latitude]
  },
  
  // --- Services, Pricing & Plans ---
  cuisine: { type: String, enum: ['Veg', 'Non-Veg', 'Both'], required: true },
  serviceType: { type: String, enum: ['Daily Only', 'Monthly Only', 'Both'], required: true },
  
  dailyThaliRate: { type: Number, required: function() { return this.serviceType !== 'Monthly Only'; } },
  specialThaliRate: { type: Number },
  mealPlans: [MealPlanSchema],
  securityDeposit: { type: Number, default: 0 },
  maxMembers: { type: Number, default: 100 },

  // --- Operational Rules & Policies ---
  timings: TimingsSchema,
  // The daily deadline (e.g., 10:00 PM) for formal leave applications for the NEXT day.
  leaveApplicationDeadlineTime: { type: String, default: '22:00' },
  // Min. consecutive days for a formal leave to be rebate-eligible.
  rebateMinDays: { type: Number, default: 4 },
  
  // The percentage rebate (0-100) for the "Not Eating" toggle.
  toggleSkipRebatePercentage: { type: Number, min: 0, max: 100, default: 0 },
  
  // Enforces your "Post-Paid Only" logic for monthly members.
  monthlyBillingType: { type: String, default: 'Post-Paid', enum: ['Post-Paid'] },
  
  // **CRITICAL REFINEMENT**: The single minimum charge for any month.
  // This simplifies billing and covers all edge cases like long leaves.
  minMonthlyCharge: { type: Number, default: 0 },
  
  // --- Reviews & Metadata ---
  averageRating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  galleryUrls: [String],

}, { timestamps: true });

MessSchema.index({ location: '2dsphere' });
const Mess = mongoose.model('Mess', MessSchema);
module.exports = Mess;