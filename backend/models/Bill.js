const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
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
  month: {
    type: Number,
    required: true,
    min: 1,
    max: 12
  },
  year: {
    type: Number,
    required: true
  },
  baseAmount: {
    type: Number,
    required: true,
    min: 0
  },
  rebateAmount: {
    type: Number,
    default: 0,
    min: 0
  },
  totalAmount: {
    type: Number,
    required: true,
    min: 0
  },
  status: {
    type: String,
    enum: ['Due', 'Pending Approval', 'Paid'],
    default: 'Due'
  },
  paymentProofUrl: {
    type: String
  }
}, {
  timestamps: true
});

// Compound indexes for efficient queries
billSchema.index({ user: 1, mess: 1, month: 1, year: 1 }, { unique: true });
billSchema.index({ mess: 1, status: 1 });
billSchema.index({ mess: 1, status: 1, year: -1, month: -1, updatedAt: -1 });
billSchema.index({ user: 1, mess: 1, year: -1, month: -1, createdAt: -1 });

module.exports = mongoose.model('Bill', billSchema);
