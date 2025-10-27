// routes/leaveRoutes.js
const express = require('express');
const router = express.Router();
const leaveController = require('../controllers/leaveController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { leaveSchema } = require('../middleware/schemas');

// Customer
router.post('/apply/:membershipId', protect, authorize('Customer'), validate(leaveSchema), leaveController.applyForLeave);
router.get('/my/:membershipId', protect, authorize('Customer'), leaveController.getMyLeaves);

// Manager routes
router.get('/mess-leaves', protect, authorize('Manager'), leaveController.getMessLeaves);
router.get('/member/:membershipId', protect, authorize('Manager'), leaveController.getMemberLeaves);

module.exports = router;