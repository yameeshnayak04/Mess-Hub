// new_backend/controllers/billingController.js
const billPaymentService = require('../services/billPaymentService');
const { readPagination } = require('../utils/pagination');

// Customer: my bills for one membership.
async function listMyBills(req, res) {
  const { page, limit, offset } = readPagination(req.validatedQuery || {});
  const result = await billPaymentService.listBillsForMembership(req.membership.id, {
    page,
    limit,
    offset,
  });
  res.json({ success: true, data: result.data, meta: result.meta });
}

// Customer uploads a screenshot of their payment.
async function submitPaymentProof(req, res) {
  const bill = await billPaymentService.submitPaymentProof(
    req.params.billId,
    req.user.id,
    req.uploadedImage
  );
  res.json({ success: true, data: bill });
}

// Manager: every bill in the mess, filterable by status / month / year.
async function listMessBills(req, res) {
  const query = req.validatedQuery;
  const { page, limit, offset } = readPagination(query);

  const result = await billPaymentService.listBillsForMess(req.mess.id, {
    status: query.status,
    month: query.month,
    year: query.year,
    page,
    limit,
    offset,
  });

  res.json({ success: true, data: result.data, meta: result.meta });
}

async function approvePayment(req, res) {
  const bill = await billPaymentService.approvePayment(req.params.billId, req.mess.id, req.user.id);
  res.json({ success: true, data: bill });
}

async function rejectPayment(req, res) {
  const bill = await billPaymentService.rejectPayment(
    req.params.billId,
    req.mess.id,
    req.user.id,
    req.body?.note
  );
  res.json({ success: true, data: bill });
}

// Returns a short-lived signed link to the proof image. The image itself is
// private on Cloudinary, so this endpoint is the only way to see it.
async function getPaymentProof(req, res) {
  const proof = await billPaymentService.getPaymentProofUrl(req.params.billId, req.mess.id);
  res.json({ success: true, data: proof });
}

// Full audit trail for one bill: submitted, approved, rejected, by whom.
async function getBillHistory(req, res) {
  const history = await billPaymentService.getBillHistory(req.params.billId, req.mess.id);
  res.json({ success: true, data: history });
}

module.exports = {
  listMyBills,
  submitPaymentProof,
  listMessBills,
  approvePayment,
  rejectPayment,
  getPaymentProof,
  getBillHistory,
};
