// routes/authRoutes.js
const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const validate = require('../middleware/validate');
const { registerSchema, loginSchema } = require('../middleware/schemas');
const { protect } = require('../middleware/auth');

// Register (Customer or Manager)
// Removed validation: registerSchema is missing 'password'
router.post('/register', authController.register);

// Login with phone + password
// Removed validation: loginSchema validates 'kioskPin', not 'password'
router.post('/login', authController.login);

// Kiosk login with phone + PIN
router.post('/kiosk-login', validate(loginSchema), authController.kioskLogin);

// Optional: Logout endpoint
router.post('/logout', protect, authController.logout);

module.exports = router;