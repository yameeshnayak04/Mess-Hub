// new_backend/db/knex.js
//
// This is the single database connection pool for the whole app. Every
// service imports THIS file (not knexfile.js directly) to run queries.
const knexfile = require('./knexfile');

const environment = process.env.NODE_ENV || 'development';
const knex = require('knex')(knexfile[environment]);

module.exports = knex;
