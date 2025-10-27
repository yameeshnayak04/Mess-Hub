// routes/menuRoutes
const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { menuSchema } = require('../middleware/schemas'); // Fixed import name

router.post('/', protect, authorize('Manager'), validate(menuSchema), menuController.setMenu);
// Removed validation: getMenuSchema is missing
router.get('/:messId', menuController.getMenu);

module.exports = router;