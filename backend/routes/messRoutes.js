// routes/messRoutes.js
const express = require('express');
const {
  createMess,
  getMyMess,
  updateMyMess,
  discoverMesses,
  getMessById,
  getDashboardStats,
  getMembersEating,
  getMembersOnLeave,
  getMembersSkipped
} = require('../controllers/messController');
const { protect, authorize } = require('../middleware/auth');
const { uploadMessImage } = require('../middleware/upload'); // <-- match export name
const validate = require('../middleware/validate');
const { createMessSchema, updateMessSchema } = require('../middleware/schemas');

const router = express.Router();

router.post(
  '/',
  protect,
  authorize('Manager'),
  uploadMessImage.single('messImage'),          // <-- use uploadMessImage
  validate(createMessSchema),
  createMess
);

router.get('/my-mess', protect, authorize('Manager'), getMyMess);

router.put(
  '/my-mess',
  protect,
  authorize('Manager'),
  uploadMessImage.single('messImage'),          // <-- use uploadMessImage
  validate(updateMessSchema),
  updateMyMess
);

router.get('/my-mess/dashboard', protect, authorize('Manager'), getDashboardStats);
router.get('/dashboard/members-eating', protect, authorize('Manager'), getMembersEating);
router.get('/dashboard/members-on-leave', protect, authorize('Manager'), getMembersOnLeave);
router.get('/dashboard/members-skipped', protect, authorize('Manager'), getMembersSkipped);

// Discovery endpoints (keep as you prefer: public or customer-protected)
router.get('/discover', protect, authorize('Customer'), discoverMesses);
router.get('/:messId', protect, getMessById);

module.exports = router;
