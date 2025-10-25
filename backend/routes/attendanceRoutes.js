const express = require('express');
const {
  skipMeal,
  kioskMarkAttendance,
  kioskMarkDaily,
  getMyAttendance
} = require('../controllers/attendanceController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { skipMealSchema, kioskMarkSchema, kioskMarkDailySchema } = require('../middleware/schemas');

const router = express.Router();

router.post('/skip', protect, authorize('Customer'), validate(skipMealSchema), skipMeal);

router.post('/kiosk/mark', protect, authorize('Manager'), validate(kioskMarkSchema), kioskMarkAttendance);

router.post('/kiosk/daily', protect, authorize('Manager'), validate(kioskMarkDailySchema), kioskMarkDaily);

router.get('/my-calendar/:membershipId', protect, authorize('Customer'), getMyAttendance);

module.exports = router;
