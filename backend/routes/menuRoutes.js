// new_backend/routes/menuRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect, authorize } = require('../middleware/auth');
const { requireManagerMess } = require('../middleware/loadMess');
const { validateBody, validateQuery } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const menuController = require('../controllers/menuController');

const router = express.Router();

// Posting the same date again simply replaces that day's menu.
router.put(
  '/my-mess',
  protect,
  authorize('Manager'),
  requireManagerMess,
  validateBody(schemas.setMenu),
  asyncHandler(menuController.setMenu)
);

// No ?from/?to means "today", which is what both dashboards ask for.
router.get(
  '/:messId',
  protect,
  validateQuery(schemas.menuQuery),
  asyncHandler(menuController.getMenus)
);

module.exports = router;
