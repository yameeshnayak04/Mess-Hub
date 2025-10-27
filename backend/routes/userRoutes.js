// routes/userRoutes
const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const validate = require('../middleware/validate');
const { updateProfileSchema } = require('../middleware/schemas');
const { protect } = require('../middleware/auth');

router.get('/profile/me', protect, userController.getMyProfile);
router.put('/profile/me', protect, validate(updateProfileSchema), userController.updateMyProfile);

module.exports = router;
