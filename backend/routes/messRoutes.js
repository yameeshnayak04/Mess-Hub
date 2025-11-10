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
  getMembersSkipped,
  getMembersRemaining // <-- Added
} = require('../controllers/messController');
const { protect, authorize } = require('../middleware/auth');
const { uploadMessImage } = require('../middleware/upload'); // <-- match export name
const validate = require('../middleware/validate');
const { createMessSchema, updateMessSchema } = require('../middleware/schemas');

const router = express.Router();

// backend/routes/messRoutes.js (add before validate)
const parseMessPayload = (req, res, next) => {
  try {
    const fieldsToParse = ['location', 'timings', 'rules', 'plans', 'cuisine', 'basicThaliDetails'];
    for (const key of fieldsToParse) {
      const val = req.body[key];
      if (typeof val === 'string' && val.trim().length) {
        try {
          req.body[key] = JSON.parse(val);
        } catch (e) {
          return res.status(400).json({ success: false, message: `Invalid JSON format for field: ${key}` });
        }
      }
    }
    // Coerce booleans
    if (typeof req.body.tiffinService === 'string') {
      req.body.tiffinService = req.body.tiffinService.toLowerCase() === 'true';
    }
    // Ensure GeoJSON shape if coordinates given as numbers/strings
    if (req.body.location && !req.body.location.type && Array.isArray(req.body.location.coordinates)) {
      req.body.location = { type: 'Point', coordinates: req.body.location.coordinates.map(Number) };
    }
    // Trim messName/city/address
    ['messName','city','address','contactPhone','serviceType'].forEach(f => {
      if (typeof req.body[f] === 'string') req.body[f] = req.body[f].trim();
    });
    next();
  } catch (err) {
    next(err);
  }
};


router.post(
  '/',
  protect,
  authorize('Manager'),
  uploadMessImage,
  parseMessPayload,            // <— add this
  validate(createMessSchema),
  createMess
);

router.put(
  '/my-mess',
  protect,
  authorize('Manager'),
  uploadMessImage, // was uploadMessImage.single('messImage')
  validate(updateMessSchema),
  updateMyMess
);

router.get('/my-mess', protect, authorize('Manager'), getMyMess);

router.get('/my-mess/dashboard', protect, authorize('Manager'), getDashboardStats);
router.get('/dashboard/members-eating', protect, authorize('Manager'), getMembersEating);
router.get('/dashboard/members-on-leave', protect, authorize('Manager'), getMembersOnLeave);
router.get('/dashboard/members-skipped', protect, authorize('Manager'), getMembersSkipped);
router.get('/dashboard/members-remaining', protect, authorize('Manager'), getMembersRemaining); // <-- Added

// Discovery endpoints (keep as you prefer: public or customer-protected)
router.get('/discover', protect, authorize('Customer'), discoverMesses);
router.get('/:messId', protect, getMessById);

module.exports = router;