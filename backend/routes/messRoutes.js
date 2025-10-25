const express = require('express');
const {
  createMess,
  getMyMess,
  updateMyMess,
  discoverMesses,
  getMessById,
  getDashboardStats
} = require('../controllers/messController');
const { protect, authorize } = require('../middleware/auth');
const { uploadMessImage } = require('../middleware/upload');
const validate = require('../middleware/validate');
const { createMessSchema, updateMessSchema } = require('../middleware/schemas');

const router = express.Router();

router.post(
  '/',
  protect,
  authorize('Manager'),
  uploadMessImage.single('messImage'),
  validate(createMessSchema),
  createMess
);

router.get('/my-mess', protect, authorize('Manager'), getMyMess);

router.put(
  '/my-mess',
  protect,
  authorize('Manager'),
  uploadMessImage.single('messImage'),
  validate(updateMessSchema),
  updateMyMess
);

router.get('/my-mess/dashboard', protect, authorize('Manager'), getDashboardStats);

router.get('/discover', protect, authorize('Customer'), discoverMesses);

router.get('/:messId', protect, getMessById);

module.exports = router;
