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

// routes/messRoutes.js
const normalizeCuisine = (raw) => {
  if (typeof raw !== 'string') return raw;
  const v = raw.trim().toLowerCase().replace(/\s+/g, '');
  if (v == 'veg' || v == 'vegetarian') return 'Veg';
  if (v == 'nonveg' || v == 'non-veg' || v == 'nonvegetarian' || v == 'non-vegetarian') return 'Non-Veg';
  if (v == 'both' || v == 'mixed') return 'Both';
  return raw; // Joi/Mongoose will flag invalid values
};

const parseMessPayload = (req, res, next) => {
  try {
    // Only parse actual JSON fields
    for (const key of ['location', 'timings', 'rules', 'plans']) {
      const val = req.body[key];
      if (typeof val === 'string' && val.trim().length) {
        try { req.body[key] = JSON.parse(val); }
        catch { return res.status(400).json({ success: false, message: `Invalid JSON format for field: ${key}` }); }
      }
    }
    // Booleans that arrive as strings
    if (typeof req.body.tiffinService === 'string') {
      req.body.tiffinService = req.body.tiffinService.toLowerCase() === 'true';
    }
    // Normalize cuisine (do NOT JSON.parse)
    if (typeof req.body.cuisine === 'string') {
      req.body.cuisine = normalizeCuisine(req.body.cuisine);
    }
    // Ensure GeoJSON shape if client sent only coordinates array
    if (req.body.location && !req.body.location.type && Array.isArray(req.body.location.coordinates)) {
      req.body.location = { type: 'Point', coordinates: req.body.location.coordinates.map(Number) };
    }
    next();
  } catch (err) { next(err); }
};

// Use it before validation and controller
router.post('/', protect, authorize('Manager'), uploadMessImage, parseMessPayload, validate(createMessSchema), createMess);
router.put('/my-mess', protect, authorize('Manager'), uploadMessImage, parseMessPayload, validate(updateMessSchema), updateMyMess);


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