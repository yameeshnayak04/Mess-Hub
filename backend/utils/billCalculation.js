// utils/billCalculation.js
// Existing utilities retained; new calculateMonthlyBillForMember added.

const DEFAULT_TZ_OFFSET_MIN = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10); // IST by default

const normOffset = (min) => ((min % 1440) + 1440) % 1440;
const getLocalMinutes = (now = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) => {
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  return (utcMin + normOffset(offsetMin)) % 1440;
};

function startOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  // Shift into target local timezone, take its calendar day, then shift back to UTC.
  // This avoids off-by-one-day issues when server UTC date differs from local date (e.g., IST).
  const d = new Date(date);
  const shifted = new Date(d.getTime() + offsetMin * 60 * 1000);
  const utcMidnightOfLocalDay = Date.UTC(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth(),
    shifted.getUTCDate()
  );
  return new Date(utcMidnightOfLocalDay - offsetMin * 60 * 1000);
}

function endOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const s = startOfDay(date, offsetMin);
  return new Date(s.getTime() + 24 * 60 * 60 * 1000 - 1);
}

function getStartAndEndOfDay(date = new Date(), offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  return { startOfDay: startOfDay(date, offsetMin), endOfDay: endOfDay(date, offsetMin) };
}

const stripTime = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const dayMs = 24 * 60 * 60 * 1000;

function calculateDaysDifference(startDate, endDate) {
  const s = stripTime(new Date(startDate));
  const e = stripTime(new Date(endDate));
  if (e < s) return 0;
  return Math.floor((e - s) / dayMs) + 1;
}

function getStartAndEndOfMonth(month, year, offsetMin = DEFAULT_TZ_OFFSET_MIN) {
  const m0 = month - 1;
  const startUTC = Date.UTC(year, m0, 1);
  const startOfMonth = new Date(startUTC - offsetMin * 60 * 1000);
  const nextMonthUTC = Date.UTC(year, m0 + 1, 1);
  const startOfNextLocal = new Date(nextMonthUTC - offsetMin * 60 * 1000);
  const endOfMonth = new Date(startOfNextLocal.getTime() - 1);
  return { startOfMonth, endOfMonth };
}

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

  const requested = String(mealType || '').toLowerCase();
  let currentMeal = 'None';
  if (requested === 'lunch' && lunchWithin) currentMeal = 'Lunch';
  else if (requested === 'dinner' && dinnerWithin) currentMeal = 'Dinner';
  else if (lunchWithin) currentMeal = 'Lunch';
  else if (dinnerWithin) currentMeal = 'Dinner';

  const hasWindow = (requested === 'lunch'
    ? lunchHas
    : requested === 'dinner'
    ? dinnerHas
    : lunchHas || dinnerHas);

  return {
    hasWindow,
    isWithin: currentMeal !== 'None',
    isPast:
      requested === 'lunch'
        ? lunchHas && localNow > lunchEnd
        : requested === 'dinner'
        ? dinnerHas && localNow > dinnerEnd
        : (lunchHas && localNow > lunchEnd) && (!dinnerHas || localNow > dinnerEnd),
    startMin: currentMeal === 'Lunch' ? lunchStart : currentMeal === 'Dinner' ? dinnerStart : null,
    endMin: currentMeal === 'Lunch' ? lunchEnd : currentMeal === 'Dinner' ? dinnerEnd : null,
    nowMin: localNow,
    currentMeal,
  };
}

function getActiveWindowForMonth(membership, startOfMonth, endOfMonth) {
  const memberStartRaw =
    membership?.startDate ||
    membership?.effectiveFrom ||
    membership?.joinedDate ||
    startOfMonth;

  let memberEndRaw = membership?.endDate || null;
  if (!memberEndRaw) {
    if (membership && membership.status === 'Inactive' && membership.updatedAt) {
      memberEndRaw = membership.updatedAt;
    } else {
      memberEndRaw = endOfMonth;
    }
  }

  const memberStart = new Date(memberStartRaw);
  const memberEnd = new Date(memberEndRaw);

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

function getMealsFromPlan(planName) {
  const p = String(planName || '').toLowerCase();
  if (p.includes('both')) return ['Lunch', 'Dinner'];
  if (p.includes('lunch')) return ['Lunch'];
  if (p.includes('dinner')) return ['Dinner'];
  return [];
}

/**
 * Shared billing calculation (attendance-based only).
 * Returns plain object with breakdown.
 * skipMealRebatePercent is mapped from existing skipAllowancePercent.
 */
async function calculateMonthlyBillForMember({
  member,
  mess,
  month,
  year,
  AttendanceModel,
}) {
  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(month, year);
  const window = getActiveWindowForMonth(member, startOfMonth, endOfMonth);
  if (!window.activeStart || !window.activeEnd) {
    return {
      baseAmount: 0,
      rebateAmount: 0,
      finalAmount: 0,
      presentCount: 0,
      absentCount: 0,
      leaveCount: 0,
      skipCount: 0,
      noRecordMeals: 0,
    };
  }

  const includedMeals = getMealsFromPlan(member.planName);
  if (!includedMeals.length) {
    return {
      baseAmount: 0,
      rebateAmount: 0,
      finalAmount: 0,
      presentCount: 0,
      absentCount: 0,
      leaveCount: 0,
      skipCount: 0,
      noRecordMeals: 0,
    };
  }

  // Resolve baseAmount.
  let baseAmount = Number(member.billingRate || 0);
  if (!baseAmount && Array.isArray(mess.plans)) {
    const planMatch = mess.plans.find(
      (p) => String(p.name || '').toLowerCase() === String(member.planName || '').toLowerCase()
    );
    if (planMatch && typeof planMatch.rate === 'number') {
      baseAmount = Number(planMatch.rate);
      // Persist back so future months use it (optional outside this pure function).
    }
  }
  if (!baseAmount) {
    return {
      baseAmount: 0,
      rebateAmount: 0,
      finalAmount: 0,
      presentCount: 0,
      absentCount: 0,
      leaveCount: 0,
      skipCount: 0,
      noRecordMeals: 0,
    };
  }

  const rules = mess.rules || {};
  const rebatePerThali = Number(rules.rebatePerThali || 0);
  const skipMealRebatePercent = Number(rules.skipAllowancePercent || 0); // mapped
  const allowAbsentRebate = rules.allowAbsentRebate === true;
  const minMonthlyCharge = Number(rules.minMonthlyCharge || 0);

  // Fetch all attendance rows in active window for included meals.
  const attendanceRows = await AttendanceModel.find({
    membership: member._id,
    mess: mess._id,
    mealType: { $in: includedMeals },
    date: { $gte: window.activeStart, $lte: window.activeEnd },
  }).select('date mealType status');

  // Count by status.
  let presentCount = 0;
  let absentCount = 0;
  let leaveCount = 0;
  let skipCount = 0;

  // Build lookup for (day, meal) combinations.
  const recordedKeySet = new Set();
  for (const row of attendanceRows) {
    const d = new Date(row.date);
    const key = `${d.getUTCFullYear()}-${d.getUTCMonth()}-${d.getUTCDate()}|${row.mealType}`;
    recordedKeySet.add(key);
    switch (row.status) {
      case 'Present':
        presentCount++;
        break;
      case 'Absent':
        absentCount++;
        break;
      case 'Leave':
        leaveCount++;
        break;
      case 'Skipped':
        skipCount++;
        break;
      default:
        break;
    }
  }

  // Iterate days in active window to find missing (no-record) meals.
  let noRecordMeals = 0;
  const cursor = new Date(window.activeStart);
  while (cursor <= window.activeEnd) {
    for (const meal of includedMeals) {
      const key = `${cursor.getUTCFullYear()}-${cursor.getUTCMonth()}-${cursor.getUTCDate()}|${meal}`;
      if (!recordedKeySet.has(key)) {
        noRecordMeals++;
      }
    }
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }

  // Deductions.
  const leaveDeduction = leaveCount * rebatePerThali;
  const skipDeduction =
    skipCount * (skipMealRebatePercent / 100) * rebatePerThali;
  const noRecordDeduction = noRecordMeals * rebatePerThali;
  const absentDeduction = allowAbsentRebate ? absentCount * rebatePerThali : 0;

  const rebateAmount = Math.max(
    0,
    Math.round((leaveDeduction + skipDeduction + noRecordDeduction + absentDeduction) * 100) / 100
  );

  const provisional = Math.round((baseAmount - rebateAmount) * 100) / 100;
  const finalAmount = provisional < minMonthlyCharge ? minMonthlyCharge : provisional;

  return {
    baseAmount: Math.round(baseAmount * 100) / 100,
    rebateAmount,
    finalAmount: Math.round(finalAmount * 100) / 100,
    presentCount,
    absentCount,
    leaveCount,
    skipCount,
    noRecordMeals,
  };
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
  calculateMonthlyBillForMember, // new export
};
