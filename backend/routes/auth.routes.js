// This file defines the API routes for authentication and user identity.

const express = require('express');
const router = express.Router();

// Import the controller functions.
const {
    sendRegistrationOtp,
    verifyRegistrationOtp,
    sendLoginOtp,
    verifyLoginOtp,
    updatePin, // <-- Import the new PIN function
} = require('../controllers/auth.controller.js');

// Import the security middleware.
const { protect } = require('../middlewares/auth.middleware.js');


// --- PUBLIC ROUTES ---
// These routes are for the initial sign-up and login process.
router.post('/register/send-otp', sendRegistrationOtp);
router.post('/register/verify-otp', verifyRegistrationOtp);
router.post('/login/send-otp', sendLoginOtp);
router.post('/login/verify-otp', verifyLoginOtp);


// --- PROTECTED ROUTE ---
// This route is for a logged-in user to set or change their Kiosk PIN.
// It is protected to ensure only the authenticated user can change their own PIN.
router.put('/me/pin', protect, updatePin);


module.exports = router;