// This file defines the data structure for leave records.

const mongoose = require('mongoose');

const LeaveSchema = new mongoose.Schema({
  // A reference to the specific membership this leave belongs to.
  // This links the leave to a user and a mess.
  membership: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Membership',
  },
  // The start date of the leave period.
  startDate: {
    type: Date,
    required: true,
  },
  // The end date of the leave period. For a single day leave, this will be the same as startDate.
  endDate: {
    type: Date,
    required: true,
  },
  // A flag to mark if this leave qualifies for a billing rebate, based on the mess's rules.
  // This will be calculated by the backend logic.
  isRebateEligible: {
    type: Boolean,
    default: false,
  },
}, { timestamps: true });

// Create the Leave model from the schema.
const Leave = mongoose.model('Leave', LeaveSchema);

// Export the model.
module.exports = Leave;