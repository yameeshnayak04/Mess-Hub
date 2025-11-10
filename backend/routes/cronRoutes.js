// routes/cronRoutes.js
const router = require('express').Router();
const { markAbsentForMeal } = require('../jobs/absentJob');
const { generateBillsForPreviousMonth } = require('../jobs/billingJob');

// simple header-protected middleware
router.use((req, res, next) => {
  const key = req.header('x-cron-secret');
  if (!key || key !== process.env.CRON_SECRET) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
});

// Trigger both meals’ absence check (idempotent)
router.post('/absent/run', async (req, res) => {
  await markAbsentForMeal('Lunch');
  await markAbsentForMeal('Dinner');
  return res.json({ success: true, message: 'Absent job executed for Lunch & Dinner' });
});

// Trigger monthly billing for previous month
router.post('/billing/run', async (req, res) => {
  await generateBillsForPreviousMonth();
  return res.json({ success: true, message: 'Monthly billing job executed' });
});

module.exports = router;
