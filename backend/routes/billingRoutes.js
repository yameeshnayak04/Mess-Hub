// routes/billingRoutes.js
const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { protect, authorize } = require('../middleware/auth');
// Removed 'validate' and missing schemas
const { uploadPaymentProof } = require('../middleware/upload');

// Customer
// Removed validation: myBillsSchema is missing
router.get('/my-bills/:membershipId', protect, authorize('Customer'), billingController.getMyBills);

// Removed validation: submitProofSchema is missing
router.post('/submit-proof/:billId',
  protect,
  authorize('Customer'),
  uploadPaymentProof.single('proof'),
  billingController.submitPaymentProof
);

// Manager
// Removed validation: generateBillsSchema is missing
router.post('/generate-bills', protect, authorize('Manager'), billingController.generateMonthlyBills);

router.get('/pending-approvals', protect, authorize('Manager'), billingController.getPendingApprovals);

// Removed validation: billIdParamSchema is missing
router.put('/approve-payment/:billId', protect, authorize('Manager'), billingController.approvePayment);
router.put('/reject-payment/:billId', protect, authorize('Manager'), billingController.rejectPayment);
router.get('/payment/:billId', protect, authorize('Manager'), billingController.getPaymentDetails);

// NEW: Manager routes for bill history
router.get('/member/:membershipId', protect, authorize('Manager'), billingController.getMemberBills);
router.get('/all-bills', protect, authorize('Manager'), billingController.getAllMessBills);

module.exports = router;