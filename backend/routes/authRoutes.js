// routes/authRoutes.js
const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const validate = require('../middleware/validate');
// FIX: Import all 3 schemas
const { registerSchema, loginSchema, kioskLoginSchema } = require('../middleware/schemas');
const { protect } = require('../middleware/auth');

// Register (Customer or Manager)
// FIX: Added validation
router.post('/register', validate(registerSchema), authController.register);

// Login with phone + password
// FIX: Added validation
router.post('/login', validate(loginSchema), authController.login);

// Optional: Logout endpoint
router.post('/logout', protect, authController.logout);

module.exports = router;