const mongoose = require('mongoose');

const membershipSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  mess: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Mess',
    required: true
  },
  planName: {
    type: String,
    required: true
  },
  billingRate: {
    type: Number,
    required: true,
    min: 0
  },
  status: {
    type: String,
    enum: ['Pending', 'Active', 'Inactive'],
    default: 'Pending'
  },
  joinedDate: {
    type: Date
  }
}, {
  timestamps: true
});

// Compound index for efficient queries
membershipSchema.index({ user: 1, mess: 1 });
membershipSchema.index({ mess: 1, status: 1 });

module.exports = mongoose.model('Membership', membershipSchema);
