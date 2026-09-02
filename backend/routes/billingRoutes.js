// new_backend/routes/billingRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { loadMembership } = require('../middleware/loadMembership');
const { validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const { uploadPaymentProof } = require('../middleware/upload');
const billingController = require('../controllers/billingController');

const router = express.Router();

const managerOnly = [protect, authorize('Manager'), requireManagerMess];

// --- manager: every bill in the mess ---
// Declared before '/:billId/...' so "mess" is not read as a bill id.
router.get(
  '/mess',
  ...managerOnly,
  validateQuery(schemas.billsQuery),
  asyncHandler(billingController.listMessBills)
);

// --- customer: my own bills ---
router.get(
  '/membership/:membershipId',
  protect,
  loadMembership,
  validateQuery(schemas.pageQuery),
  asyncHandler(billingController.listMyBills)
);
router.post(
  '/:billId/proof',
  protect,
  authorize('Customer'),
  ...uploadPaymentProof,
  asyncHandler(billingController.submitPaymentProof)
);

// --- manager: approve or reject a submitted payment ---
router.post('/:billId/approve', ...managerOnly, asyncHandler(billingController.approvePayment));
router.post('/:billId/reject', ...managerOnly, asyncHandler(billingController.rejectPayment));

// Returns a short-lived signed link; the proof image itself is private.
router.get('/:billId/proof', ...managerOnly, asyncHandler(billingController.getPaymentProof));
router.get('/:billId/history', ...managerOnly, asyncHandler(billingController.getBillHistory));

module.exports = router;
