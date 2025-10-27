// routes/membershipRoutes.js
const express = require('express');
const router = express.Router();

const membershipController = require('../controllers/membershipController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { joinMessSchema } = require('../middleware/schemas'); // Removed missing schema

// Customer
router.post('/join/:messId', protect, authorize('Customer'), validate(joinMessSchema), membershipController.joinMess);
// Removed validation: leaveMembershipSchema is missing
router.put('/leave/:membershipId', protect, authorize('Customer'), membershipController.leaveMess);
router.get('/my-memberships', protect, authorize('Customer'), membershipController.getMyMemberships);
router.get('/details/:membershipId', protect, authorize('Customer'), membershipController.getMembershipDetails);

// Manager
router.get('/mess', protect, authorize('Manager'), membershipController.getMessMembers);
router.put('/approve/:membershipId', protect, authorize('Manager'), membershipController.approveMembership);
router.put('/reject/:membershipId', protect, authorize('Manager'), membershipController.rejectMembership);
router.put('/verify-leave/:membershipId', protect, authorize('Manager'), membershipController.verifyLeaveMembership);

// NEW: Manager route for single member details
router.get('/member/:membershipId', protect, authorize('Manager'), membershipController.getMemberDetails);

module.exports = router;