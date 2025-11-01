/**
 * Calculate the number of days in a date range
 * @param {Date} startDate 
 * @param {Date} endDate 
 * @returns {Number} Number of days
 */
exports.calculateDaysDifference = (startDate, endDate) => {
  const start = new Date(startDate);
  const end = new Date(endDate);
  const diffTime = Math.abs(end - start);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1; // +1 to include both start and end date
  return diffDays;
};

/**
 * Check if current time is within meal timing
 * @param {Object} timings - Meal timings from Mess
 * @param {String} mealType - 'Lunch' or 'Dinner'
 * @returns {Object} { isWithin: Boolean, isPast: Boolean, currentMeal: String, liveStatus: String }
 */
exports.checkMealTiming = (timings, mealType = null) => {
  const now = new Date();
  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();
  const currentTimeInMinutes = currentHour * 60 + currentMinute;

  const parseLunchStart = timings.lunch.start.split(':');
  const lunchStartMinutes = parseInt(parseLunchStart[0]) * 60 + parseInt(parseLunchStart[1]);
  
  const parseLunchEnd = timings.lunch.end.split(':');
  const lunchEndMinutes = parseInt(parseLunchEnd[0]) * 60 + parseInt(parseLunchEnd[1]);

  const parseDinnerStart = timings.dinner.start.split(':');
  const dinnerStartMinutes = parseInt(parseDinnerStart[0]) * 60 + parseInt(parseDinnerStart[1]);
  
  const parseDinnerEnd = timings.dinner.end.split(':');
  const dinnerEndMinutes = parseInt(parseDinnerEnd[0]) * 60 + parseInt(parseDinnerEnd[1]);

  let currentMeal = 'None';
  let liveStatus = 'Service Closed';
  let isWithin = false;
  let isPast = false;

  // Check if currently in lunch time
  if (currentTimeInMinutes >= lunchStartMinutes && currentTimeInMinutes <= lunchEndMinutes) {
    currentMeal = 'Lunch';
    liveStatus = 'Lunch Ongoing';
    isWithin = true;
  }
  // Check if currently in dinner time
  else if (currentTimeInMinutes >= dinnerStartMinutes && currentTimeInMinutes <= dinnerEndMinutes) {
    currentMeal = 'Dinner';
    liveStatus = 'Dinner Ongoing';
    isWithin = true;
  }

  // If mealType is specified, check specifically for that meal
  if (mealType) {
    if (mealType === 'Lunch') {
      return {
        isWithin: currentTimeInMinutes >= lunchStartMinutes && currentTimeInMinutes <= lunchEndMinutes,
        isPast: currentTimeInMinutes > lunchEndMinutes,
        currentMeal,
        liveStatus
      };
    } else if (mealType === 'Dinner') {
      return {
        isWithin: currentTimeInMinutes >= dinnerStartMinutes && currentTimeInMinutes <= dinnerEndMinutes,
        isPast: currentTimeInMinutes > dinnerEndMinutes,
        currentMeal,
        liveStatus
      };
    }
  }

  // Return general status if no specific mealType was requested
  return {
    isWithin, // Is any meal active right now?
    isPast, // This is not well-defined without a mealType, defaults to false
    currentMeal,
    liveStatus
  };
};

/**
 * Get start and end of day
 * @param {Date} date 
 * @returns {Object} { startOfDay, endOfDay }
 */
const getStartAndEndOfDay = (date = new Date()) => {
  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);

  return { startOfDay, endOfDay };
};
exports.getStartAndEndOfDay = getStartAndEndOfDay;

// ADDING CONSOLIDATED FUNCTIONS
exports.startOfDay = (d = new Date()) => { const x = new Date(d); x.setHours(0,0,0,0); return x; };
exports.endOfDay   = (d = new Date()) => { const x = new Date(d); x.setHours(23,59,59,999); return x; };


/**
 * Get start and end of month
 * @param {Number} month 
 * @param {Number} year 
 * @returns {Object} { startOfMonth, endOfMonth }
 */
exports.getStartAndEndOfMonth = (month, year) => {
  const startOfMonth = new Date(year, month - 1, 1, 0, 0, 0, 0);
  const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);

  return { startOfMonth, endOfMonth };
};
