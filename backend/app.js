// new_backend/app.js
//
// Builds the Express app. Kept separate from server.js so tests can import
// the app without actually opening a port.
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');

const knex = require('./db/knex');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { loadConfig } = require('./utils/config');

const config = loadConfig();

function createApp() {
  const app = express();

  // Behind a load balancer (e.g. on Render), this makes req.ip the real
  // client address instead of the proxy's - which matters because the rate
  // limiters key off it.
  app.set('trust proxy', 1);

  app.use(helmet());

  // Only allow the origins we actually ship. The old backend used a bare
  // cors() call, which allows every website on the internet to call the API
  // with a user's credentials. An empty list here means "development, allow
  // anything" - production should always set ALLOWED_ORIGINS.
  app.use(
    cors({
      origin: config.allowedOrigins.length > 0 ? config.allowedOrigins : true,
      credentials: true,
    })
  );

  app.use(express.json({ limit: '1mb' }));
  app.use(compression());

  if (config.env === 'development') {
    app.use(morgan('dev'));
  }

  // Used by Docker's healthcheck and any uptime monitor. It checks the
  // database too, because an API that cannot reach its database is not
  // actually healthy even though the process is alive.
  app.get('/health', async (_req, res) => {
    try {
      await knex.raw('SELECT 1');
      res.json({ status: 'ok', database: 'connected' });
    } catch (error) {
      res.status(503).json({ status: 'error', database: 'unreachable', message: error.message });
    }
  });

  app.use('/api', routes);

  // Order matters: unmatched routes first, then the error handler last so it
  // catches anything thrown anywhere above.
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
