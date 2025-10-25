const Joi = require('joi');

// Auth schemas
exports.registerSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).required(),
  phone: Joi.string().trim().pattern(/^[0-9]{10}$/).required().messages({
    'string.pattern.base': 'Phone number must be 10 digits'
  }),
  kioskPin: Joi.string().pattern(/^[0-9]{4}$/).when('role', {
    is: 'Customer',
    then: Joi.required(),
    otherwise: Joi.forbidden()
  }).messages({
    'string.pattern.base': 'Kiosk PIN must be 4 digits'
  }),
  role: Joi.string().valid('Customer', 'Manager').required(),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required()
  }).when('role', {
    is: 'Customer',
    then: Joi.required(),
    otherwise: Joi.optional()
  })
});

exports.loginSchema = Joi.object({
  phone: Joi.string().trim().pattern(/^[0-9]{10}$/).required(),
  kioskPin: Joi.string().pattern(/^[0-9]{4}$/).required()
});

exports.updateProfileSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).optional(),
  kioskPin: Joi.string().pattern(/^[0-9]{4}$/).optional()
});

// Mess schemas
exports.createMessSchema = Joi.object({
  messName: Joi.string().trim().min(2).max(100).required(),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required()
  }).required(),
  address: Joi.string().trim().min(5).max(200).required(),
  city: Joi.string().trim().min(2).max(50).required(),
  contactPhone: Joi.string().trim().pattern(/^[0-9]{10}$/).required(),
  serviceType: Joi.string().valid('Monthly Only', 'Both Daily & Monthly').required(),
  cuisine: Joi.string().valid('Veg', 'Non-Veg', 'Both').required(),
  maxCapacity: Joi.number().integer().min(1).optional(),
  timings: Joi.object({
    lunch: Joi.object({
      start: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required(),
      end: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required()
    }).required(),
    dinner: Joi.object({
      start: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required(),
      end: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required()
    }).required()
  }).required(),
  plans: Joi.array().items(
    Joi.object({
      name: Joi.string().trim().required(),
      rate: Joi.number().min(0).required()
    })
  ).min(1).required(),
  dailyThaliRate: Joi.number().min(0).when('serviceType', {
    is: 'Both Daily & Monthly',
    then: Joi.required(),
    otherwise: Joi.optional()
  }),
  rules: Joi.object({
    minLeaveDaysForRebate: Joi.number().integer().min(1).required(),
    rebatePerThali: Joi.number().min(0).required(),
    skipAllowancePercent: Joi.number().min(0).max(100).default(0),
    securityDeposit: Joi.number().min(0).optional(),
    minMonthlyCharge: Joi.number().min(0).optional()
  }).required()
});

exports.updateMessSchema = Joi.object({
  messName: Joi.string().trim().min(2).max(100).optional(),
  address: Joi.string().trim().min(5).max(200).optional(),
  city: Joi.string().trim().min(2).max(50).optional(),
  contactPhone: Joi.string().trim().pattern(/^[0-9]{10}$/).optional(),
  serviceType: Joi.string().valid('Monthly Only', 'Both Daily & Monthly').optional(),
  cuisine: Joi.string().valid('Veg', 'Non-Veg', 'Both').optional(),
  maxCapacity: Joi.number().integer().min(1).optional(),
  timings: Joi.object({
    lunch: Joi.object({
      start: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required(),
      end: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required()
    }).optional(),
    dinner: Joi.object({
      start: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required(),
      end: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).required()
    }).optional()
  }).optional(),
  plans: Joi.array().items(
    Joi.object({
      name: Joi.string().trim().required(),
      rate: Joi.number().min(0).required()
    })
  ).min(1).optional(),
  dailyThaliRate: Joi.number().min(0).optional(),
  rules: Joi.object({
    minLeaveDaysForRebate: Joi.number().integer().min(1).optional(),
    rebatePerThali: Joi.number().min(0).optional(),
    skipAllowancePercent: Joi.number().min(0).max(100).optional(),
    securityDeposit: Joi.number().min(0).optional(),
    minMonthlyCharge: Joi.number().min(0).optional()
  }).optional()
});

// Membership schemas
exports.joinMessSchema = Joi.object({
  planName: Joi.string().trim().required()
});

// Attendance schemas
exports.skipMealSchema = Joi.object({
  membershipId: Joi.string().hex().length(24).required(),
  mealType: Joi.string().valid('Lunch', 'Dinner').required(),
  date: Joi.date().iso().optional()
});

exports.kioskMarkSchema = Joi.object({
  userId: Joi.string().hex().length(24).required(),
  kioskPin: Joi.string().pattern(/^[0-9]{4}$/).required(),
  mealType: Joi.string().valid('Lunch', 'Dinner').required()
});

exports.kioskMarkDailySchema = Joi.object({
  mealType: Joi.string().valid('Lunch', 'Dinner').required()
});

// Leave schemas
exports.leaveSchema = Joi.object({
  startDate: Joi.date().iso().greater('now').required(),
  endDate: Joi.date().iso().required().custom((value, helpers) => {
    const startDate = helpers.state.ancestors[0].startDate;
    if (value < startDate) {
      return helpers.error('any.invalid');
    }
    // Check if both dates are in the same month and year
    const start = new Date(startDate);
    const end = new Date(value);
    if (start.getMonth() !== end.getMonth() || start.getFullYear() !== end.getFullYear()) {
      return helpers.error('date.sameMonth');
    }
    return value;
  }).messages({
    'date.sameMonth': 'End date must be in the same month as start date'
  })
});

// Menu schemas
exports.menuSchema = Joi.object({
  date: Joi.date().iso().required(),
  lunchItems: Joi.array().items(Joi.string().trim().min(1)).min(1).optional(),
  dinnerItems: Joi.array().items(Joi.string().trim().min(1)).min(1).optional()
});

// Review schemas
exports.reviewSchema = Joi.object({
  rating: Joi.number().integer().min(1).max(5).required(),
  comment: Joi.string().trim().min(5).max(500).optional()
});
