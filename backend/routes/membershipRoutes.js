// new_backend/routes/membershipRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { loadMembership } = require('../middleware/loadMembership');
const { validateBody, validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const membershipController = require('../controllers/membershipController');

const router = express.Router();

// --- customer ---
router.post(
  '/join/:messId',
  protect,
  authorize('Customer'),
  validateBody(schemas.joinMess),
  asyncHandler(membershipController.joinMess)
);
router.get(
  '/mine',
  protect,
  authorize('Customer'),
  asyncHandler(membershipController.listMyMemberships)
);

// --- manager ---
// Declared before '/:membershipId' so "mess" is not read as an id.
router.get(
  '/mess',
  protect,
  authorize('Manager'),
  requireManagerMess,
  validateQuery(schemas.membersQuery),
  asyncHandler(membershipController.listMessMembers)
);

// --- either role, depending on who owns what ---
// loadMembership lets a customer through for their own membership and a
// manager through for anyone in their mess, so one route serves both.
router.get(
  '/:membershipId',
  protect,
  loadMembership,
  asyncHandler(membershipController.getMembershipDetails)
);

router.post(
  '/:membershipId/approve',
  protect,
  authorize('Manager'),
  loadMembership,
  asyncHandler(membershipController.approveMembership)
);
router.post(
  '/:membershipId/reject',
  protect,
  authorize('Manager'),
  loadMembership,
  asyncHandler(membershipController.rejectMembership)
);

// Leaving the mess for good. The customer asks; the manager decides.
router.post(
  '/:membershipId/discontinue',
  protect,
  authorize('Customer'),
  loadMembership,
  asyncHandler(membershipController.requestDiscontinuation)
);
router.post(
  '/:membershipId/discontinue/approve',
  protect,
  authorize('Manager'),
  loadMembership,
  asyncHandler(membershipController.approveDiscontinuation)
);
router.post(
  '/:membershipId/discontinue/reject',
  protect,
  authorize('Manager'),
  loadMembership,
  asyncHandler(membershipController.rejectDiscontinuation)
);

module.exports = router;
