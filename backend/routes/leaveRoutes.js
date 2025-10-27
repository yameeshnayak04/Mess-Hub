const express = require('express');
const router = express.Router();
const leaveController = require('../controllers/leaveController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { applyLeaveSchema, getMyLeavesSchema } = require('../middleware/schemas');

router.post('/apply/:membershipId', protect, authorize('Customer'), validate(applyLeaveSchema), leaveController.applyForLeave);
router.get('/my/:membershipId', protect, authorize('Customer'), validate(getMyLeavesSchema), leaveController.getMyLeaves);

module.exports = router;
