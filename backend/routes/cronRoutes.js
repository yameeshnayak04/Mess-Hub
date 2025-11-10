// backend/routes/cronRoutes.js
const router = require('express').Router();
const { runBillingJob } = require('../jobs/billingJob.js');
const { runAbsentJob } = require('../jobs/absentJob.js');

router.use((req, res, next) => {
  const key = req.header('x-cron-secret');
  if (!key || key !== process.env.CRON_SECRET) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
});

router.post('/absent/run', async (req, res, next) => {
  try {
    await runAbsentJob();
    res.json({ success: true, message: 'Absent job executed' });
  } catch (e) { next(e); }
});

router.post('/billing/run', async (req, res, next) => {
  try {
    await runBillingJob();
    res.json({ success: true, message: 'Monthly billing job executed' });
  } catch (e) { next(e); }
});

module.exports = router;
