// routes/manager.routes.js
const express = require('express');
const router = express.Router();

const {
  getMyMess,
  updateMyMess,
  getDashboardStats,
  getMessMembers,
  updateWeeklyMenu,
  getPaymentApprovals,
  updateInvoiceStatus,
  getAnalytics,
  runBillingForMonth,
} = require('../controllers/manager.controller.js');

const { protect, isManager } = require('../middlewares/auth.middleware.js');

router.use(protect, isManager);

router.route('/my-mess').get(getMyMess).put(updateMyMess);
router.put('/my-mess/menu', updateWeeklyMenu);

router.get('/my-mess/dashboard-stats', getDashboardStats);
router.get('/my-mess/analytics', getAnalytics);

router.get('/my-mess/members', getMessMembers);
router.get('/my-mess/payment-approvals', getPaymentApprovals);
router.put('/my-mess/invoices/:invoiceId/status', updateInvoiceStatus);

// Month-end billing run
router.post('/my-mess/billing/run', runBillingForMonth);

module.exports = router;
