// new_backend/routes/planRoutes.js
//
// Plans belong to a mess, so these all live under /messes. This file is
// mounted on the same '/messes' path as messRoutes and is listed first in
// routes/index.js, so the plan-specific paths match before the generic
// '/:messId' route gets a chance to swallow them.
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { validateBody } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const planController = require('../controllers/planController');

const router = express.Router();

const managerOnly = [protect, authorize('Manager'), requireManagerMess];

router.get('/my-mess/plans', ...managerOnly, asyncHandler(planController.listMyPlans));
router.post(
  '/my-mess/plans',
  ...managerOnly,
  validateBody(schemas.planInput),
  asyncHandler(planController.addPlan)
);
router.patch(
  '/my-mess/plans/:planId',
  ...managerOnly,
  validateBody(schemas.planInput),
  asyncHandler(planController.updatePlan)
);
// Retires the plan rather than deleting it - memberships point at it.
router.delete(
  '/my-mess/plans/:planId',
  ...managerOnly,
  asyncHandler(planController.deactivatePlan)
);

// What a customer sees when browsing a mess.
router.get('/:messId/plans', protect, asyncHandler(planController.listPlans));

module.exports = router;
