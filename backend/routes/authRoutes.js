const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const validate = require('../middleware/validate');
const { registerSchema, loginSchema } = require('../middleware/schemas');
const { protect } = require('../middleware/auth');

// Register (Customer or Manager)
router.post('/register', validate(registerSchema), authController.register);

// Login with phone + password
router.post('/login', validate(loginSchema), authController.login);

// Optional: Logout endpoint (stateless JWT; returns success for client token discard)
router.post('/logout', protect, authController.logout);

module.exports = router;
