// routes/kiosk.routes.js
const express = require('express');
const router = express.Router();

const {
  getActiveMembers,
  logMonthlyMeal,
  markAttendance,   // alias to monthly
  logDailyMeal
} = require('../controllers/kiosk.controller.js');

// Public kiosk endpoints (IP/Key restricted at infra level)
router.get('/messes/:messId/active-members', getActiveMembers);
router.post('/messes/:messId/log-monthly', logMonthlyMeal);
router.post('/messes/:messId/attendance', markAttendance);
router.post('/messes/:messId/log-daily', logDailyMeal);

module.exports = router;
