// This file defines the API routes for authentication.

const express = require('express');
const router = express.Router();

// Import the controller functions that contain the logic for each route.
const {
    sendRegistrationOtp,
    verifyRegistrationOtp,
    sendLoginOtp,
    verifyLoginOtp
} = require('../controllers/auth.controller.js');

// --- PUBLIC ROUTES ---

// Route to handle sending an OTP for a new user registration.
router.post('/register/send-otp', sendRegistrationOtp);

// Route to handle verifying the OTP and creating the new user.
router.post('/register/verify-otp', verifyRegistrationOtp);

// Route to handle sending an OTP for an existing user to log in.
router.post('/login/send-otp', sendLoginOtp);

// Route to handle verifying the OTP and logging the user in.
router.post('/login/verify-otp', verifyLoginOtp);

// Export the router so it can be used in the main index.js file.
module.exports = router;