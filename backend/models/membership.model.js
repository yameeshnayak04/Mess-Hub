// This file defines the link between a User and a Mess (their membership).

const mongoose = require('mongoose');

const MembershipSchema = new mongoose.Schema({
  // Reference to the User who holds this membership.
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    required: true, 
    ref: 'User',
  },
  // Reference to the Mess this membership is for.
  mess: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Mess',
  },
  // Stores the specific meal plan the customer chose from the mess's offerings.
  // This is an embedded object to keep the plan details at the time of joining.
  mealPlan: {
    name: { type: String, required: true },
    price: { type: Number, required: true },
  },
  // The status of the membership.
  status: {
    type: String,
    enum: ['active', 'inactive', 'cancelled'],
    default: 'active',
  },
}, { timestamps: true });

// Create the Membership model from the schema.
const Membership = mongoose.model('Membership', MembershipSchema);

// Export the model.
module.exports = Membership;