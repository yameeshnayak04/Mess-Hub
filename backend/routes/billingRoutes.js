const express = require('express');
const {
  generateMonthlyBills,
  submitPaymentProof,
  getPendingApprovals,
  approvePayment,
  rejectPayment,
  getMyBills
} = require('../controllers/billingController');
const { protect, authorize } = require('../middleware/auth');
const { uploadPaymentProof } = require('../middleware/upload');

const router = express.Router();

router.post('/generate-bills', protect, authorize('Manager'), generateMonthlyBills);

router.post(
  '/submit-proof/:billId',
  protect,
  authorize('Customer'),
  uploadPaymentProof.single('paymentProof'),
  submitPaymentProof
);

router.get('/pending-approvals', protect, authorize('Manager'), getPendingApprovals);

router.put('/approve-payment/:billId', protect, authorize('Manager'), approvePayment);

router.put('/reject-payment/:billId', protect, authorize('Manager'), rejectPayment);

router.get('/my-bills/:membershipId', protect, authorize('Customer'), getMyBills);

module.exports = router;
