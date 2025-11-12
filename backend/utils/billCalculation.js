// utils/billCalculation.js
// NOTE: Exported function names stay the same to avoid breaking imports.

const DEFAULT_TZ_OFFSET_MIN = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

// Internal: minutes since local midnight for a fixed offset from UTC
const getLocalMinutes = (now = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  const norm = ((offsetMin % 1440) + 1440) % 1440;
  return (utcMin + norm) % 1440;
};

// Exported: startOfDay/endOfDay using offset timezone (inclusive range)
function startOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const d = new Date(date);
  // Construct UTC midnight of the given day, then shift by offset to get “local” midnight in UTC
  const utcMidnight = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
  return new Date(utcMidnight - offsetMin * 60 * 1000);
}

function endOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const s = startOfDay(date, offsetMin);
  return new Date(s.getTime() + 24 * 60 * 60 * 1000 - 1);
}

// Exported: getStartAndEndOfDay (wrapper preserved)
function getStartAndEndOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  return { startOfDay: startOfDay(date, offsetMin), endOfDay: endOfDay(date, offsetMin) };
}

// Internal: inclusive date diff by whole days
const stripTime = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
function daysInclusive(a, b) {
  const dayMs = 24 * 60 * 60 * 1000;
  return Math.max(0, Math.floor((stripTime(b) - stripTime(a)) / dayMs) + 1);
}

// Exported: getStartAndEndOfMonth (1..12), inclusive in offset timezone
function getStartAndEndOfMonth(month, year, offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  // month is 1..12
  const m0 = month - 1;
  // Local month start in UTC: first day UTC midnight shifted by offset
  const startUTC = Date.UTC(year, m0, 1);
  const startOfMonth = new Date(startUTC - offsetMin * 60 * 1000);

  // Local month end: last local millisecond of the last day
  const nextMonthUTC = Date.UTC(year, m0 + 1, 1);
  // Last UTC millisecond of month:
  const lastUtcMs = nextMonthUTC - 1;
  // Convert to local by subtracting offset on the start, but the “inclusive” last ms is universal
  const endOfMonth = new Date(lastUtcMs - offsetMin * 60 * 1000 + offsetMin * 60 * 1000);

  return { startOfMonth, endOfMonth };
}

// Exported: calculateDaysDifference (kept signature and behavior: inclusive)
function calculateDaysDifference(startDate, endDate) {
  const s = new Date(startDate);
  const e = new Date(endDate);
  return daysInclusive(s, e);
}

// Exported: checkMealTiming (kept signature and behavior, improved robustness)
// timings example: { lunch: { start: '12:00', end: '14:00' }, dinner: { start: '20:00', end: '22:00' } }
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

// Optional internal helpers your jobs may use without changing imports:

// Compute the active window of a membership within a billing month for proration
function getActiveWindowForMonth(membership, startOfMonth, endOfMonth) {
  const memberStart = membership?.startDate ? new Date(membership.startDate) : startOfMonth;
  const memberEnd = membership?.endDate ? new Date(membership.endDate) : endOfMonth;

  const activeStart = memberStart > startOfMonth ? memberStart : startOfMonth;
  const activeEnd = memberEnd < endOfMonth ? memberEnd : endOfMonth;

  if (activeEnd < activeStart) {
    return { activeStart: null, activeEnd: null, activeDays: 0, monthDays: daysInclusive(startOfMonth, endOfMonth) };
  }
  return {
    activeStart,
    activeEnd,
    activeDays: daysInclusive(activeStart, activeEnd),
    monthDays: daysInclusive(startOfMonth, endOfMonth),
  };
}

// Derive meals covered by a plan (kept here to avoid renames elsewhere)
function getMealsFromPlan(planName) {
  const p = String(planName || '').toLowerCase();
  if (p.includes('both')) return ['Lunch', 'Dinner'];
  if (p.includes('lunch')) return ['Lunch'];
  if (p.includes('dinner')) return ['Dinner'];
  return [];
}

// Keep original exports intact
module.exports = {
  checkMealTiming,
  getStartAndEndOfDay,
  getStartAndEndOfMonth,
  startOfDay,
  endOfDay,

  // Also export helpers already referenced elsewhere in your codebase
  calculateDaysDifference,

  // Non-breaking additional helpers (safe to import where needed)
  getActiveWindowForMonth,
  getMealsFromPlan,

  // Expose default offset for reference
  DEFAULT_TZ_OFFSET_MIN,
};
