// This file defines the API routes for creating and discovering messes.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    registerMess,
    getNearbyMesses,
    getMessProfile
} = require('../controllers/mess.controller.js');

// Import our security middleware.
const { protect, isManager, isCustomer } = require('../middlewares/auth.middleware.js');

// --- ROUTES ---

// Route for a manager to register their mess.
// The request first goes through 'protect' (checks for valid JWT),
// then 'isManager' (checks if the user has the manager role),
// and finally to the 'registerMess' controller if both pass.
router.post('/', protect, isManager, registerMess);

// Route for a customer to find nearby messes.
// This is protected to ensure only logged-in customers can search.
router.get('/nearby', protect, isCustomer, getNearbyMesses);

// Route to get the public profile of a single mess.
// This is a public route, so it does not need any middleware.
router.get('/:messId', getMessProfile);


module.exports = router;