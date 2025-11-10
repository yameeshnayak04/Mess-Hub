const express = require('express');
const { runAbsentJob } = require('../jobs/absentJob');
const { runBillingJob } = require('../jobs/billingJob');

const router = express.Router();

// This is a simple middleware to protect your job endpoints
const checkJobSecret = (req, res, next) => {
  const secret = req.headers['x-job-secret'];
  if (secret && secret === process.env.JOB_SECRET_KEY) {
    next();
  } else {
    res.status(401).json({ success: false, message: 'Unauthorized' });
  }
};

// Route to manually trigger the absent job
router.post('/run-absent', checkJobSecret, async (req, res) => {
  console.log('Absent job triggered via API...');
  try {
    // We run the job but don't wait for it to finish.
    // This avoids a 504 Gateway Timeout on Render.
    runAbsentJob().catch(err => {
      console.error('Error running absent job in background:', err);
    });
    // Immediately send a response
    res.status(202).json({ success: true, message: 'Absent job started.' });
  } catch (error) {
    console.error('Failed to trigger absent job:', error);
    res.status(500).json({ success: false, message: 'Failed to start job.' });
  }
});

// Route to manually trigger the billing job
router.post('/run-billing', checkJobSecret, async (req, res) => {
  console.log('Billing job triggered via API...');
  try {
    // Run in background
    runBillingJob().catch(err => {
      console.error('Error running billing job in background:', err);
    });
    res.status(202).json({ success: true, message: 'Billing job started.' });
  } catch (error) {
    console.error('Failed to trigger billing job:', error);
    res.status(500).json({ success: false, message: 'Failed to start job.' });
  }
});

module.exports = router;