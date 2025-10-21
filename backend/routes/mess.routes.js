// routes/mess.routes.js
const express = require('express');
const router = express.Router();

const { registerMess, getNearbyMesses, getMessProfile, createReview, getMessReviews, getWeeklyMenu } = require('../controllers/mess.controller.js');
const { protect, isManager, isCustomer } = require('../middlewares/auth.middleware.js');

router.post('/', protect, isManager, registerMess);
router.get('/nearby', protect, isCustomer, getNearbyMesses);
router.get('/:messId', getMessProfile);
router.post('/:messId/reviews', protect, isCustomer, createReview);
router.get('/:messId/reviews', getMessReviews);
router.get('/:messId/menu', getWeeklyMenu);

module.exports = router;
