// routes/attendanceRoutes.js
const express = require('express');
const router = express.Router();

const attendanceController = require('../controllers/attendanceController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { skipMealSchema, kioskMarkSchema, kioskMarkDailySchema } = require('../middleware/schemas');

// Customer
router.get('/my-calendar/:membershipId', protect, authorize('Customer'), attendanceController.getMyAttendance);
router.post('/skip', protect, authorize('Customer'), validate(skipMealSchema), attendanceController.skipMeal);

// Manager kiosk
router.post('/kiosk/mark', protect, authorize('Manager'), validate(kioskMarkSchema), attendanceController.kioskMarkAttendance);
router.post('/kiosk/daily', protect, authorize('Manager'), validate(kioskMarkDailySchema), attendanceController.kioskMarkDaily);

// Manager route for single member attendance
router.get('/member/:membershipId', protect, authorize('Manager'), attendanceController.getMemberAttendance);

// Any routes that were on or after line 22 in your local file are removed 
// if they pointed to non-existent controller functions.
router.get('/dashboard/meal-stats', protect, authorize('Manager'), attendanceController.getMealDashboardStats);

module.exports = router;
