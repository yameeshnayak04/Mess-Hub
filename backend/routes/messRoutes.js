// new_backend/routes/messRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { validateBody, validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const { uploadMessImage } = require('../middleware/upload');
const messController = require('../controllers/messController');

const router = express.Router();

const managerOnly = [protect, authorize('Manager'), requireManagerMess];

// --- manager: set up and run their own mess ---
router.post(
  '/',
  protect,
  authorize('Manager'),
  ...uploadMessImage,
  validateBody(schemas.createMess),
  asyncHandler(messController.createMess)
);
router.get('/my-mess', protect, authorize('Manager'), asyncHandler(messController.getMyMess));
router.patch(
  '/my-mess',
  ...managerOnly,
  ...uploadMessImage,
  validateBody(schemas.updateMess),
  asyncHandler(messController.updateMyMess)
);

// Live "who is eating right now" figures, plus the drill-down behind each one.
router.get(
  '/my-mess/dashboard',
  ...managerOnly,
  validateQuery(schemas.mealStatsQuery),
  asyncHandler(messController.getDashboard)
);
router.get(
  '/my-mess/dashboard/members',
  ...managerOnly,
  validateQuery(schemas.memberStatusQuery),
  asyncHandler(messController.getDashboardMembers)
);

// --- customer: find and view messes ---
// '/discover' must be declared before '/:messId', otherwise Express would
// treat the word "discover" as a mess id.
router.get(
  '/discover',
  protect,
  authorize('Customer'),
  validateQuery(schemas.discoverQuery),
  asyncHandler(messController.discoverMesses)
);
router.get('/:messId', protect, asyncHandler(messController.getMessById));

module.exports = router;
