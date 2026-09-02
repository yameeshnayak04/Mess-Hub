// new_backend/jobs/absenceJob.js
//
// Turns "nobody recorded anything" into a real Absent row once a meal's
// serving window has closed.
//
// This runs on a short interval (every ~10 minutes), not once at midnight,
// because every mess sets its own lunch/dinner times - one mess's dinner may
// close at 21:00 and another's at 22:30, and each should be closed off as
// soon as its own window ends.

const knex = require('../db/knex');
const { runTrackedJob } = require('./jobRunner');

// One statement per meal. Reading it out loud: "for every active membership
// whose plan includes this meal, at a mess whose serving window has already
// closed today, insert an Absent row - unless something is already recorded."
//
// Two things here are deliberate and easy to get wrong:
//
//  1. `now() AT TIME ZONE 'Asia/Kolkata'` rather than CURRENT_TIME. The
//     lunch_end / dinner_end columns are plain clock times meaning IST. A
//     database server running in UTC would otherwise compare them against a
//     time 5.5 hours off and close meals at completely the wrong moment.
//
//  2. ON CONFLICT DO NOTHING. Running this job twice cannot create duplicates
//     or overwrite a real Present/Skipped/Leave record, so it is safe to run
//     as often as we like and safe to re-run after a failure.
const MARK_ABSENT_SQL = `
  INSERT INTO attendance (membership_id, mess_id, service_date, meal, status)
  SELECT
    memberships.id,
    memberships.mess_id,
    (now() AT TIME ZONE 'Asia/Kolkata')::date,
    :meal,
    'Absent'
  FROM memberships
  JOIN messes     ON messes.id = memberships.mess_id
  JOIN plan_meals ON plan_meals.plan_id = memberships.plan_id
                 AND plan_meals.meal = :meal
  WHERE memberships.status = 'Active'
    -- A member who has asked to leave is frozen; billing stops counting their
    -- days, so there is no point manufacturing Absent rows for them.
    AND memberships.discontinuation_requested_at IS NULL
    AND (now() AT TIME ZONE 'Asia/Kolkata')::time >
        CASE WHEN :meal = 'Lunch' THEN messes.lunch_end ELSE messes.dinner_end END
    AND NOT EXISTS (
      SELECT 1 FROM attendance
      WHERE attendance.membership_id = memberships.id
        AND attendance.service_date = (now() AT TIME ZONE 'Asia/Kolkata')::date
        AND attendance.meal = :meal
    )
  ON CONFLICT (membership_id, service_date, meal) DO NOTHING
`;

// Runs the statement above for one meal against whatever db handle is given.
// Exported separately so tests can drive it inside their own transaction; the
// job below is what production actually calls.
async function markAbsentForMeal(db, meal) {
  const result = await db.raw(MARK_ABSENT_SQL, { meal });
  return result.rowCount;
}

async function markAbsencesForClosedMeals() {
  return runTrackedJob('absence_marking', null, async () => {
    let rowsAffected = 0;
    const perMeal = {};

    for (const meal of ['Lunch', 'Dinner']) {
      perMeal[meal] = await markAbsentForMeal(knex, meal);
      rowsAffected += perMeal[meal];
    }

    return { rowsAffected, perMeal };
  });
}

module.exports = { markAbsencesForClosedMeals, markAbsentForMeal };
