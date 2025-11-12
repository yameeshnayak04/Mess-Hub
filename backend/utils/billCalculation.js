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

// Exported: startOfDay — compute the local (IST) day start as a UTC instant Date
function startOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const d = new Date(date);
  // Construct the UTC midnight for the calendar day of 'd'
  const utcMidnight = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
  // Shift that instant backward by the offset to get the local midnight as a UTC instant
  return new Date(utcMidnight - offsetMin * 60 * 1000);
}

// Exported: endOfDay — compute the local (IST) day end as a UTC instant Date
function endOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const s = startOfDay(date, offsetMin);
  return new Date(s.getTime() + 24 * 60 * 60 * 1000 - 1);
}

// Exported: getStartAndEndOfDay — wrapper returning { startOfDay, endOfDay } with same naming
function getStartAndEndOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  return { startOfDay: startOfDay(date, offsetMin), endOfDay: endOfDay(date, offsetMin) };
}

// Internal: strip time for inclusive day arithmetic (local calendar, not offset-corrected)
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
  // Local last millisecond of month: local first-of-next-month midnight minus 1 ms
  const nextMonthUTC = Date.UTC(year, m0 + 1, 1);
  const startOfNextLocal = new Date(nextMonthUTC - offsetMin * 60 * 1000);
  const endOfMonth = new Date(startOfNextLocal.getTime() - 1);
  return { startOfMonth, endOfMonth };
}

// Exported: checkMealTiming — evaluates HH:MM windows in IST (or configured offset).
// timings: { lunch: { start: '12:00', end: '14:00' }, dinner: { start: '20:00', end: '22:00' } }
function checkMealTiming(timings, mealType, offsetMin = DEFAULT_TZ_OFFSET_MIN, now = new Date()) {
  const t = timings || {};
  const parseHM = (s) => {
    if (!s || typeof s !== 'string') return null;
    const parts = s.split(':');
    if (parts.length < 2) return null;
    const hh = parseInt(parts[0], 10);
    const mm = parseInt(parts[1], 10);
    if (Number.isNaN(hh) || Number.isNaN(mm)) return null;
    return (hh % 24) * 60 + (mm % 60);
  };

  const lunchSlot = t.lunch || {};
  const dinnerSlot = t.dinner || {};

  const lunchStart = parseHM(lunchSlot.start);
  const lunchEnd = parseHM(lunchSlot.end);
  const dinnerStart = parseHM(dinnerSlot.start);
  const dinnerEnd = parseHM(dinnerSlot.end);

  const localNow = getLocalMinutes(now, offsetMin);

  const lunchHas = Number.isInteger(lunchStart) && Number.isInteger(lunchEnd);
  const dinnerHas = Number.isInteger(dinnerStart) && Number.isInteger(dinnerEnd);

  const lunchWithin = lunchHas && localNow >= lunchStart && localNow <= lunchEnd;
  const dinnerWithin = dinnerHas && localNow >= dinnerStart && localNow <= dinnerEnd;

  // Resolve currentMeal preference: explicit mealType first, else whichever window is active.
  const requested = String(mealType || '').toLowerCase();
  let currentMeal = 'None';
  if (requested === 'lunch' && lunchWithin) currentMeal = 'Lunch';
  else if (requested === 'dinner' && dinnerWithin) currentMeal = 'Dinner';
  else if (lunchWithin) currentMeal = 'Lunch';
  else if (dinnerWithin) currentMeal = 'Dinner';

  const hasWindow = (requested === 'lunch' ? lunchHas : requested === 'dinner' ? dinnerHas : lunchHas || dinnerHas);
  const isWithin = currentMeal !== 'None';
  const isPast =
    requested === 'lunch'
      ? lunchHas && localNow > lunchEnd
      : requested === 'dinner'
      ? dinnerHas && localNow > dinnerEnd
      : (lunchHas && localNow > lunchEnd) && (!dinnerHas || localNow > dinnerEnd);

  return {
    hasWindow,
    isWithin,
    isPast,
    startMin: currentMeal === 'Lunch' ? lunchStart : currentMeal === 'Dinner' ? dinnerStart : null,
    endMin: currentMeal === 'Lunch' ? lunchEnd : currentMeal === 'Dinner' ? dinnerEnd : null,
    nowMin: localNow,
    currentMeal, // added to help dashboards resolve the active meal string
  };
}

// Compatible helpers already referenced in code (names preserved)

// Limit a membership’s active window to the billing month for proration.
function getActiveWindowForMonth(membership, startOfMonth, endOfMonth) {
  const memberStart = membership?.startDate ? new Date(membership.startDate) : startOfMonth;
  const memberEnd = membership?.endDate ? new Date(membership.endDate) : endOfMonth;
  const activeStart = memberStart > startOfMonth ? memberStart : startOfMonth;
  const activeEnd = memberEnd < endOfMonth ? memberEnd : endOfMonth;
  if (activeEnd < activeStart) {
    return {
      activeStart: null,
      activeEnd: null,
      activeDays: 0,
      monthDays: calculateDaysDifference(startOfMonth, endOfMonth),
    };
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
