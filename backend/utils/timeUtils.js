// utils/timeUtils.js

// Normalize any date to start of local day
const normalizeToStartOfDay = (date = new Date()) => {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
};

const getTodayDateRange = () => {
  const startOfDay = normalizeToStartOfDay(new Date());
  const endOfDay = new Date(startOfDay);
  endOfDay.setHours(23, 59, 59, 999);
  return { startOfDay, endOfDay };
};

const parseHHmmOn = (date, hhmm) => {
  if (!hhmm) return null;
  const [h, m] = hhmm.split(':').map(Number);
  const d = new Date(date);
  d.setHours(h || 0, m || 0, 0, 0);
  return d;
};

const getTodayInMessTimezone = () => normalizeToStartOfDay(new Date());

// Build a Date for the meal's end time on a target day
const getMealEndDateTime = (mess, mealType, targetDate) => {
  const time = mealType === 'Lunch' ? mess?.timings?.lunch?.end : mess?.timings?.dinner?.end;
  if (!time) return null;
  return parseHHmmOn(targetDate, time);
};

// Decide current meal by comparing now to timings; default Lunch before dinner end
const getCurrentMealType = (mess, now = new Date()) => {
  const lunchEnd = mess?.timings?.lunch?.end;
  const dinnerEnd = mess?.timings?.dinner?.end;
  if (!lunchEnd && !dinnerEnd) return 'Lunch';
  if (lunchEnd) {
    const lunchEndDate = parseHHmmOn(now, lunchEnd);
    if (now <= lunchEndDate) return 'Lunch';
  }
  return 'Dinner';
};

// Month range helper
const getMonthRange = (year, month1to12) => {
  const from = new Date(Date.UTC(year, month1to12 - 1, 1));
  const to = new Date(Date.UTC(year, month1to12, 1));
  return { from, to };
};

module.exports = {
  normalizeToStartOfDay,
  getTodayDateRange,
  parseHHmmOn,
  getTodayInMessTimezone,
  getMealEndDateTime,
  getCurrentMealType,
  getMonthRange,
};
