// models/invoice.model.js
const mongoose = require('mongoose');

const InvoiceSchema = new mongoose.Schema(
  {
    membership: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Membership' },
    month: { type: Number, required: true }, // 1-12
    year: { type: Number, required: true },
    amount: { type: Number, required: true },
    status: { type: String, enum: ['due', 'pending_approval', 'paid', 'rejected'], default: 'due' },
    proofUrl: { type: String },
    rejectionReason: { type: String },
  },
  { timestamps: true }
);

// Ensure one invoice per membership per month
InvoiceSchema.index({ membership: 1, month: 1, year: 1 }, { unique: true });

module.exports = mongoose.model('Invoice', InvoiceSchema);
