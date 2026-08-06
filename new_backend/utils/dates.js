// new_backend/utils/dates.js
//
// Calendar dates are handled as plain 'YYYY-MM-DD' strings everywhere in this
// codebase, never as JavaScript Date objects passed around.
//
// Why: a JS Date is really a moment in time (with a timezone), but attendance,
// leave and billing only care about *which calendar day* something happened.
// Mixing the two is what caused the old backend's off-by-one-day bugs. A plain
// 'YYYY-MM-DD' string has no timezone to get wrong.
//
// Bonus: ISO date strings sort correctly as plain text, so comparing two dates
// is just `a < b` — no special date-comparison helper needed.

// 'YYYY-MM-DD' -> Date object at midnight UTC.
// We only use this internally for day arithmetic; UTC keeps it deterministic
// no matter what timezone the Node process happens to be running in.
function parseDate(dateString) {
  const [year, month, day] = dateString.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day));
}

// Date object -> 'YYYY-MM-DD'
function formatDate(date) {
  return date.toISOString().slice(0, 10);
}

function addDays(dateString, days) {
  const date = parseDate(dateString);
  date.setUTCDate(date.getUTCDate() + days);
  return formatDate(date);
}

function addMonths(dateString, months) {
  const date = parseDate(dateString);
  date.setUTCMonth(date.getUTCMonth() + months);
  return formatDate(date);
}

// Number of days from start (inclusive) to end (exclusive).
// daysBetween('2026-04-01', '2026-05-01') === 30
function daysBetween(startDateString, endDateString) {
  const millisecondsPerDay = 24 * 60 * 60 * 1000;
  const difference = parseDate(endDateString) - parseDate(startDateString);
  return Math.round(difference / millisecondsPerDay);
}

function earlier(dateStringA, dateStringB) {
  return dateStringA < dateStringB ? dateStringA : dateStringB;
}

function later(dateStringA, dateStringB) {
  return dateStringA > dateStringB ? dateStringA : dateStringB;
}

// '2026-04-17' -> '2026-04-01'
function firstDayOfMonth(dateString) {
  return dateString.slice(0, 8) + '01';
}

module.exports = {
  parseDate,
  formatDate,
  addDays,
  addMonths,
  daysBetween,
  earlier,
  later,
  firstDayOfMonth,
};
