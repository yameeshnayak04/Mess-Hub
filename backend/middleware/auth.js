// new_backend/middleware/auth.js
const jwt = require('jsonwebtoken');
const { loadConfig } = require('../utils/config');
const { AppError, ForbiddenError } = require('../errors/AppError');

const config = loadConfig();

function signToken(user) {
  // The role travels inside the token so `protect` does not need a database
  // query on every single request just to find out who is calling. Trade-off:
  // if an account's role changes, their existing token keeps the old role
  // until it expires. That is acceptable here because roles never change in
  // this product - you are a Customer or a Manager from signup onward.
  return jwt.sign({ id: user.id, role: user.role }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
  });
}

// Verifies the "Authorization: Bearer <token>" header and attaches
// req.user = { id, role }.
function protect(req, _res, next) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    return next(new AppError('You must be logged in to do that', 401, 'UNAUTHENTICATED'));
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    req.user = { id: Number(payload.id), role: payload.role };
    return next();
  } catch {
    return next(new AppError('Your session is invalid or has expired', 401, 'UNAUTHENTICATED'));
  }
}

// Use after `protect`: authorize('Manager') or authorize('Customer').
function authorize(...allowedRoles) {
  return (req, _res, next) => {
    if (!allowedRoles.includes(req.user.role)) {
      return next(
        new ForbiddenError(`This action is only available to: ${allowedRoles.join(', ')}`)
      );
    }
    return next();
  };
}

module.exports = { signToken, protect, authorize };
