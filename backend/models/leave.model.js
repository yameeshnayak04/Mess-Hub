// This file defines the structure for formal leave applications with new validation.

const mongoose = require('mongoose');

const LeaveSchema = new mongoose.Schema({
  membership: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Membership' },
  // Both start and end dates must be within the same month.
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  // The number of days in the leave period.
  duration: { type: Number, required: true },
  // Flag set by the backend based on 'duration' and 'rebateMinDays'.
  isRebateEligible: { type: Boolean, default: false },
  // The total rebate amount calculated for this leave.
  rebateAmount: { type: Number, default: 0 },
}, { timestamps: true });

// A pre-save hook to validate that the leave is within a single month and to calculate duration.
LeaveSchema.pre('validate', function(next) {
    // This business rule is now enforced by the database model itself.
    if (this.startDate.getMonth() !== this.endDate.getMonth()) {
        next(new Error('Leave applications cannot span across different months. Please create separate applications for each month.'));
    } else {
        // Calculate the duration in days. +1 to include both start and end days.
        this.duration = (this.endDate.getTime() - this.startDate.getTime()) / (1000 * 60 * 60 * 24) + 1;
        next();
    }
});

const Leave = mongoose.model('Leave', LeaveSchema);
module.exports = Leave;