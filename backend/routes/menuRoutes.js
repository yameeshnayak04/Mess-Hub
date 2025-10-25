const express = require('express');
const { setMenu, getMenu } = require('../controllers/menuController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { menuSchema } = require('../middleware/schemas');

const router = express.Router();

router.post('/', protect, authorize('Manager'), validate(menuSchema), setMenu);

router.get('/:messId', protect, getMenu);

module.exports = router;
