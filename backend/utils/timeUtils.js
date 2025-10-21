// backend/utils/timeUtils.js

// This file contains helper functions for handling time-based logic.

/**
 * Creates a Date object for today with a specific time (e.g., "14:30").
 * @param {string} timeString - The time in "HH:MM" format.
 * @returns {Date} A Date object representing today at the specified time.
 */
const getDateWithSpecificTime = (timeString) => {
    const [hours, minutes] = timeString.split(':').map(Number);
    const date = new Date(); // Gets today's date and current time
    date.setHours(hours, minutes, 0, 0); // Sets the time to the specified HH:MM, with seconds and ms to 0
    return date;
};

/**
 * Gets the start and end of the current day.
 * @returns {{startOfDay: Date, endOfDay: Date}}
 */
const getTodayDateRange = () => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);
    return { startOfDay, endOfDay };
};

module.exports = {
    getDateWithSpecificTime,
    getTodayDateRange,
};