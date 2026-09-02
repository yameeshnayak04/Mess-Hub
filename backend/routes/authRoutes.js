// new_backend/routes/authRoutes.js
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const { protect } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const schemas = require('../middleware/schemas');
const { loginLimiter } = require('../middleware/rateLimiters');
const authController = require('../controllers/authController');

const router = express.Router();

router.post('/register', validateBody(schemas.register), asyncHandler(authController.register));
// Rate limited because login is the obvious place to try guessing passwords.
router.post(
  '/login',
  loginLimiter,
  validateBody(schemas.login),
  asyncHandler(authController.login)
);
router.post('/logout', protect, asyncHandler(authController.logout));

router.get('/me', protect, asyncHandler(authController.getMyProfile));
router.patch(
  '/me',
  protect,
  validateBody(schemas.updateProfile),
  asyncHandler(authController.updateMyProfile)
);

module.exports = router;
