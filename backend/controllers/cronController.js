// new_backend/controllers/cronController.js
const crypto = require('crypto');
const { loadConfig } = require('../utils/config');
const { markAbsencesForClosedMeals } = require('../jobs/absenceJob');
const { generateMonthlyBills } = require('../jobs/billingJob');
const { AppError } = require('../errors/AppError');

const config = loadConfig();

// These endpoints are called by an external scheduler, so they are guarded by
// a shared secret rather than a user login.
//
// The comparison uses timingSafeEqual rather than `===`. A normal string
// comparison bails out at the first character that differs, so how long it
// takes leaks how much of the secret was correct - given enough attempts that
// is enough to guess it one character at a time.
function verifyCronSecret(req, _res, next) {
  const provided = req.get('x-cron-secret') || '';

  if (!config.cronSecret) {
    return next(
      new AppError('Cron endpoints are disabled (CRON_SECRET not set)', 503, 'CRON_DISABLED')
    );
  }

  const providedBuffer = Buffer.from(provided);
  const expectedBuffer = Buffer.from(config.cronSecret);

  // timingSafeEqual throws if the two buffers differ in length, so check that
  // separately first.
  const matches =
    providedBuffer.length === expectedBuffer.length &&
    crypto.timingSafeEqual(providedBuffer, expectedBuffer);

  if (!matches) {
    return next(new AppError('Invalid cron secret', 401, 'UNAUTHENTICATED'));
  }
  return next();
}

async function runAbsenceJob(_req, res) {
  const result = await markAbsencesForClosedMeals();
  res.json({ success: true, data: result });
}

async function runBillingJob(req, res) {
  const result = await generateMonthlyBills({ periodStart: req.body?.periodStart });
  res.json({ success: true, data: result });
}

module.exports = { verifyCronSecret, runAbsenceJob, runBillingJob };
