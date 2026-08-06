// new_backend/db/knexfile.js
//
// Knex is our "SQL toolkit" — it manages the database connection pool, runs our
// migrations, and lets us run transactions. We still write our own SQL by hand
// for anything real (that's on purpose, see the plan doc) — Knex is not an ORM here.
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

// Every connection in the pool needs to "think" in Indian time (IST), not the
// server's UTC clock. If we skipped this, something like "mark absent after
// 2pm" could fire at the wrong real-world time. We do this once, right when a
// connection is created, so every query on it automatically uses IST.
//
// statement_timeout is a safety net: if a query somehow hangs (e.g. a bug in
// the billing query), Postgres will kill it after 30 seconds instead of
// freezing the whole app.
const afterCreate = (conn, done) => {
  conn.query("SET TIME ZONE 'Asia/Kolkata'; SET statement_timeout = '30s';", (err) =>
    done(err, conn)
  );
};

const basePoolSettings = {
  client: 'pg',
  pool: { min: 2, max: 10, idleTimeoutMillis: 30000, afterCreate },
  migrations: { directory: __dirname + '/migrations', tableName: 'knex_migrations' },
};

module.exports = {
  development: { ...basePoolSettings, connection: process.env.DATABASE_URL },

  // Tests can point at a separate database via TEST_DATABASE_URL if you want
  // to keep test data fully apart from dev data. If it's not set, tests just
  // reuse the dev database (fine for this project since every test cleans up
  // after itself by rolling back its transaction — see test-helpers).
  test: {
    ...basePoolSettings,
    connection: process.env.TEST_DATABASE_URL || process.env.DATABASE_URL,
    pool: { min: 1, max: 5, afterCreate },
  },

  production: {
    ...basePoolSettings,
    connection: { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } },
  },
};
