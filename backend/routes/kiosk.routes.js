// routes/kiosk.routes.js
const express = require('express');
const router = express.Router();

const { getActiveMembers, logMonthlyMeal, logDailyMeal, managerOverride } = require('../controllers/kiosk.controller.js');
const { protect, isManager } = require('../middlewares/auth.middleware.js');

// Public kiosk routes (IP-restricted in production)
router.get('/messes/:messId/active-members', getActiveMembers);
router.post('/messes/:messId/log-monthly', logMonthlyMeal);
router.post('/messes/:messId/log-daily', logDailyMeal);

// Protected manager override route (requires JWT auth + manager role)
router.post('/messes/:messId/manager-override', protect, isManager, managerOverride);

module.exports = router;
