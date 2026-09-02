// new_backend/middleware/schemas.js
//
// Joi schemas describing the shape of every request body we accept. These
// only check *shape* (is this a 10-digit phone? is rating between 1 and 5?).
// Business rules like "leave must be at least N days" are enforced deeper
// down, in the database, so they can never be bypassed.
const Joi = require('joi');

const phone = Joi.string()
  .pattern(/^[0-9]{10}$/)
  .messages({ 'string.pattern.base': 'Phone number must be exactly 10 digits' });

const pin = Joi.string()
  .pattern(/^[0-9]{4}$/)
  .messages({ 'string.pattern.base': 'PIN must be exactly 4 digits' });

const timeOfDay = Joi.string()
  .pattern(/^([01]\d|2[0-3]):[0-5]\d$/)
  .messages({ 'string.pattern.base': 'Time must look like HH:MM, e.g. 12:30' });

const isoDate = Joi.string()
  .pattern(/^\d{4}-\d{2}-\d{2}$/)
  .messages({ 'string.pattern.base': 'Date must look like YYYY-MM-DD' });

const coordinates = Joi.object({
  longitude: Joi.number().min(-180).max(180).required(),
  latitude: Joi.number().min(-90).max(90).required(),
});

// The API accepts and returns plain rupees; the database stores whole
// smallest-currency units. utils/money.js does that conversion in one place,
// so no controller has to remember to do it.
const rupees = Joi.number().min(0).precision(2);

const register = Joi.object({
  name: Joi.string().trim().min(2).max(80).required(),
  phone: phone.required(),
  password: Joi.string().min(8).max(72).required(),
  role: Joi.string().valid('Customer', 'Manager').required(),
  // Customers use a 4-digit PIN at the mess kiosk and have a location for
  // "messes near me"; managers need neither.
  pin: pin.when('role', { is: 'Customer', then: Joi.required(), otherwise: Joi.forbidden() }),
  location: coordinates.when('role', {
    is: 'Customer',
    then: Joi.required(),
    otherwise: Joi.forbidden(),
  }),
});

const login = Joi.object({
  phone: phone.required(),
  password: Joi.string().required(),
});

const updateProfile = Joi.object({
  name: Joi.string().trim().min(2).max(80),
  pin,
}).min(1);

const planInput = Joi.object({
  name: Joi.string().trim().min(2).max(80).required(),
  rateRupees: rupees.required(),
  meals: Joi.array().items(Joi.string().valid('Lunch', 'Dinner')).min(1).unique().required(),
});

const createMess = Joi.object({
  messName: Joi.string().trim().min(2).max(120).required(),
  address: Joi.string().trim().min(5).max(250).required(),
  city: Joi.string().trim().min(2).max(80).required(),
  contactPhone: phone.required(),
  location: coordinates.required(),
  serviceType: Joi.string().valid('Monthly Only', 'Both Daily & Monthly').required(),
  cuisine: Joi.string().valid('Veg', 'Non-Veg', 'Both').required(),
  maxCapacity: Joi.number().integer().min(1).allow(null),
  tiffinService: Joi.boolean().default(false),
  basicThaliDetails: Joi.string().trim().min(5).max(500).required(),
  lunchStart: timeOfDay.required(),
  lunchEnd: timeOfDay.required(),
  dinnerStart: timeOfDay.required(),
  dinnerEnd: timeOfDay.required(),
  dailyThaliRateRupees: rupees.allow(null),
  rules: Joi.object({
    minLeaveDaysForRebate: Joi.number().integer().min(1).required(),
    rebatePerThaliRupees: rupees.required(),
    skipAllowancePercent: Joi.number().integer().min(0).max(100).default(0),
    allowAbsentRebate: Joi.boolean().default(false),
    minMonthlyChargeRupees: rupees.allow(null),
    securityDepositRupees: rupees.allow(null),
  }).required(),
  plans: Joi.array().items(planInput).min(1).required(),
});

// Everything optional - a manager may update just one field.
const updateMess = Joi.object({
  messName: Joi.string().trim().min(2).max(120),
  address: Joi.string().trim().min(5).max(250),
  city: Joi.string().trim().min(2).max(80),
  contactPhone: phone,
  serviceType: Joi.string().valid('Monthly Only', 'Both Daily & Monthly'),
  cuisine: Joi.string().valid('Veg', 'Non-Veg', 'Both'),
  maxCapacity: Joi.number().integer().min(1).allow(null),
  tiffinService: Joi.boolean(),
  basicThaliDetails: Joi.string().trim().min(5).max(500),
  lunchStart: timeOfDay,
  lunchEnd: timeOfDay,
  dinnerStart: timeOfDay,
  dinnerEnd: timeOfDay,
  dailyThaliRateRupees: rupees.allow(null),
  rules: Joi.object({
    minLeaveDaysForRebate: Joi.number().integer().min(1),
    rebatePerThaliRupees: rupees,
    skipAllowancePercent: Joi.number().integer().min(0).max(100),
    allowAbsentRebate: Joi.boolean(),
    minMonthlyChargeRupees: rupees.allow(null),
    securityDepositRupees: rupees.allow(null),
  }),
}).min(1);

const joinMess = Joi.object({
  planId: Joi.number().integer().positive().required(),
});

const skipMeal = Joi.object({
  meal: Joi.string().valid('Lunch', 'Dinner').required(),
});

const kioskMark = Joi.object({
  membershipId: Joi.number().integer().positive().required(),
  pin: pin.required(),
  meal: Joi.string().valid('Lunch', 'Dinner').required(),
});

const walkinSale = Joi.object({
  meal: Joi.string().valid('Lunch', 'Dinner').required(),
  quantity: Joi.number().integer().min(1).max(50).default(1),
});

const applyLeave = Joi.object({
  startDate: isoDate.required(),
  endDate: isoDate.required(),
  reason: Joi.string().trim().max(300).allow('', null),
});

const setMenu = Joi.object({
  serviceDate: isoDate.required(),
  lunchItems: Joi.array().items(Joi.string().trim().min(1).max(80)).default([]),
  dinnerItems: Joi.array().items(Joi.string().trim().min(1).max(80)).default([]),
});

const upsertReview = Joi.object({
  rating: Joi.number().integer().min(1).max(5).required(),
  comment: Joi.string().trim().max(1000).allow('', null),
});

const discoverQuery = Joi.object({
  cuisine: Joi.string().valid('Veg', 'Non-Veg', 'Both'),
  serviceType: Joi.string().valid('Monthly Only', 'Both Daily & Monthly'),
  search: Joi.string().trim().max(120),
  page: Joi.number().integer().min(1),
  limit: Joi.number().integer().min(1).max(100),
});

const calendarQuery = Joi.object({
  month: Joi.number().integer().min(1).max(12),
  year: Joi.number().integer().min(2020).max(2100),
});

const mealStatsQuery = Joi.object({
  meal: Joi.string().valid('Lunch', 'Dinner'),
});

const memberStatusQuery = Joi.object({
  status: Joi.string().valid('Present', 'Skipped', 'Leave', 'Absent', 'Remaining').required(),
  meal: Joi.string().valid('Lunch', 'Dinner'),
  page: Joi.number().integer().min(1),
  limit: Joi.number().integer().min(1).max(100),
});

const billsQuery = Joi.object({
  status: Joi.string().valid('Due', 'Pending Approval', 'Paid'),
  month: Joi.number().integer().min(1).max(12),
  year: Joi.number().integer().min(2020).max(2100),
  page: Joi.number().integer().min(1),
  limit: Joi.number().integer().min(1).max(100),
});

const pageQuery = Joi.object({
  page: Joi.number().integer().min(1),
  limit: Joi.number().integer().min(1).max(100),
});

const membersQuery = Joi.object({
  status: Joi.string().valid('Pending', 'Active', 'Inactive'),
  page: Joi.number().integer().min(1),
  limit: Joi.number().integer().min(1).max(100),
});

const menuQuery = Joi.object({
  from: isoDate,
  to: isoDate,
});

module.exports = {
  register,
  login,
  updateProfile,
  createMess,
  updateMess,
  planInput,
  joinMess,
  skipMeal,
  kioskMark,
  walkinSale,
  applyLeave,
  setMenu,
  upsertReview,
  discoverQuery,
  calendarQuery,
  mealStatsQuery,
  memberStatusQuery,
  billsQuery,
  pageQuery,
  membersQuery,
  menuQuery,
};
