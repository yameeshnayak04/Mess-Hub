// routes/auth.routes.js
const express = require('express');
const router = express.Router();

const {
  sendRegistrationOtp,
  verifyRegistrationOtp,
  sendLoginOtp,
  verifyLoginOtp,
  updatePin,
} = require('../controllers/auth.controller.js');

const { protect } = require('../middlewares/auth.middleware.js');

// OTP flows
router.post('/register/send-otp', sendRegistrationOtp);
router.post('/register/verify-otp', verifyRegistrationOtp);
router.post('/login/send-otp', sendLoginOtp);
router.post('/login/verify-otp', verifyLoginOtp);

// Customer PIN management
router.put('/me/pin', protect, updatePin);

module.exports = router;
