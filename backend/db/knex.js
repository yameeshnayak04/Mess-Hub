// new_backend/db/knex.js
//
// This is the single database connection pool for the whole app. Every
// service imports THIS file (not knexfile.js directly) to run queries.
const pg = require('pg');
const knexfile = require('./knexfile');

// By default the Postgres driver hands BIGINT columns back as *strings*, not
// numbers. It does that because a BIGINT can hold values larger than
// JavaScript can represent exactly. The side effect is that every id and every
// money amount would arrive as "143" instead of 143, and the mobile app would
// get strings where it expects numbers.
//
// Converting to a number is safe here: JavaScript handles whole numbers
// exactly up to about 9 quadrillion, and neither our row ids nor our money
// amounts (stored as whole rupees x 100) will ever get near that. Doing it once,
// globally, is better than remembering to convert at every call site.
pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// A DATE column is a calendar day - "the 11th of August" - with no time and no
// timezone. The driver's default is to turn it into a JavaScript Date, which
// bolts on a midnight and a timezone that were never there; JSON then ships it
// as "2026-08-11T00:00:00.000Z" and any conversion can slide it to the wrong
// day. Postgres already sends these as "YYYY-MM-DD", so we keep the string.
pg.types.setTypeParser(pg.types.builtins.DATE, (value) => value);

const environment = process.env.NODE_ENV || 'development';
const knex = require('knex')(knexfile[environment]);

module.exports = knex;
