// new_backend/controllers/membershipController.js
const membershipService = require('../services/membershipService');
const { readPagination } = require('../utils/pagination');

async function joinMess(req, res) {
  const membership = await membershipService.joinMess(
    req.user.id,
    Number(req.params.messId),
    req.body.planId
  );
  res.status(201).json({ success: true, data: membershipService.toPublicMembership(membership) });
}

async function listMyMemberships(req, res) {
  const memberships = await membershipService.listMyMemberships(req.user.id);
  res.json({ success: true, data: memberships });
}

// Full customer dashboard payload for one membership.
async function getMembershipDetails(req, res) {
  const details = await membershipService.getMembershipDetails(req.membership.id);
  res.json({ success: true, data: details });
}

async function listMessMembers(req, res) {
  const query = req.validatedQuery;
  const { page, limit, offset } = readPagination(query);

  const result = await membershipService.listMessMembers(req.mess.id, {
    status: query.status,
    page,
    limit,
    offset,
  });

  res.json({ success: true, data: result.data, meta: result.meta });
}

async function approveMembership(req, res) {
  const membership = await membershipService.approveMembership(req.membership.id);
  res.json({ success: true, data: membershipService.toPublicMembership(membership) });
}

async function rejectMembership(req, res) {
  const result = await membershipService.rejectMembership(req.membership.id);
  res.json({ success: true, data: result });
}

// Customer asks to leave the mess permanently. This also produces the partial
// bill for the current month straight away, so they can see what they owe.
async function requestDiscontinuation(req, res) {
  const result = await membershipService.requestDiscontinuation(req.membership.id);
  res.json({ success: true, data: result });
}

async function approveDiscontinuation(req, res) {
  const result = await membershipService.approveDiscontinuation(req.membership.id);
  res.json({ success: true, data: result });
}

async function rejectDiscontinuation(req, res) {
  const result = await membershipService.rejectDiscontinuation(req.membership.id);
  res.json({ success: true, data: result });
}

module.exports = {
  joinMess,
  listMyMemberships,
  getMembershipDetails,
  listMessMembers,
  approveMembership,
  rejectMembership,
  requestDiscontinuation,
  approveDiscontinuation,
  rejectDiscontinuation,
};
