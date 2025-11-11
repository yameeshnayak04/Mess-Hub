// routes/jobsRoutes.js (compatibility)
const router = require('express').Router();
const { runAbsentJob } = require('../jobs/absentJob.js');
const { runBillingJob } = require('../jobs/billingJob.js');

router.use((req, res, next) => {
  const key = req.header('X-Job-Secret');
  if (!key || key !== process.env.CRON_SECRET) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
});

router.post('/run-absent', async (_req, res, next) => {
  try { await runAbsentJob(); res.json({ success: true, message: 'Absent job executed' }); }
  catch (e) { next(e); }
});

router.post('/run-billing', async (_req, res, next) => {
  try { await runBillingJob(); res.json({ success: true, message: 'Billing job executed' }); }
  catch (e) { next(e); }
});

module.exports = router;
