// This file defines API routes for actions performed by a logged-in customer.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    joinMess,
    markLeave,
    getMyMemberships
} = require('../controllers/customer.controller.js');

// Import security middleware.
const { protect, isCustomer } = require('../middlewares/auth.middleware.js');

// --- PROTECTED CUSTOMER ROUTES ---
// We apply the 'protect' and 'isCustomer' middleware to all routes in this file.
// This ensures only an authenticated customer can access these endpoints.
router.use(protect, isCustomer);

// Route for a customer to join a mess (create a membership).
router.post('/memberships', joinMess);

// Route for a customer to get a list of all their active memberships.
router.get('/me/memberships', getMyMemberships);

// Route for a customer to mark a leave for a specific membership.
router.post('/memberships/:membershipId/leaves', markLeave);


module.exports = router;