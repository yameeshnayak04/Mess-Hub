// routes/attendanceRoutes.js
const express = require('express');
const router = express.Router();

const attendanceController = require('../controllers/attendanceController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { skipMealSchema, myAttendanceSchema, kioskMarkSchema, kioskDailySchema } = require('../middleware/schemas');

// Customer
router.get('/my-calendar/:membershipId', protect, authorize('Customer'), validate(myAttendanceSchema), attendanceController.getMyAttendance);
router.post('/skip', protect, authorize('Customer'), validate(skipMealSchema), attendanceController.skipMeal);

// Manager kiosk
router.post('/kiosk/mark', protect, authorize('Manager'), validate(kioskMarkSchema), attendanceController.kioskMarkAttendance);
router.post('/kiosk/daily', protect, authorize('Manager'), validate(kioskDailySchema), attendanceController.kioskMarkDaily);

module.exports = router;
