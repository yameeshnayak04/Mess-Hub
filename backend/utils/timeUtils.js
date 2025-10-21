// utils/timeUtils.js

// Normalize any date to start of its local day
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

// Backward-compatible
const getDateWithSpecificTime = (timeString) => {
  const [hours, minutes] = timeString.split(':').map(Number);
  const date = new Date();
  date.setHours(hours, minutes, 0, 0);
  return date;
};

// Minimal stub to avoid timezone bugs in controllers
const getTodayInMessTimezone = () => normalizeToStartOfDay(new Date());

// Compute ISO week identifier "YYYY-Www"
const getISOWeekIdentifier = (date = new Date()) => {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNo).padStart(2, '0')}`;
};

// Build a Date for the meal's end time on a target day
const getMealEndDateTime = (mess, mealType, targetDate) => {
  const time = mealType === 'Lunch' ? mess.timings?.lunch?.end : mess.timings?.dinner?.end;
  if (!time) return null;
  const [h, m] = time.split(':').map(Number);
  const d = new Date(targetDate);
  d.setHours(h, m, 0, 0);
  return d;
};

// Decide current meal by comparing now to timings; default Lunch before dinner end
const getCurrentMealType = (mess, now = new Date()) => {
  const lunchEnd = mess?.timings?.lunch?.end;
  const dinnerEnd = mess?.timings?.dinner?.end;
  if (!lunchEnd && !dinnerEnd) return 'Lunch';
  if (lunchEnd) {
    const [lh, lm] = lunchEnd.split(':').map(Number);
    const lunchEndDate = new Date(now);
    lunchEndDate.setHours(lh, lm, 0, 0);
    if (now <= lunchEndDate) return 'Lunch';
  }
  return 'Dinner';
};

module.exports = {
  normalizeToStartOfDay,
  getDateWithSpecificTime,
  getTodayDateRange,
  getTodayInMessTimezone,
  getISOWeekIdentifier,
  getMealEndDateTime,
  getCurrentMealType,
};
