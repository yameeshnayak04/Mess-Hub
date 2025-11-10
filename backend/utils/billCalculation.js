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
// utils/billCalculation.js (replace checkMealTiming with this version and add helpers)

// Default to IST (+5:30 = 330 minutes); override per env if needed
const DEFAULT_TZ_OFFSET_MIN = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

// Get “local” minutes since midnight using UTC clock + offset, stable across servers
const getLocalMinutes = (now = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  const norm = ((offsetMin % 1440) + 1440) % 1440; // normalize offset
  return (utcMin + norm) % 1440;
};

const parseHHMM = (str) => {
  const [h, m] = String(str || '').split(':');
  const hh = parseInt(h, 10);
  const mm = parseInt(m, 10);
  if (Number.isNaN(hh) || Number.isNaN(mm)) return null;
  return hh * 60 + mm;
};

// Check if minutes-within-window, supporting windows that wrap past midnight
const inWindow = (min, start, end) => {
  if (start == null || end == null) return false;
  return start <= end ? (min >= start && min <= end) : (min >= start || min <= end);
};

// For a specific window, determine if current time is past its end (wrap-aware)
const isWindowPast = (min, start, end) => {
  if (start == null || end == null) return false;
  return start <= end ? (min > end) : (min > end && min < start);
};

/**
 * Timezone-aware meal timing check
 * @param {Object} timings { lunch: {start:'HH:MM', end:'HH:MM'}, dinner: {...} }
 * @param {('Lunch'|'Dinner'|null)} mealType
 * @param {number} tzOffsetMin minutes offset from UTC (default from env)
 * @returns {{ isWithin: boolean, isPast: boolean, currentMeal: string, liveStatus: string }}
 */
exports.checkMealTiming = (timings, mealType = null, tzOffsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const nowMin = getLocalMinutes(new Date(), tzOffsetMin);

  const Ls = parseHHMM(timings?.lunch?.start);
  const Le = parseHHMM(timings?.lunch?.end);
  const Ds = parseHHMM(timings?.dinner?.start);
  const De = parseHHMM(timings?.dinner?.end);

  const lunchNow = inWindow(nowMin, Ls, Le);
  const dinnerNow = inWindow(nowMin, Ds, De);

  let currentMeal = 'None';
  let liveStatus = 'Service Closed';
  if (lunchNow) { currentMeal = 'Lunch'; liveStatus = 'Lunch Ongoing'; }
  else if (dinnerNow) { currentMeal = 'Dinner'; liveStatus = 'Dinner Ongoing'; }

  if (mealType === 'Lunch') {
    return {
      isWithin: lunchNow,
      isPast: isWindowPast(nowMin, Ls, Le),
      currentMeal,
      liveStatus
    };
  } else if (mealType === 'Dinner') {
    return {
      isWithin: dinnerNow,
      isPast: isWindowPast(nowMin, Ds, De),
      currentMeal,
      liveStatus
    };
  }

  // Generic summary
  return {
    isWithin: lunchNow || dinnerNow,
    isPast: false,
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
