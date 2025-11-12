// utils/billCalculation.js

// Timezone offset in minutes (default IST: +5:30 = 330). Can be overridden via env.
const DEFAULT_TZ_OFFSET_MIN = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

// Convert a Date to “local clock” minutes since midnight for a fixed offset.
// Works consistently across servers regardless of host timezone.
const getLocalMinutes = (now = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  const norm = ((offsetMin % 1440) + 1440) % 1440;
  return (utcMin + norm) % 1440;
};

// Start/end of day using offset timezone (inclusive range).
const startOfDay = (date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const d = new Date(date);
  const utc = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
  // Shift to local midnight by subtracting offset from UTC midnight
  return new Date(utc - offsetMin * 60 * 1000);
};

const endOfDay = (date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const s = startOfDay(date, offsetMin);
  return new Date(s.getTime() + 24 * 60 * 60 * 1000 - 1);
};

// Start/end of a calendar month (1..12) in offset timezone (inclusive).
const getStartAndEndOfMonth = (month, year, offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  // month is 1..12
  const m0 = month - 1;
  // Start: first day local midnight => convert by subtracting offset from UTC midnight
  const startUTC = Date.UTC(year, m0, 1);
  const startOfMonth = new Date(startUTC - offsetMin * 60 * 1000);
  // End: day 0 of next month is last day of current month
  const endUTC = Date.UTC(year, m0 + 1, 1) - 1;
  const endOfMonth = new Date(endUTC - offsetMin * 60 * 1000 + offsetMin * 60 * 1000); // cancel previous shift then apply inclusive
  return { startOfMonth, endOfMonth };
};

// Days difference inclusive between two dates (00:00 to 23:59:59.999 boundaries respected).
const calculateDaysDifference = (startDate, endDate) => {
  const s = new Date(startDate);
  const e = new Date(endDate);
  const dayMs = 24 * 60 * 60 * 1000;
  return Math.max(0, Math.floor((stripTime(e) - stripTime(s)) / dayMs) + 1);
};

const stripTime = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

// Check whether the current local time is within or past a configured meal window.
// timings example per mess:
// { lunch: { start: '12:00', end: '14:00' }, dinner: { start: '20:00', end: '22:00' } }
const checkMealTiming = (timings, mealType, offsetMin = DEFAULT_TZ_OFFSET_MIN, now = new Date()) => {
  const t = timings || {};
  const key = String(mealType || '').toLowerCase() === 'lunch' ? 'lunch' : 'dinner';
  const slot = t[key] || {};
  const parseHM = (s) => {
    if (!s || typeof s !== 'string') return null;
    const [hh, mm] = s.split(':').map((x) => parseInt(x, 10));
    if (Number.isNaN(hh) || Number.isNaN(mm)) return null;
    return (hh % 24) * 60 + (mm % 60);
  };
  const startMin = parseHM(slot.start);
  const endMin = parseHM(slot.end);
  const nowMin = getLocalMinutes(now, offsetMin);

  const hasWindow = Number.isInteger(startMin) && Number.isInteger(endMin);
  const isWithin =
    hasWindow && (nowMin >= startMin && nowMin <= endMin);
  const isPast = hasWindow && nowMin > endMin;

  return { hasWindow, isWithin, isPast, startMin, endMin, nowMin };
};

// Compute the member’s active window within a billing month,
// given optional membership.startDate and membership.endDate.
const getActiveWindowForMonth = (membership, startOfMonth, endOfMonth) => {
  const memberStart = membership?.startDate ? new Date(membership.startDate) : startOfMonth;
  const memberEnd = membership?.endDate ? new Date(membership.endDate) : endOfMonth;

  const activeStart = memberStart > startOfMonth ? memberStart : startOfMonth;
  const activeEnd = memberEnd < endOfMonth ? memberEnd : endOfMonth;

  if (activeEnd < activeStart) {
    return { activeStart: null, activeEnd: null, activeDays: 0, monthDays: calculateDaysDifference(startOfMonth, endOfMonth) };
  }

  const activeDays = calculateDaysDifference(activeStart, activeEnd);
  const monthDays = calculateDaysDifference(startOfMonth, endOfMonth);
  return { activeStart, activeEnd, activeDays, monthDays };
};

// Helper: meals included per plan name
const getMealsFromPlan = (planName) => {
  const p = String(planName || '').toLowerCase();
  if (p.includes('both')) return ['Lunch', 'Dinner'];
  if (p.includes('lunch')) return ['Lunch'];
  if (p.includes('dinner')) return ['Dinner'];
  return [];
};

module.exports = {
  DEFAULT_TZ_OFFSET_MIN,
  getLocalMinutes,
  startOfDay,
  endOfDay,
  getStartAndEndOfMonth,
  calculateDaysDifference,
  checkMealTiming,
  getActiveWindowForMonth,
  getMealsFromPlan
};
