const express = require('express');
const {
  joinMess,
  getMessMembers,
  approveMembership,
  rejectMembership,
  getMyMemberships,
  leaveMess
} = require('../controllers/membershipController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { joinMessSchema } = require('../middleware/schemas');

const router = express.Router();

router.post('/join/:messId', protect, authorize('Customer'), validate(joinMessSchema), joinMess);

router.get('/mess', protect, authorize('Manager'), getMessMembers);

router.put('/approve/:membershipId', protect, authorize('Manager'), approveMembership);

router.put('/reject/:membershipId', protect, authorize('Manager'), rejectMembership);

router.get('/my-memberships', protect, authorize('Customer'), getMyMemberships);

router.put('/leave/:membershipId', protect, authorize('Customer'), leaveMess);

module.exports = router;
