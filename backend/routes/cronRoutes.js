// new_backend/routes/cronRoutes.js
//
// Called by an external scheduler rather than by a logged-in user, so these
// are guarded by a shared secret instead of a JWT.
const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const cronController = require('../controllers/cronController');

const router = express.Router();

router.use(cronController.verifyCronSecret);
router.post('/absence', asyncHandler(cronController.runAbsenceJob));
router.post('/billing', asyncHandler(cronController.runBillingJob));

module.exports = router;
