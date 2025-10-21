// models/leave.model.js
const mongoose = require('mongoose');

const LeaveSchema = new mongoose.Schema(
  {
    membership: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Membership' },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    duration: { type: Number, required: true },
    isRebateEligible: { type: Boolean, default: false },
    rebateAmount: { type: Number, default: 0 }, // computed by controller
  },
  { timestamps: true }
);

LeaveSchema.pre('validate', function (next) {
  if (this.startDate.getMonth() !== this.endDate.getMonth() || this.startDate.getFullYear() !== this.endDate.getFullYear()) {
    return next(new Error('Leave applications cannot span across different months. Please create separate applications for each month.'));
  }
  // +1 to include both start and end days
  this.duration = Math.round((this.endDate.getTime() - this.startDate.getTime()) / (1000 * 60 * 60 * 24)) + 1;
  return next();
});

module.exports = mongoose.model('Leave', LeaveSchema);
