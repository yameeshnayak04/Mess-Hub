// new_backend/server.js
//
// Starts the HTTP server and shuts it down cleanly.
const { createApp } = require('./app');
const knex = require('./db/knex');
const { loadConfig } = require('./utils/config');

const config = loadConfig(); // throws immediately if required env vars are missing
const app = createApp();

const server = app.listen(config.port, () => {
  console.log(`new_backend listening on port ${config.port} (${config.env})`);
});

// A promise that rejects with nothing catching it, or an error thrown outside
// any request, leaves Node in a state we cannot reason about. Log it and exit
// so the container restarts with a clean process, rather than limping along
// serving requests from a broken event loop.
function crashOnUnexpectedError(label) {
  return (error) => {
    console.error(`${label}:`, error);
    process.exit(1);
  };
}
process.on('unhandledRejection', crashOnUnexpectedError('Unhandled promise rejection'));
process.on('uncaughtException', crashOnUnexpectedError('Uncaught exception'));

// Docker sends SIGTERM when stopping a container. Finish the requests already
// in flight, close the database pool, then exit - otherwise an in-progress
// billing transaction could be cut off mid-way.
async function shutDownGracefully(signal) {
  console.log(`${signal} received, shutting down...`);

  server.close(async () => {
    try {
      await knex.destroy();
      console.log('Database pool closed. Bye.');
      process.exit(0);
    } catch (error) {
      console.error('Error while closing the database pool:', error);
      process.exit(1);
    }
  });

  // Don't hang forever if a request refuses to finish.
  setTimeout(() => {
    console.error('Shutdown took too long, forcing exit.');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => shutDownGracefully('SIGTERM'));
process.on('SIGINT', () => shutDownGracefully('SIGINT'));
