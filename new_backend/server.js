// new_backend/server.js
//
// This is the entry point. Right now it's intentionally small — just enough to
// start the app and prove the database connection works. Routes get added in
// later phases (middleware, then controllers).
require('dotenv').config();

const express = require('express');
const knex = require('./db/knex');

// Fail fast: if we're missing something we need to even start, crash
// immediately with a clear message instead of starting and failing later on
// the first request. This is much easier to debug, especially in Docker
// where a silent failure just looks like "the container won't start".
const requiredEnvVars = ['DATABASE_URL'];
for (const name of requiredEnvVars) {
  if (!process.env[name]) {
    console.error(`Missing required environment variable: ${name}`);
    process.exit(1);
  }
}

const app = express();

// Docker Compose's healthcheck (and later, a real uptime monitor) hits this.
// It's not just "is the server up" — it also checks we can actually reach
// Postgres, since a server that's up but can't talk to its database is
// useless anyway.
app.get('/health', async (_req, res) => {
  try {
    await knex.raw('SELECT 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'error', database: 'unreachable', message: err.message });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`new_backend listening on port ${PORT}`);
});
