// Wraps db/schema.sql verbatim — that file remains the source of truth to read/review;
// this migration just makes it a versioned, applied-once step in the normal knex flow.
const fs = require('fs');
const path = require('path');

const SCHEMA_SQL = fs.readFileSync(path.join(__dirname, '..', 'schema.sql'), 'utf8');

exports.up = (knex) => knex.raw(SCHEMA_SQL);

// Initial migration: down is "start over," not a field-by-field reversal.
exports.down = (knex) => knex.raw('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
