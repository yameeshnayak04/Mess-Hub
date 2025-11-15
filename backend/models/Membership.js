// models/Membership.js
const mongoose = require('mongoose');

const membershipSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    mess: { type: mongoose.Schema.Types.ObjectId, ref: 'Mess', required: true },

    // Snapshot and linkage to Mess.plans subdocument
    planId: { type: mongoose.Schema.Types.ObjectId }, // references Mess.plans[_id]

    planName: { type: String, required: true },

    billingRate: { type: Number, required: true, min: 0 },

    // Lifecycle
    status: {
      type: String,
      enum: ['Pending', 'Active', 'Inactive'],
      default: 'Pending',
    },

    joinedDate: { type: Date },

    // Pricing cycle anchor (e.g., 1st of month at 00:00)
    effectiveFrom: { type: Date },

    // Customer has requested permanent discontinuation; needs manager action
    leaveRequested: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// Optional helper: when activating without effectiveFrom, default to 1st of current month
membershipSchema.pre('save', function (next) {
  if (this.isModified('status') && this.status === 'Active' && !this.effectiveFrom) {
    const now = new Date();
    this.effectiveFrom = new Date(
      now.getFullYear(),
      now.getMonth(),
      1,
      0,
      0,
      0,
      0
    );
    if (!this.joinedDate) this.joinedDate = now;
  }

  next();
});

// Indexes
membershipSchema.index({ user: 1, mess: 1 });
membershipSchema.index({ mess: 1, status: 1 });

module.exports = mongoose.model('Membership', membershipSchema);
