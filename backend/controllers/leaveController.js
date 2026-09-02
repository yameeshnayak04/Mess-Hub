// new_backend/controllers/leaveController.js
const leaveService = require('../services/leaveService');
const { readPagination } = require('../utils/pagination');

async function applyForLeave(req, res) {
  const leave = await leaveService.applyForLeave(req.membership, req.body);
  res.status(201).json({ success: true, data: leave });
}

// Works for the customer viewing their own leave and the manager viewing a
// member's leave history - loadMembership handles the permission check.
async function listLeavesForMembership(req, res) {
  const { page, limit, offset } = readPagination(req.validatedQuery || {});
  const result = await leaveService.listLeavesForMembership(req.membership.id, {
    page,
    limit,
    offset,
  });
  res.json({ success: true, data: result.data, meta: result.meta });
}

async function listMessLeaves(req, res) {
  const { page, limit, offset } = readPagination(req.validatedQuery || {});
  const result = await leaveService.listLeavesForMess(req.mess.id, { page, limit, offset });
  res.json({ success: true, data: result.data, meta: result.meta });
}

async function listMembersOnLeaveToday(req, res) {
  const result = await leaveService.listMembersOnLeave(req.mess.id);
  res.json({ success: true, data: result });
}

module.exports = {
  applyForLeave,
  listLeavesForMembership,
  listMessLeaves,
  listMembersOnLeaveToday,
};
