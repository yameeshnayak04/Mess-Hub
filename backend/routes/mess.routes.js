// routes/mess.routes.js
const express = require('express');
const router = express.Router();

const {
  registerMess,
  searchMess,
  getNearbyMesses,
  getMessProfile,
  getMenu,          // daily menu get
  updateMenu,       // daily menu update
  updateMessProfile
} = require('../controllers/mess.controller.js');

const { protect, isManager, requireMessOwner } = require('../middlewares/auth.middleware.js');

// Manager registration and profile updates
router.post('/', protect, isManager, registerMess);
router.put('/:messId', protect, isManager, requireMessOwner, updateMessProfile);

// Search and map
router.get('/search', searchMess);
router.get('/nearby', getNearbyMesses);

// Public mess profile
router.get('/:messId', getMessProfile);

// Daily menu (manager-owned update)
router.get('/:messId/menu', getMenu);
router.put('/:messId/menu', protect, isManager, requireMessOwner, updateMenu);

module.exports = router;
