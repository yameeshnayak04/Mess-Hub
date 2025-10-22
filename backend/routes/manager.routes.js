// routes/manager.routes.js
const express = require('express');
const router = express.Router();

const {
  getMyMess,
  updateMyMess,
  getDashboardStats,
  getMessMembers,
  getPaymentApprovals,
  updateInvoiceStatus,
  runBillingForMonth,
} = require('../controllers/manager.controller.js');

const { getMenu, updateMenu } = require('../controllers/mess.controller.js');
const { protect, isManager } = require('../middlewares/auth.middleware.js');
const Mess = require('../models/mess.model.js');

// Helper: inject :messId of the authenticated manager
const injectMyMessId = async (req, res, next) => {
  const mess = await Mess.findOne({ owner: req.user._id }).select('_id');
  if (!mess) return res.status(404).json({ message: 'Mess not found' });
  req.params.messId = mess._id;
  return next();
};

router.use(protect, isManager);

router.route('/my-mess').get(getMyMess).put(updateMyMess);
router.get('/my-mess/dashboard-stats', getDashboardStats);
router.get('/my-mess/members', getMessMembers);

// Daily menu via manager context (no need to expose messId)
router.get('/my-mess/menu', injectMyMessId, getMenu);
router.put('/my-mess/menu', injectMyMessId, updateMenu);

// Payments and billing
router.get('/my-mess/payment-approvals', getPaymentApprovals);
router.put('/my-mess/invoices/:invoiceId/status', updateInvoiceStatus);
router.post('/my-mess/billing/run', runBillingForMonth);

module.exports = router;
