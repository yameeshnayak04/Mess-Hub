const express = require('express');
const {
  applyForLeave,
  getLeaveRequests,
  approveLeave,
  rejectLeave
} = require('../controllers/leaveController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { leaveSchema } = require('../middleware/schemas');

const router = express.Router();

router.post('/apply/:membershipId', protect, authorize('Customer'), validate(leaveSchema), applyForLeave);

router.get('/requests/my-mess', protect, authorize('Manager'), getLeaveRequests);

router.put('/approve/:leaveId', protect, authorize('Manager'), approveLeave);

router.put('/reject/:leaveId', protect, authorize('Manager'), rejectLeave);

module.exports = router;
