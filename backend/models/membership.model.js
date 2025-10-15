const mongoose = require('mongoose');

const MembershipSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
  // We embed the meal plan details to "freeze" them at the time of joining.
  // This prevents issues if the manager later changes the main plan.
  mealPlan: {
    name: { type: String, required: true },
    price: { type: Number, required: true },
    perDayRebateRate: { type: Number, required: true },
  },
  status: {
    type: String,
    enum: ['active', 'cancelled'],
    default: 'active',
  },
}, { timestamps: true });

const Membership = mongoose.model('Membership', MembershipSchema);
module.exports = Membership;