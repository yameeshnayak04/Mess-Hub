// new_backend/routes/attendanceRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { loadMembership } = require('../middleware/loadMembership');
const { validateBody, validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const { kioskLimiter } = require('../middleware/rateLimiters');
const attendanceController = require('../controllers/attendanceController');

const router = express.Router();

// --- kiosk (manager's shared device at the mess) ---
// Declared before '/:membershipId/...' so "kiosk" is not read as an id.
// Rate limited because the PIN is only four digits.
router.post(
  '/kiosk/mark',
  protect,
  authorize('Manager'),
  requireManagerMess,
  kioskLimiter,
  validateBody(schemas.kioskMark),
  asyncHandler(attendanceController.markAtKiosk)
);
// Same PIN-verified kiosk path, but the deliberate override for a member who
// is mid-leave and has shown up anyway.
router.post(
  '/kiosk/override-leave',
  protect,
  authorize('Manager'),
  requireManagerMess,
  kioskLimiter,
  validateBody(schemas.kioskMark),
  asyncHandler(attendanceController.overrideLeaveAtKiosk)
);
router.post(
  '/kiosk/walkin',
  protect,
  authorize('Manager'),
  requireManagerMess,
  validateBody(schemas.walkinSale),
  asyncHandler(attendanceController.recordWalkinSale)
);

// --- customer ---
router.post(
  '/:membershipId/skip',
  protect,
  authorize('Customer'),
  loadMembership,
  validateBody(schemas.skipMeal),
  asyncHandler(attendanceController.skipMeal)
);

// Readable by the member themselves or by their mess manager.
router.get(
  '/:membershipId/calendar',
  protect,
  loadMembership,
  validateQuery(schemas.calendarQuery),
  asyncHandler(attendanceController.getCalendar)
);

module.exports = router;
