// new_backend/services/messClock.js
//
// "What day is it, and is a meal being served right now?" — answered by
// Postgres rather than by JavaScript.
//
// Why let the database decide: lunch_start/lunch_end are plain TIME columns
// meaning IST wall-clock time. Comparing them against a JS `new Date()` means
// trusting whatever timezone the Node process happens to run in, which on a
// cloud host is usually UTC — five and a half hours off. Doing the comparison
// in SQL with an explicit `AT TIME ZONE` removes the guesswork completely.

const knex = require('../db/knex');

async function getMessClock(messId, db = knex) {
  const { rows } = await db.raw(
    `
    SELECT
      (now() AT TIME ZONE 'Asia/Kolkata')::date::text AS today,
      to_char((now() AT TIME ZONE 'Asia/Kolkata')::time, 'HH24:MI') AS current_time,
      CASE
        WHEN (now() AT TIME ZONE 'Asia/Kolkata')::time
             BETWEEN lunch_start AND lunch_end  THEN 'Lunch'
        WHEN (now() AT TIME ZONE 'Asia/Kolkata')::time
             BETWEEN dinner_start AND dinner_end THEN 'Dinner'
      END AS current_meal,
      -- The next meal that has not started yet today. After dinner closes
      -- this is null, which the caller reads as "tomorrow's lunch".
      CASE
        WHEN (now() AT TIME ZONE 'Asia/Kolkata')::time < lunch_start  THEN 'Lunch'
        WHEN (now() AT TIME ZONE 'Asia/Kolkata')::time < dinner_start THEN 'Dinner'
      END AS next_meal_today,
      to_char(lunch_start,  'HH24:MI') AS lunch_start,
      to_char(lunch_end,    'HH24:MI') AS lunch_end,
      to_char(dinner_start, 'HH24:MI') AS dinner_start,
      to_char(dinner_end,   'HH24:MI') AS dinner_end,
      -- Whether each meal's window has already closed for today.
      -- Careful: never write a question mark inside a knex raw query, even in
      -- a comment. Knex scans the whole string for placeholders and will count
      -- it as one, then fail because the bindings no longer match.
      (now() AT TIME ZONE 'Asia/Kolkata')::time > lunch_end  AS lunch_is_over,
      (now() AT TIME ZONE 'Asia/Kolkata')::time > dinner_end AS dinner_is_over
    FROM messes
    WHERE id = ?
    `,
    [messId]
  );

  const clock = rows[0];
  if (!clock) return null;

  return {
    ...clock,
    // After dinner, the next thing served is tomorrow's lunch.
    nextMeal: clock.next_meal_today || 'Lunch',
    nextMealIsTomorrow: !clock.next_meal_today,
    isMealOver: (meal) => (meal === 'Lunch' ? clock.lunch_is_over : clock.dinner_is_over),
  };
}

// Today's date in India, as a plain 'YYYY-MM-DD' string. Asked of Postgres
// for the same reason as above: the Node process's own clock may be in UTC.
async function getTodayInIndia(db = knex) {
  const { rows } = await db.raw("SELECT (now() AT TIME ZONE 'Asia/Kolkata')::date::text AS today");
  return rows[0].today;
}

module.exports = { getMessClock, getTodayInIndia };
