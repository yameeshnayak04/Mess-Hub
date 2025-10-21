// routes/customer.routes.js
const express = require('express');
const router = express.Router();

const {
  getMyProfile,
  updateMyProfile,
  getMyInvoices,
  joinMess,
  markLeave,
  toggleMealSkip,
  notifyPayment,
  getMyMemberships,
} = require('../controllers/customer.controller.js');

const { protect, isCustomer } = require('../middlewares/auth.middleware.js');

router.use(protect, isCustomer);

router.route('/me/profile').get(getMyProfile).put(updateMyProfile);
router.get('/me/invoices', getMyInvoices);

router.post('/memberships', joinMess);
router.get('/me/memberships', getMyMemberships);
router.post('/memberships/:membershipId/leaves', markLeave);
router.post('/memberships/:membershipId/toggle-meal', toggleMealSkip);

router.post('/invoices/:invoiceId/notify-payment', notifyPayment);

module.exports = router;
