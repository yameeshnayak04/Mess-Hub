const mongoose = require('mongoose');

const leaveSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    mess: { type: mongoose.Schema.Types.ObjectId, ref: 'Mess', required: true },

    // Date range of leave; eligibility for rebate is computed at billing time
    startDate: { type: Date, required: true },
    endDate: {
      type: Date,
      required: true,
      validate: {
        validator: function (v) {
          return this.startDate && v && this.startDate <= v;
        },
        message: 'endDate must be on or after startDate',
      },
    },

    // Optional metadata
    reason: { type: String, trim: true },
  },
  { timestamps: true }
);

// Indexes for efficient lookups by user/mess and date windows
leaveSchema.index({ user: 1, mess: 1, startDate: 1, endDate: 1 });

module.exports = mongoose.model('Leave', leaveSchema);
