const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: function () {
        return this.memberType === 'Monthly';
      },
    },
    mess: { type: mongoose.Schema.Types.ObjectId, ref: 'Mess', required: true },
    date: { type: Date, required: true },
    mealType: { type: String, enum: ['Lunch', 'Dinner'], required: true },
    status: { type: String, enum: ['Present', 'Skipped', 'Leave', 'Absent'], required: true },

    memberType: { type: String, enum: ['Monthly', 'Daily'], default: 'Monthly' },

    // Pricing/plan snapshotting
    membership: { type: mongoose.Schema.Types.ObjectId, ref: 'Membership' }, // optional
    planNameSnapshot: { type: String }, // e.g., "Lunch Only"
    rateSnapshot: { type: Number, min: 0 }, // amount used for rebate or billing for this meal
    // Optional: capture rebate rule at time of attendance if needed
    rebatePerThaliSnapshot: { type: Number, min: 0 },
  },
  { timestamps: true }
);

// Compound indexes for efficient queries
attendanceSchema.index({ user: 1, mess: 1, date: 1, mealType: 1 });
attendanceSchema.index({ mess: 1, date: 1, mealType: 1, status: 1 });
attendanceSchema.index({ mess: 1, date: 1, memberType: 1, status: 1 });
// Optional: accelerate membership-based lookups
attendanceSchema.index({ membership: 1, date: 1, mealType: 1 });

module.exports = mongoose.model('Attendance', attendanceSchema);
