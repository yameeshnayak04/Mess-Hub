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
  perThaliRebateRate: { type: Number, required: true },
});

const TimingsSchema = new mongoose.Schema({
  lunch: { start: String, end: String },
  dinner: { start: String, end: String },
});

const MessSchema = new mongoose.Schema(
  {
    // Profile
    name: { type: String, required: true },
    owner: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },

    // Location & contact
    address: { type: String, required: true },
    city: { type: String, required: true },
    managerContact: { type: String, required: true },
    location: {
      type: { type: String, enum: ['Point'], required: true },
      coordinates: { type: [Number], required: true }, // [lng, lat]
    },

    // Services & pricing
    cuisine: { type: String, enum: ['Veg', 'Non-Veg', 'Both'], required: true },
    serviceType: { type: String, enum: ['Daily Only', 'Monthly Only', 'Both'], required: true },
    dailyThaliRate: { type: Number, required: function () { return this.serviceType !== 'Monthly Only'; } },
    specialThaliRate: { type: Number },
    mealPlans: [MealPlanSchema],
    securityDeposit: { type: Number, default: 0 },
    maxMembers: { type: Number, default: 100 },

    // Policies
    timings: TimingsSchema,
    leaveApplicationDeadlineTime: { type: String, default: '22:00' }, // deadline to apply for tomorrow
    rebateMinDays: { type: Number, default: 4 },
    toggleSkipRebatePercentage: { type: Number, min: 0, max: 100, default: 0 },
    monthlyBillingType: { type: String, default: 'Post-Paid', enum: ['Post-Paid'] },
    minMonthlyCharge: { type: Number, default: 0 },

    // Ratings
    averageRating: { type: Number, default: 0 },
    reviewCount: { type: Number, default: 0 },
    galleryUrls: [String],
  },
  { timestamps: true }
);

MessSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Mess', MessSchema);
