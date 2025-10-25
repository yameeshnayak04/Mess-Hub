const express = require('express');
const { getMyProfile, updateMyProfile } = require('../controllers/userController');
const { protect } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { updateProfileSchema } = require('../middleware/schemas');

const router = express.Router();

router.get('/profile/me', protect, getMyProfile);
router.put('/profile/me', protect, validate(updateProfileSchema), updateMyProfile);

module.exports = router;
