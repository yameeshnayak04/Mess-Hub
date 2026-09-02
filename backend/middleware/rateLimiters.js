// new_backend/middleware/rateLimiters.js
const rateLimit = require('express-rate-limit');
const { ipKeyGenerator } = require('express-rate-limit');

// Any custom key built from an IP has to go through ipKeyGenerator first. It
// collapses an IPv6 address down to its /56 subnet; using the raw address
// would let one client walk through thousands of addresses in its own subnet
// and get a fresh allowance each time, which is a limiter that does nothing.
function ipPart(req) {
  return ipKeyGenerator(req.ip);
}

// Login is the obvious brute-force target, so we cap attempts per phone
// number + IP combination rather than per IP alone (otherwise everyone
// sharing a college wifi would lock each other out).
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `${ipPart(req)}:${req.body?.phone || 'unknown'}`,
  message: {
    success: false,
    code: 'TOO_MANY_REQUESTS',
    message: 'Too many login attempts. Please wait a few minutes and try again.',
  },
});

// The kiosk PIN is only 4 digits - just 10,000 possibilities. Without a limit
// someone could stand at the kiosk and try them all. This makes that
// impractical while staying generous enough for real mealtime queues.
const kioskLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `${ipPart(req)}:${req.body?.membershipId || 'unknown'}`,
  message: {
    success: false,
    code: 'TOO_MANY_REQUESTS',
    message: 'Too many PIN attempts for this member. Please wait a few minutes.',
  },
});

module.exports = { loginLimiter, kioskLimiter };
