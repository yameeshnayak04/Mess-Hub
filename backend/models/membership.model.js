// This file defines the link between a User and a Mess (their membership).

const mongoose = require('mongoose');

const MembershipSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
  // We embed the meal plan details to "freeze" them at the time of joining.
  mealPlan: {
    name: { type: String, required: true },
    price: { type: Number, required: true },
    // **CORRECTED**: Store the granular rebate rates at the time of joining.
    lunchRebateRate: { type: Number, required: true },
    dinnerRebateRate: { type: Number, required: true },
  },
  // **CORRECTED**: Using a clearer status enum.
  status: {
    type: String,
    enum: ['active', 'cancelled'],
    default: 'active',
  },
  startedAt: { type: Date, default: Date.now },
  endedAt: { type: Date }, // Will be set when membership is cancelled.
}, { timestamps: true });

// A compound index for efficient querying of a user's memberships.
MembershipSchema.index({ customer: 1, mess: 1 });

const Membership = mongoose.model('Membership', MembershipSchema);
module.exports = Membership;