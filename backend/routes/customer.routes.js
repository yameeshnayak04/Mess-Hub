// This file defines API routes for actions performed by a logged-in customer.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    joinMess,
    getMyProfile,       // <-- New
    updateMyProfile,    // <-- New
    markLeave,
    toggleMealSkip,     // <-- New
    notifyPayment,      // <-- New
    getMyMemberships,
} = require('../controllers/customer.controller.js');

// Import security middleware.
const { protect, isCustomer } = require('../middlewares/auth.middleware.js');

// --- PROTECTED CUSTOMER ROUTES ---
// We apply the 'protect' and 'isCustomer' middleware to all routes in this file.
// This is a clean way to protect all endpoints defined below.
router.use(protect, isCustomer);

// --- Profile Routes ---
router.route('/me/profile')
    .get(getMyProfile)       // Get my profile
    .put(updateMyProfile);   // Update my profile

// --- Membership Routes ---
router.post('/memberships', joinMess); // Join a new mess
router.get('/me/memberships', getMyMemberships); // Get all my memberships
router.post('/memberships/:membershipId/leaves', markLeave); // Mark a formal leave
router.post('/memberships/:membershipId/toggle-meal', toggleMealSkip); // Toggle "Not Eating"

// --- Payment Routes ---
router.post('/invoices/:invoiceId/notify-payment', notifyPayment); // Notify manager of payment


module.exports = router;