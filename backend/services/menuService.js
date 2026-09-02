// new_backend/services/menuService.js
const knex = require('../db/knex');
const { getTodayInIndia } = require('./messClock');

function toPublicMenu(row) {
  return {
    id: row.id,
    serviceDate: row.service_date,
    lunchItems: row.lunch_items,
    dinnerItems: row.dinner_items,
  };
}

// Set (or replace) the menu for one day. Menus are stored one row per mess
// per day, so re-posting the same date just overwrites it.
async function setMenu(messId, { serviceDate, lunchItems, dinnerItems }) {
  const [menu] = await knex('menus')
    .insert({
      mess_id: messId,
      service_date: serviceDate,
      lunch_items: lunchItems,
      dinner_items: dinnerItems,
    })
    .onConflict(['mess_id', 'service_date'])
    .merge({ lunch_items: lunchItems, dinner_items: dinnerItems, updated_at: knex.fn.now() })
    .returning('*');

  return toPublicMenu(menu);
}

// No date range given means "just today", which is what the app asks for on
// both dashboards.
async function getMenus(messId, { from, to } = {}) {
  const today = await getTodayInIndia();
  const startDate = from || today;
  const endDate = to || startDate;

  const rows = await knex('menus')
    .where('mess_id', messId)
    .andWhere('service_date', '>=', startDate)
    .andWhere('service_date', '<=', endDate)
    .orderBy('service_date');

  return rows.map(toPublicMenu);
}

module.exports = { setMenu, getMenus };
