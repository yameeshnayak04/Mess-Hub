// new_backend/controllers/planController.js
const planService = require('../services/planService');

async function listPlans(req, res) {
  const plans = await planService.listPlansForMess(req.params.messId);
  res.json({ success: true, data: plans });
}

async function listMyPlans(req, res) {
  const plans = await planService.listPlansForMess(req.mess.id, { includeInactive: true });
  res.json({ success: true, data: plans });
}

async function addPlan(req, res) {
  const plan = await planService.addPlanToMess(req.mess.id, req.body);
  res.status(201).json({ success: true, data: plan });
}

async function updatePlan(req, res) {
  const plan = await planService.updatePlan(req.mess.id, req.params.planId, req.body);
  res.json({ success: true, data: plan });
}

async function deactivatePlan(req, res) {
  const result = await planService.deactivatePlan(req.mess.id, req.params.planId);
  res.json({ success: true, data: result });
}

module.exports = { listPlans, listMyPlans, addPlan, updatePlan, deactivatePlan };
