// models/Attendance.js
const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: function () { return this.memberType === 'Monthly'; },
    },
    membership: { type: mongoose.Schema.Types.ObjectId, ref: 'Membership', required: function () { return this.memberType === 'Monthly'; } },
    mess: { type: mongoose.Schema.Types.ObjectId, ref: 'Mess', required: true },
    date: { type: Date, required: true }, // must be normalized to 00:00:00.000
    mealType: { type: String, enum: ['Lunch', 'Dinner'], required: true },
    status: { type: String, enum: ['Present', 'Skipped', 'Leave', 'Absent'], required: true },
    memberType: { type: String, enum: ['Monthly', 'Daily'], default: 'Monthly' },

    // Snapshots
    planNameSnapshot: { type: String },
    rateSnapshot: { type: Number, min: 0 },
    rebatePerThaliSnapshot: { type: Number, min: 0 },
  },
  { timestamps: true }
);

// Enforce one row per membership x date x meal for monthly
attendanceSchema.index(
  { membership: 1, date: 1, mealType: 1 },
  { unique: true, partialFilterExpression: { memberType: 'Monthly' } }
);

// Useful lookups
attendanceSchema.index({ mess: 1, date: 1, mealType: 1, status: 1 });
attendanceSchema.index({ user: 1, mess: 1, date: 1, mealType: 1 });

module.exports = mongoose.model('Attendance', attendanceSchema);
