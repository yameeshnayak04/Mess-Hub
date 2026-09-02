// new_backend/routes/index.js
//
// Mounts every area of the API. One file per area, matching the controllers,
// so you can jump straight to the routes for whatever you are working on.
//
// Inside each file the chain on a route reads left to right as: who may call
// it, what shape the input must be, then the controller. Anything a route does
// not list simply is not applied - there are no hidden checks inside
// controllers.

const express = require('express');

const router = express.Router();

router.use('/auth', require('./authRoutes'));

// planRoutes is mounted on the same path as messRoutes and must come first:
// it claims '/my-mess/plans' and '/:messId/plans' before messRoutes' generic
// '/:messId' route can match them.
router.use('/messes', require('./planRoutes'));
router.use('/messes', require('./messRoutes'));

router.use('/memberships', require('./membershipRoutes'));
router.use('/attendance', require('./attendanceRoutes'));
router.use('/leave', require('./leaveRoutes'));
router.use('/billing', require('./billingRoutes'));
router.use('/reviews', require('./reviewRoutes'));
router.use('/menus', require('./menuRoutes'));
router.use('/cron', require('./cronRoutes'));

module.exports = router;
