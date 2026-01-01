const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const {
  startOfDay,
  DEFAULT_TZ_OFFSET_MIN,
  getMealsFromPlan,
} = require('../utils/billCalculation');

const DAY_MS = 24 * 60 * 60 * 1000;

function resolveMembershipStartDate(membership) {
  return (
    membership?.joinedDate ||
    membership?.effectiveFrom ||
    membership?.createdAt ||
    new Date()
  );
}

function resolveMembershipEndCap(membership) {
  // If membership is inactive, cap backfill at the day it became inactive.
  if (membership?.status === 'Inactive' && membership?.updatedAt) {
    return membership.updatedAt;
  }
  return null;
}

async function backfillMissingAttendanceAsPresent({
  includeToday = false,
  offsetMinutes = DEFAULT_TZ_OFFSET_MIN,
} = {}) {
  const now = new Date();
  const todayStart = startOfDay(now, offsetMinutes);
  const globalEnd = includeToday ? todayStart : new Date(todayStart.getTime() - DAY_MS);

  const memberships = await Membership.find({}).select(
    '_id user mess planName billingRate status joinedDate effectiveFrom createdAt updatedAt'
  );

  if (!memberships.length) {
    return {
      membershipsProcessed: 0,
      attendanceInserted: 0,
      fromDate: null,
      toDate: globalEnd,
    };
  }

  // Preload mess rules so we can snapshot rebatePerThali.
  const messIds = Array.from(new Set(memberships.map((m) => String(m.mess))));
  const messDocs = await Mess.find({ _id: { $in: messIds } }).select('rules.rebatePerThali');
  const rebateByMessId = new Map(
    messDocs.map((m) => [String(m._id), Number(m?.rules?.rebatePerThali || 0)])
  );

  let membershipsProcessed = 0;
  let attendanceInserted = 0;
  let overallFrom = null;

  for (const membership of memberships) {
    const meals = getMealsFromPlan(membership.planName);
    if (!meals.length) {
      membershipsProcessed++;
      continue;
    }

    const startRaw = resolveMembershipStartDate(membership);
    const membershipStart = startOfDay(startRaw, offsetMinutes);

    const capRaw = resolveMembershipEndCap(membership);
    const cap = capRaw ? startOfDay(capRaw, offsetMinutes) : null;

    const membershipEnd = cap && cap < globalEnd ? cap : globalEnd;
    if (membershipEnd < membershipStart) {
      membershipsProcessed++;
      continue;
    }

    if (!overallFrom || membershipStart < overallFrom) overallFrom = membershipStart;

    const rebatePerThali = rebateByMessId.get(String(membership.mess)) || 0;

    let bulkOps = [];
    const flush = async () => {
      if (!bulkOps.length) return;
      const res = await Attendance.bulkWrite(bulkOps, { ordered: false });
      attendanceInserted += res.upsertedCount || 0;
      bulkOps = [];
    };

    for (
      let t = membershipStart.getTime();
      t <= membershipEnd.getTime();
      t += DAY_MS
    ) {
      const day = new Date(t);
      for (const mealType of meals) {
        bulkOps.push({
          updateOne: {
            filter: {
              membership: membership._id,
              date: day,
              mealType,
            },
            update: {
              $setOnInsert: {
                user: membership.user,
                membership: membership._id,
                mess: membership.mess,
                date: day,
                mealType,
                status: 'Present',
                memberType: 'Monthly',
                planNameSnapshot: membership.planName,
                rateSnapshot: membership.billingRate,
                rebatePerThaliSnapshot: rebatePerThali,
              },
            },
            upsert: true,
          },
        });

        if (bulkOps.length >= 1000) {
          await flush();
        }
      }
    }

    await flush();
    membershipsProcessed++;
  }

  return {
    membershipsProcessed,
    attendanceInserted,
    fromDate: overallFrom,
    toDate: globalEnd,
  };
}

module.exports = {
  backfillMissingAttendanceAsPresent,
};
