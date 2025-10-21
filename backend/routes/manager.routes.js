// This file defines API routes for the mess manager's dashboard and tools.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    getMyMess,
    updateMyMess,
    getDashboardStats,
    getMessMembers,
    updateWeeklyMenu,
    getPaymentApprovals,
    updateInvoiceStatus,
    getAnalytics,
} = require('../controllers/manager.controller.js');

// Import security middleware.
const { protect, isManager } = require('../middlewares/auth.middleware.js');

// --- PROTECTED MANAGER ROUTES ---
// Apply the 'protect' and 'isManager' middleware to all routes below.
router.use(protect, isManager);


// --- Mess Profile & Menu Routes ---
router.route('/my-mess')
    .get(getMyMess)          // GET my mess profile
    .put(updateMyMess);      // PUT (update) my mess profile

router.put('/my-mess/menu', updateWeeklyMenu); // Create or update the weekly menu

// --- Dashboard & Analytics Routes ---
router.get('/my-mess/dashboard-stats', getDashboardStats); // Get live stats
router.get('/my-mess/analytics', getAnalytics); // Get simple analytics for a month

// --- Member & Payment Management Routes ---
router.get('/my-mess/members', getMessMembers); // Get a list of all members
router.get('/my-mess/payment-approvals', getPaymentApprovals); // Get payments pending approval
router.put('/my-mess/invoices/:invoiceId/status', updateInvoiceStatus); // Approve or reject a payment


module.exports = router;