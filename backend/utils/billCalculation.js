// utils/billCalculation.js
// Exported names unchanged: checkMealTiming, getStartAndEndOfDay, getStartAndEndOfMonth, startOfDay, endOfDay, calculateDaysDifference.

const DEFAULT_TZ_OFFSET_MIN = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

// Internal: minutes since local midnight at a fixed offset (IST by default)
const getLocalMinutes = (now = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  const norm = ((offsetMin % 1440) + 1440) % 1440;
  return (utcMin + norm) % 1440;
};

// IST start/end of day (inclusive) without changing function names
function startOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const d = new Date(date);
  // Compute local midnight by taking the UTC date components and shifting by offset
  const utcMidnight = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
  return new Date(utcMidnight - offsetMin * 60 * 1000);
}

function endOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const s = startOfDay(date, offsetMin);
  return new Date(s.getTime() + 24 * 60 * 60 * 1000 - 1);
}

function getStartAndEndOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  return { startOfDay: startOfDay(date, offsetMin), endOfDay: endOfDay(date, offsetMin) };
}

// Helpers for inclusive day arithmetic
const stripTime = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
function daysInclusive(a, b) {
  const dayMs = 24 * 60 * 60 * 1000;
  return Math.max(0, Math.floor((stripTime(b) - stripTime(a)) / dayMs) + 1);
}

// IST month boundaries (inclusive) using the same function name
function getStartAndEndOfMonth(month, year, offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  // month is 1..12
  const m0 = month - 1;
  // Local first-of-month midnight
  const startUTC = Date.UTC(year, m0, 1);
  const startOfMonth = new Date(startUTC - offsetMin * 60 * 1000);

  // Local last millisecond of month
  const nextMonthUTC = Date.UTC(year, m0 + 1, 1);
  const endOfMonth = new Date(nextMonthUTC - 1); // already the last ms; IST consumers read via offset-aware functions

  return { startOfMonth, endOfMonth };
}

// Same exported name; inclusive day count
function calculateDaysDifference(startDate, endDate) {
  const s = new Date(startDate);
  const e = new Date(endDate);
  return daysInclusive(s, e);
}

// Same exported name; meal windows evaluated in IST by default
function checkMealTiming(timings, mealType, offsetMin = DEFAULT_TZ_OFFSET_MIN, now = new Date()) {
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
  const isWithin = hasWindow && nowMin >= startMin && nowMin <= endMin;
  const isPast = hasWindow && nowMin > endMin;

  return { hasWindow, isWithin, isPast, startMin, endMin, nowMin };
}

// Additional helpers (names preserved where referenced elsewhere)
function getActiveWindowForMonth(membership, startOfMonth, endOfMonth) {
  const memberStart = membership?.startDate ? new Date(membership.startDate) : startOfMonth;
  const memberEnd = membership?.endDate ? new Date(membership.endDate) : endOfMonth;
  const activeStart = memberStart > startOfMonth ? memberStart : startOfMonth;
  const activeEnd = memberEnd < endOfMonth ? memberEnd : endOfMonth;
  if (activeEnd < activeStart) {
    return { activeStart: null, activeEnd: null, activeDays: 0, monthDays: daysInclusive(startOfMonth, endOfMonth) };
  }
  return { activeStart, activeEnd, activeDays: daysInclusive(activeStart, activeEnd), monthDays: daysInclusive(startOfMonth, endOfMonth) };
}

function getMealsFromPlan(planName) {
  const p = String(planName || '').toLowerCase();
  if (p.includes('both')) return ['Lunch', 'Dinner'];
  if (p.includes('lunch')) return ['Lunch'];
  if (p.includes('dinner')) return ['Dinner'];
  return [];
}

module.exports = {
  checkMealTiming,
  getStartAndEndOfDay,
  getStartAndEndOfMonth,
  startOfDay,
  endOfDay,
  calculateDaysDifference,
  getActiveWindowForMonth,
  getMealsFromPlan,
  DEFAULT_TZ_OFFSET_MIN,
};
