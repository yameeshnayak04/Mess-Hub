// routes/attendanceRoutes.js
const express = require('express');
const router = express.Router();

const attendanceController = require('../controllers/attendanceController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { skipMealSchema, kioskMarkSchema, kioskDailySchema } = require('../middleware/schemas'); // Removed missing schema

// Customer
// Removed validation: myAttendanceSchema is missing
router.get('/my-calendar/:membershipId', protect, authorize('Customer'), attendanceController.getMyAttendance);
router.post('/skip', protect, authorize('Customer'), validate(skipMealSchema), attendanceController.skipMeal);

// Manager kiosk
router.post('/kiosk/mark', protect, authorize('Manager'), validate(kioskMarkSchema), attendanceController.kioskMarkAttendance);
router.post('/kiosk/daily', protect, authorize('Manager'), validate(kioskDailySchema), attendanceController.kioskMarkDaily);

// NEW: Manager route for single member attendance
router.get('/member/:membershipId', protect, authorize('Manager'), attendanceController.getMemberAttendance);
router.get('/member-calendar/:membershipId', protect, authorize('Manager'), attendanceController.getMemberAttendanceForManager);


module.exports = router;