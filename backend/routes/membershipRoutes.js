// routes/membershipRoutes.js

const express = require('express');
const router = express.Router();

const membershipController = require('../controllers/membershipController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { joinMessSchema } = require('../middleware/schemas');

// Customer
router.post(
  '/join/:messId',
  protect,
  authorize('Customer'),
  validate(joinMessSchema),
  membershipController.joinMess
);

// NEW: customer requests permanent discontinuation
router.put(
  '/request-discontinue/:membershipId',
  protect,
  authorize('Customer'),
  membershipController.requestDiscontinueMembership
);

router.get(
  '/my-memberships',
  protect,
  authorize('Customer'),
  membershipController.getMyMemberships
);

router.get(
  '/details/:membershipId',
  protect,
  authorize('Customer'),
  membershipController.getMembershipDetails
);

// Manager
router.get(
  '/mess',
  protect,
  authorize('Manager'),
  membershipController.getMessMembers
);

router.put(
  '/approve/:membershipId',
  protect,
  authorize('Manager'),
  membershipController.approveMembership
);

router.put(
  '/reject/:membershipId',
  protect,
  authorize('Manager'),
  membershipController.rejectMembership
);

// NEW: manager approves/rejects discontinuation
router.put(
  '/approve-discontinue/:membershipId',
  protect,
  authorize('Manager'),
  membershipController.approveDiscontinueMembership
);

router.put(
  '/reject-discontinue/:membershipId',
  protect,
  authorize('Manager'),
  membershipController.rejectDiscontinueMembership
);

// Backward-compatible alias: verify-leave → approve-discontinue
router.put(
  '/verify-leave/:membershipId',
  protect,
  authorize('Manager'),
  membershipController.verifyLeaveMembership
);

// Existing manager route for single member details
router.get(
  '/member/:membershipId',
  protect,
  authorize('Manager'),
  membershipController.getMemberDetails
);

module.exports = router;
