// new_backend/routes/leaveRoutes.js
//
// Holiday leave ("I'm away next week"). Not to be confused with leaving the
// mess for good, which lives in membershipRoutes.
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { loadMembership } = require('../middleware/loadMembership');
const { validateBody, validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const leaveController = require('../controllers/leaveController');

const router = express.Router();

// --- manager ---
// Declared before '/:membershipId' so "mess" is not read as an id.
router.get(
  '/mess',
  protect,
  authorize('Manager'),
  requireManagerMess,
  validateQuery(schemas.pageQuery),
  asyncHandler(leaveController.listMessLeaves)
);
router.get(
  '/mess/today',
  protect,
  authorize('Manager'),
  requireManagerMess,
  asyncHandler(leaveController.listMembersOnLeaveToday)
);

// --- customer ---
router.post(
  '/:membershipId',
  protect,
  authorize('Customer'),
  loadMembership,
  validateBody(schemas.applyLeave),
  asyncHandler(leaveController.applyForLeave)
);

// Readable by the member themselves or by their mess manager.
router.get(
  '/:membershipId',
  protect,
  loadMembership,
  validateQuery(schemas.pageQuery),
  asyncHandler(leaveController.listLeavesForMembership)
);

module.exports = router;
