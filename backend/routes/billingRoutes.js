// routes/billingRoutes.js
const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { generateBillsSchema, myBillsSchema, submitProofSchema, billIdParamSchema } = require('../middleware/schemas');
const { uploadPaymentProof } = require('../middleware/upload'); // <-- match export

// Customer
router.get('/my-bills/:membershipId', protect, authorize('Customer'), validate(myBillsSchema), billingController.getMyBills);
router.post('/submit-proof/:billId',
  protect,
  authorize('Customer'),
  uploadPaymentProof.single('proof'),           // <-- use uploadPaymentProof
  validate(submitProofSchema),
  billingController.submitPaymentProof
);

// Manager
router.post('/generate-bills', protect, authorize('Manager'), validate(generateBillsSchema), billingController.generateMonthlyBills);
router.get('/pending-approvals', protect, authorize('Manager'), billingController.getPendingApprovals);
router.put('/approve-payment/:billId', protect, authorize('Manager'), validate(billIdParamSchema), billingController.approvePayment);
router.put('/reject-payment/:billId', protect, authorize('Manager'), validate(billIdParamSchema), billingController.rejectPayment);
router.get('/payment/:billId', protect, authorize('Manager'), validate(billIdParamSchema), billingController.getPaymentDetails);

module.exports = router;
