// routes/billingRoutes.js
const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { protect, authorize } = require('../middleware/auth');
const { uploadPaymentProof } = require('../middleware/upload');

// Customer
router.get('/my-bills/:membershipId', protect, authorize('Customer'), billingController.getMyBills);

router.post('/submit-proof/:billId',
  protect,
  authorize('Customer'),
  uploadPaymentProof,
  billingController.submitPaymentProof
);

// Manager
// POST /api/billing/generate-bills is REMOVED and replaced by automated job

router.get('/pending-approvals', protect, authorize('Manager'), billingController.getPendingApprovals);
router.get('/due-bills', protect, authorize('Manager'), billingController.getDueBills);

router.put('/approve-payment/:billId', protect, authorize('Manager'), billingController.approvePayment);
router.put('/reject-payment/:billId', protect, authorize('Manager'), billingController.rejectPayment);
router.get('/payment/:billId', protect, authorize('Manager'), billingController.getPaymentDetails);

router.get('/member/:membershipId', protect, authorize('Manager'), billingController.getMemberBills);
router.get('/all-bills', protect, authorize('Manager'), billingController.getAllMessBills);

module.exports = router;
