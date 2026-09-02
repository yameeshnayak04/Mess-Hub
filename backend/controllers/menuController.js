// new_backend/controllers/menuController.js
const menuService = require('../services/menuService');

async function setMenu(req, res) {
  const menu = await menuService.setMenu(req.mess.id, req.body);
  res.json({ success: true, data: menu });
}

// No ?from/?to means "today's menu", which is what both dashboards ask for.
async function getMenus(req, res) {
  const menus = await menuService.getMenus(req.params.messId, req.validatedQuery || {});
  res.json({ success: true, data: menus });
}

module.exports = { setMenu, getMenus };
