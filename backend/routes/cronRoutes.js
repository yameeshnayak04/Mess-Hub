// backend/routes/cronRoutes.js
const router = require('express').Router();

// Import job entry points (ensure these are exported in the job files)
const { generateBillsForPreviousMonth } = require('../jobs/billingJob.js');
const { markAbsentForMeal } = require('../jobs/absentJob.js');

// Simple header-based protection
router.use((req, res, next) => {
  const key = req.header('x-cron-secret');
  if (!key || key !== process.env.CRON_SECRET) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
});

// Run absence marking for both meals
router.post('/absent/run', async (req, res, next) => {
  try {
    await markAbsentForMeal('Lunch');
    await markAbsentForMeal('Dinner');
    res.json({ success: true, message: 'Absent job executed for Lunch & Dinner' });
  } catch (e) {
    next(e);
  }
});

// Run monthly billing
router.post('/billing/run', async (req, res, next) => {
  try {
    await generateBillsForPreviousMonth();
    res.json({ success: true, message: 'Monthly billing job executed' });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
