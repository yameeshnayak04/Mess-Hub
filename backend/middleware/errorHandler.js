// new_backend/middleware/errorHandler.js
//
// One place that turns any thrown error into an HTTP response. Because this
// exists, services can just `throw new ValidationError(...)` and never think
// about status codes or response shapes.
const { AppError } = require('../errors/AppError');

// Postgres reports rule violations as numeric error codes. Translating them
// here means a constraint we rely on (rather than an if-statement) still
// produces a friendly message instead of a raw database error.
const POSTGRES_ERRORS = {
  23505: { status: 409, code: 'DUPLICATE', message: 'That record already exists' },
  23503: { status: 400, code: 'INVALID_REFERENCE', message: 'Referenced record does not exist' },
  '23P01': {
    status: 409,
    code: 'OVERLAPPING_PERIOD',
    message: 'That date range overlaps an existing one',
  },
  // Raised when Postgres cannot read a value as the column's type. In practice
  // this means a URL like /messes/abc where an id was expected. That is the
  // caller's mistake, so it must be a 400 - not a 500 that looks like our bug.
  '22P02': { status: 400, code: 'INVALID_INPUT', message: 'One of the values sent is not valid' },
};

function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    code: 'ROUTE_NOT_FOUND',
    message: `No route matches ${req.method} ${req.originalUrl}`,
  });
}

// Express only recognises this as an error handler because it takes four
// arguments - `_next` must stay in the signature even though it is unused.
function errorHandler(error, req, res, _next) {
  // Errors we threw on purpose already know their status and code.
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      code: error.code,
      message: error.message,
    });
  }

  // Our own database triggers (e.g. the minimum-leave-days rule) raise
  // check_violation with a message written for the customer, so pass that
  // message straight through rather than replacing it with something generic.
  if (error.code === '23514') {
    return res.status(400).json({
      success: false,
      code: 'RULE_VIOLATION',
      message: error.message.replace(/^.*?:\s*/, ''),
    });
  }

  const known = POSTGRES_ERRORS[error.code];
  if (known) {
    return res.status(known.status).json({
      success: false,
      code: known.code,
      message: known.message,
    });
  }

  if (error.type === 'entity.parse.failed') {
    return res
      .status(400)
      .json({ success: false, code: 'INVALID_JSON', message: 'Request body is not valid JSON' });
  }

  if (error.code === 'LIMIT_FILE_SIZE') {
    return res
      .status(400)
      .json({ success: false, code: 'FILE_TOO_LARGE', message: 'Image must be 5MB or smaller' });
  }

  // Anything reaching here is a bug. Log the real thing for us, return
  // something safe to the client - internal messages can leak table names.
  console.error('Unhandled error:', error);
  return res.status(500).json({
    success: false,
    code: 'INTERNAL_ERROR',
    message: 'Something went wrong on our side',
  });
}

module.exports = { errorHandler, notFoundHandler };
