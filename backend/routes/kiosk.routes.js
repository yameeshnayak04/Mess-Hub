// This file defines the API routes for the on-premise Kiosk.

const express = require('express');
const router = express.Router();

// Import controller functions.
const {
    getActiveMembers,
    logMonthlyMeal,
    logDailyMeal,
    managerOverride, // <-- The new override route
} = require('../controllers/kiosk.controller.js');

// --- KIOSK ROUTES (Public but should be IP-restricted in production) ---

// Kiosk fetches the list of active members to display on the grid.
router.get('/messes/:messId/active-members', getActiveMembers);

// Kiosk logs a meal for a monthly member after PIN verification.
router.post('/messes/:messId/log-monthly', logMonthlyMeal);

// Kiosk logs a meal for a pay-per-meal daily user.
router.post('/messes/:messId/log-daily', logDailyMeal);

// Manager uses their own PIN to override and log a meal for a user.
router.post('/messes/:messId/manager-override', managerOverride);


module.exports = router;