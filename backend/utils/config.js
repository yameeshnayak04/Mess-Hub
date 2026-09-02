// new_backend/utils/config.js
//
// Reads and checks environment variables once, at startup. If something
// required is missing we crash immediately with a clear message, instead of
// starting fine and then failing on the first request that happens to need it.
require('dotenv').config();

const REQUIRED = ['DATABASE_URL', 'JWT_SECRET'];

function loadConfig() {
  const missing = REQUIRED.filter((name) => !process.env[name]);
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variable(s): ${missing.join(', ')}. ` +
        `Copy .env.example to .env and fill them in.`
    );
  }

  return {
    env: process.env.NODE_ENV || 'development',
    port: Number(process.env.PORT) || 4000,
    jwtSecret: process.env.JWT_SECRET,
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',
    cronSecret: process.env.CRON_SECRET || '',
    // Comma-separated list. Empty means "allow any origin", which is fine for
    // local development but should always be set in production.
    allowedOrigins: (process.env.ALLOWED_ORIGINS || '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
    cloudinary: {
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      apiSecret: process.env.CLOUDINARY_API_SECRET,
    },
  };
}

module.exports = { loadConfig };
