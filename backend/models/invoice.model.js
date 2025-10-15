const mongoose = require('mongoose');

const InvoiceSchema = new mongoose.Schema({
  membership: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Membership' },
  month: { type: Number, required: true }, // e.g., 10 for October
  year: { type: Number, required: true }, // e.g., 2025
  amount: { type: Number, required: true },
  status: {
    type: String,
    enum: ['due', 'pending_approval', 'paid', 'rejected'],
    default: 'due',
  },
  // URL to the payment proof screenshot uploaded by the user.
  proofUrl: { type: String },
  // Optional reason provided by the manager for rejecting a payment.
  rejectionReason: { type: String },
}, { timestamps: true });

const Invoice = mongoose.model('Invoice', InvoiceSchema);
module.exports = Invoice;