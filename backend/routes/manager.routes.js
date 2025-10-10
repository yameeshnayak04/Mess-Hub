// This file defines API routes for the mess manager's dashboard and tools.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    getMyMess,
    getDashboardStats,
    updateMyMessRules
} = require('../controllers/manager.controller.js');

// Import security middleware.
const { protect, isManager } = require('../middlewares/auth.middleware.js');

// --- PROTECTED MANAGER ROUTES ---
// Apply the 'protect' and 'isManager' middleware to all routes in this file.
router.use(protect, isManager);

// Route for a manager to get the full profile of their own mess.
router.get('/my-mess', getMyMess);

// Route for a manager to get the live dashboard statistics for their mess.
router.get('/my-mess/dashboard-stats', getDashboardStats);

// Route for a manager to update the operational rules of their mess.
router.put('/my-mess/rules', updateMyMessRules);


module.exports = router;