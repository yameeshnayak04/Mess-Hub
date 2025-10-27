// routes/menuRoutes
const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { setMenuSchema, getMenuSchema } = require('../middleware/schemas');

router.post('/', protect, authorize('Manager'), validate(setMenuSchema), menuController.setMenu);
router.get('/:messId', validate(getMenuSchema), menuController.getMenu);

module.exports = router;
