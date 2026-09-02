// new_backend/controllers/messController.js
const knex = require('../db/knex');
const messService = require('../services/messService');
const attendanceService = require('../services/attendanceService');
const menuService = require('../services/menuService');
const { readPagination } = require('../utils/pagination');
const { ValidationError } = require('../errors/AppError');

async function createMess(req, res) {
  const input = { ...req.body };
  if (req.uploadedImage) input.messImage = req.uploadedImage.url;

  const result = await messService.createMess(req.user.id, input);
  res.status(201).json({ success: true, data: result });
}

async function getMyMess(req, res) {
  const mess = await messService.getMessForOwner(req.user.id);
  res.json({ success: true, data: mess });
}

async function updateMyMess(req, res) {
  const input = { ...req.body };
  if (req.uploadedImage) input.messImage = req.uploadedImage.url;

  const mess = await messService.updateMess(req.mess.id, input);
  res.json({ success: true, data: mess });
}

async function getMessById(req, res) {
  const mess = await messService.getMessById(req.params.messId);
  res.json({ success: true, data: mess });
}

async function discoverMesses(req, res) {
  const query = req.validatedQuery;
  const { page, limit, offset } = readPagination(query);

  // Sort by distance from wherever the customer is. Their saved location is
  // the default; the app can override it with ?longitude=&latitude= if the
  // user pans the map somewhere else.
  const customer = await knex('users')
    .select(
      knex.raw('ST_X(location::geometry) AS longitude'),
      knex.raw('ST_Y(location::geometry) AS latitude')
    )
    .where('id', req.user.id)
    .first();

  if (!customer || customer.longitude === null) {
    throw new ValidationError('Set your location in your profile to discover nearby messes');
  }

  const result = await messService.discoverMesses({
    longitude: customer.longitude,
    latitude: customer.latitude,
    cuisine: query.cuisine,
    serviceType: query.serviceType,
    search: query.search,
    page,
    limit,
    offset,
  });

  res.json({ success: true, data: result.data, meta: result.meta });
}

// Live "who is eating right now" numbers for the manager's home screen.
async function getDashboard(req, res) {
  const stats = await attendanceService.getLiveMealStats(req.mess, req.validatedQuery?.meal);
  const menus = await menuService.getMenus(req.mess.id);

  res.json({
    success: true,
    data: { ...stats, todaysMenu: menus[0] || null },
  });
}

// The drill-down list behind each dashboard number.
async function getDashboardMembers(req, res) {
  const query = req.validatedQuery;
  const { page, limit, offset } = readPagination(query);

  const result = await attendanceService.listMembersByMealStatus(req.mess, {
    status: query.status,
    meal: query.meal,
    page,
    limit,
    offset,
  });

  res.json({ success: true, data: result.data, meta: result.meta });
}

module.exports = {
  createMess,
  getMyMess,
  updateMyMess,
  getMessById,
  discoverMesses,
  getDashboard,
  getDashboardMembers,
};
