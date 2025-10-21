// models/membership.model.js
const mongoose = require('mongoose');

const MembershipSchema = new mongoose.Schema(
  {
    customer: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
    mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },

    // Freeze plan details at join time (normalized to a single perThaliRebateRate)
    mealPlan: {
      name: { type: String, enum: ['Lunch', 'Dinner', 'Full Day'], required: true },
      price: { type: Number, required: true },
      perThaliRebateRate: { type: Number, required: true },
    },

    status: { type: String, enum: ['active', 'cancelled'], default: 'active' },
    startedAt: { type: Date, default: Date.now },
    endedAt: { type: Date },
  },
  { timestamps: true }
);

// Query optimization for memberships
MembershipSchema.index({ customer: 1, mess: 1, status: 1 });

module.exports = mongoose.model('Membership', MembershipSchema);
