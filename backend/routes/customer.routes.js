// routes/customer.routes.js
const express = require('express');
const router = express.Router();

const {
  getProfile,
  setKioskPin,
  updateKioskPin,
  updateProfile,
  joinMess,
  getMyMemberships,
  getMembershipDetails,
  toggleMealSkip,
  markLeave,
  getAttendance,
  requestPaymentApproval,
  getCurrentDues,
  leaveMembership,
  upsertReview,
  getInvoice,
} = require('../controllers/customer.controller.js');

const { protect, isCustomer } = require('../middlewares/auth.middleware.js');

router.use(protect, isCustomer);

// Profile and PIN
router.get('/me/profile', getProfile);
router.put('/me/profile', updateProfile);
router.put('/me/pin', setKioskPin);               // set or update kiosk PIN

// Memberships
router.post('/memberships', joinMess);
router.get('/me/memberships', getMyMemberships);
router.get('/memberships/:membershipId', getMembershipDetails);
router.post('/memberships/:membershipId/leave', leaveMembership);

// Attendance and toggles
router.get('/memberships/:membershipId/attendance', getAttendance);
router.post('/memberships/:membershipId/toggle-skip', toggleMealSkip);

// Leave
router.post('/memberships/:membershipId/leaves', markLeave);

// Invoices and dues
router.post('/invoices/:invoiceId/request-approval', requestPaymentApproval);
router.get('/invoices/:invoiceId', getInvoice);
router.get('/me/dues/current', getCurrentDues);

// Reviews
router.post('/messes/:messId/reviews', upsertReview);

module.exports = router;
