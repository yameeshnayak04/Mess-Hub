// This file defines the API routes for the on-premise Kiosk.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    getActiveMembers,
    logMonthlyMeal,
    logDailyMeal
} = require('../controllers/kiosk.controller.js');

// --- KIOSK ROUTES ---

// Route for the Kiosk to fetch the list of active members to display on the grid.
router.get('/messes/:messId/active-members', getActiveMembers);

// Route for the Kiosk to log a meal for a monthly member after PIN verification.
router.post('/messes/:messId/log-monthly', logMonthlyMeal);

// Route for the Kiosk to log a meal for a pay-per-meal daily user.
router.post('/messes/:messId/log-daily', logDailyMeal);


module.exports = router;