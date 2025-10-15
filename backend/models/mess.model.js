// This file defines the final, bulletproof data structure for a Mess Profile.

const mongoose = require('mongoose');

// ... (PriceHistorySchema, MealPlanSchema, TimingsSchema, CutoffTimeSchema remain the same) ...
const PriceHistorySchema = new mongoose.Schema({ price: { type: Number, required: true }, effectiveDate: { type: Date, default: Date.now }, });
const MealPlanSchema = new mongoose.Schema({ name: { type: String, enum: ['Lunch', 'Dinner', 'Full Day'], required: true, }, priceHistory: [PriceHistorySchema], perDayRebateRate: { type: Number, required: true }, });
const TimingsSchema = new mongoose.Schema({ lunch: { start: { type: String, default: '12:00' }, end: { type: String, default: '14:00' }, }, dinner: { start: { type: String, default: '20:00' }, end: { type: String, default: '22:00' }, } });
const CutoffTimeSchema = new mongoose.Schema({ lunch: { type: String, default: '11:30' }, dinner: { type: String, default: '19:30' }, });


const MessSchema = new mongoose.Schema({
  // --- Core Profile & Status ---
  name: { type: String, required: true },
  owner: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  // **NEW**: A status field to allow managers to temporarily deactivate their listing.
  status: { type: String, enum: ['active', 'inactive', 'under_review'], default: 'active' },

  // --- Location & Contact ---
  address: { type: String, required: true },
  managerContact: { type: String, required: true },
  location: {
    type: { type: String, enum: ['Point'], required: true },
    coordinates: { type: [Number], required: true },
  },
  
  // --- Services, Pricing & Plans ---
  serviceType: { type: String, enum: ['Daily Only', 'Monthly Only', 'Both'], required: true },
  dailyThaliRate: { type: Number, required: function() { return this.serviceType !== 'Monthly Only'; } },
  mealPlans: [MealPlanSchema],

  // --- Operational Rules & Policies ---
  timings: TimingsSchema,
  leaveApplicationDeadlineTime: { type: String, default: '22:00' },
  leaveCutoffDay: { type: Number, default: 26 },
  notEatingCutoff: CutoffTimeSchema,
  rebateMinDays: { type: Number, default: 3 },
  notEatingRebatePolicy: { type: String, enum: ['Full', 'Partial', 'None'], default: 'None' },
  
  // **NEW (CRITICAL FIX)**: Field to store the value of the partial rebate.
  partialRebatePercentage: { 
    type: Number, 
    default: 50, // Defaults to 50%
    min: 0, 
    max: 100,
    // Only required if the policy is 'Partial'.
    required: function() { return this.notEatingRebatePolicy === 'Partial'; }
  },

  firstMonthPolicy: { type: String, enum: ['Pro-Rata', 'Pay-Per-Day'], default: 'Pro-Rata' },
  minimumFirstMonthCharge: { type: Number },
  maxMembers: { type: Number, default: 100 },

  // --- Reviews & Metadata ---
  averageRating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  galleryUrls: [String],

}, { timestamps: true });

MessSchema.index({ location: '2dsphere' });
const Mess = mongoose.model('Mess', MessSchema);
module.exports = Mess;