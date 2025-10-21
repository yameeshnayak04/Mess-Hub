// This file defines API routes for actions performed by a logged-in customer.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    joinMess,
    getMyProfile,
    updateMyProfile,
    markLeave,
    toggleMealSkip,
    notifyPayment,
    getMyMemberships,
    getMyInvoices,
} = require('../controllers/customer.controller.js');

// Import security middleware.
const { protect, isCustomer } = require('../middlewares/auth.middleware.js');

// --- PROTECTED CUSTOMER ROUTES ---
// We apply the 'protect' and 'isCustomer' middleware to all routes in this file.
// This is a clean way to protect all endpoints defined below.
router.use(protect, isCustomer);

// --- Profile Routes ---
router.route('/me/profile')
    .get(getMyProfile)       // GET my profile
    .put(updateMyProfile);   // PUT (update) my profile

// --- Membership Routes ---
router.post('/memberships', joinMess); // Join a new mess
router.get('/me/memberships', getMyMemberships); // Get all my memberships
router.post('/memberships/:membershipId/leaves', markLeave); // Mark a formal leave
router.post('/memberships/:membershipId/toggle-meal', toggleMealSkip); // Toggle "Not Eating"

// --- Payment Routes ---
router.get('/me/invoices', getMyInvoices); // Get all my invoices
router.post('/invoices/:invoiceId/notify-payment', notifyPayment); // Notify manager of payment


module.exports = router;