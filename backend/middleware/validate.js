// new_backend/middleware/validate.js
const { ValidationError } = require('../errors/AppError');

// Checks req.body against a Joi schema before the controller runs, and
// replaces req.body with the cleaned-up value (unknown fields stripped, types
// coerced). Controllers can then trust their input.
function validateBody(schema) {
  return (req, _res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false, // report every problem at once, not just the first
      stripUnknown: true,
    });

    if (error) {
      const details = error.details.map((detail) => detail.message).join('; ');
      return next(new ValidationError(details));
    }

    req.body = value;
    return next();
  };
}

// Same idea for query strings (filters, pagination).
function validateQuery(schema) {
  return (req, _res, next) => {
    const { error, value } = schema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const details = error.details.map((detail) => detail.message).join('; ');
      return next(new ValidationError(details));
    }

    // Express 5 makes req.query read-only, so stash the cleaned version
    // separately rather than assigning over it.
    req.validatedQuery = value;
    return next();
  };
}

module.exports = { validateBody, validateQuery };
