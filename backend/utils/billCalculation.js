// utils/billCalculation.js
// All exported function names/signatures are unchanged to maintain compatibility across controllers, jobs, and routes.

const DEFAULT_TZ_OFFSET_MIN = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10); // IST by default

// Internal: normalize offset into [0, 1439] minutes
const normOffset = (min) => ((min % 1440) + 1440) % 1440;

// Internal: minutes since local (offset) midnight from a Date
const getLocalMinutes = (now = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  return (utcMin + normOffset(offsetMin)) % 1440;
};

// Exported: startOfDay/endOfDay — compute the local (IST) day bounds as UTC instants.
// These return Date objects that represent the exact start and end instants of the given local day.
function startOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const d = new Date(date);
  // 1) Construct the UTC midnight for the calendar day of 'd'
  const utcMidnight = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
  // 2) Shift that instant backward by the offset to get the local midnight as a UTC instant
  return new Date(utcMidnight - offsetMin * 60 * 1000);
}

function endOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const s = startOfDay(date, offsetMin);
  return new Date(s.getTime() + 24 * 60 * 60 * 1000 - 1);
}

// Exported: getStartAndEndOfDay — wrapper returning { startOfDay, endOfDay } with same naming
function getStartAndEndOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  return { startOfDay: startOfDay(date, offsetMin), endOfDay: endOfDay(date, offsetMin) };
}

// Internal: strip time for inclusive day arithmetic
const stripTime = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const dayMs = 24 * 60 * 60 * 1000;

// Exported: calculateDaysDifference — inclusive whole-day count
function calculateDaysDifference(startDate, endDate) {
  const s = stripTime(new Date(startDate));
  const e = stripTime(new Date(endDate));
  if (e < s) return 0;
  return Math.floor((e - s) / dayMs) + 1;
}

// Exported: getStartAndEndOfMonth — inclusive local (IST) month bounds as UTC instants.
// month is 1..12; returns Dates suitable for querying with $gte/$lte on UTC timestamps.
function getStartAndEndOfMonth(month, year, offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const m0 = month - 1;
  // Local first-of-month midnight as a UTC instant
  const startUTC = Date.UTC(year, m0, 1);
  const startOfMonth = new Date(startUTC - offsetMin * 60 * 1000);

  // Local last millisecond of month:
  // Take local first-of-next-month midnight and subtract 1 millisecond.
  const nextMonthUTC = Date.UTC(year, m0 + 1, 1);
  const startOfNextLocal = new Date(nextMonthUTC - offsetMin * 60 * 1000);
  const endOfMonth = new Date(startOfNextLocal.getTime() - 1);

  return { startOfMonth, endOfMonth };
}

// Exported: checkMealTiming — evaluates HH:MM windows in IST (or configured offset).
// timings: { lunch: { start: '12:00', end: '14:00' }, dinner: { start: '20:00', end: '22:00' } }
function checkMealTiming(timings, mealType, offsetMin = DEFAULT_TZ_OFFSET_MIN, now = new Date()) {
  const t = timings || {};
  const key = String(mealType || '').toLowerCase() === 'lunch' ? 'lunch' : 'dinner';
  const slot = t[key] || {};

  const parseHM = (s) => {
    if (!s || typeof s !== 'string') return null;
    const parts = s.split(':');
    if (parts.length < 2) return null;
    const hh = parseInt(parts[0], 10);
    const mm = parseInt(parts[1], 10);
    if (Number.isNaN(hh) || Number.isNaN(mm)) return null;
    return (hh % 24) * 60 + (mm % 60);
  };

  const startMin = parseHM(slot.start);
  const endMin = parseHM(slot.end);
  const localNow = getLocalMinutes(now, offsetMin);

  const hasWindow = Number.isInteger(startMin) && Number.isInteger(endMin);
  const isWithin = hasWindow && localNow >= startMin && localNow <= endMin;
  const isPast = hasWindow && localNow > endMin;

  return { hasWindow, isWithin, isPast, startMin, endMin, nowMin: localNow };
}

// Compatible helpers already referenced in code (names preserved)

// Limit a membership’s active window to the billing month for proration.
function getActiveWindowForMonth(membership, startOfMonth, endOfMonth) {
  const memberStart = membership?.startDate ? new Date(membership.startDate) : startOfMonth;
  const memberEnd = membership?.endDate ? new Date(membership.endDate) : endOfMonth;

  const activeStart = memberStart > startOfMonth ? memberStart : startOfMonth;
  const activeEnd = memberEnd < endOfMonth ? memberEnd : endOfMonth;

  if (activeEnd < activeStart) {
    return { activeStart: null, activeEnd: null, activeDays: 0, monthDays: calculateDaysDifference(startOfMonth, endOfMonth) };
  }
  return {
    activeStart,
    activeEnd,
    activeDays: calculateDaysDifference(activeStart, activeEnd),
    monthDays: calculateDaysDifference(startOfMonth, endOfMonth),
  };
}

// Meals covered by a plan string
function getMealsFromPlan(planName) {
  const p = String(planName || '').toLowerCase();
  if (p.includes('both')) return ['Lunch', 'Dinner'];
  if (p.includes('lunch')) return ['Lunch'];
  if (p.includes('dinner')) return ['Dinner'];
  return [];
}

module.exports = {
  // Original exports (unchanged names)
  checkMealTiming,
  getStartAndEndOfDay,
  getStartAndEndOfMonth,
  startOfDay,
  endOfDay,
  calculateDaysDifference,

  // Also exported previously/used elsewhere
  getActiveWindowForMonth,
  getMealsFromPlan,

  // Expose default offset for consumers that need it
  DEFAULT_TZ_OFFSET_MIN,
};
