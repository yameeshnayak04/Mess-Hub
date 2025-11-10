// server.js
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const mongoose = require('mongoose');
const connectDB = require('./config/db');

dotenv.config();

const app = express();
app.set('trust proxy', 1);

// Core middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());
if ((process.env.NODE_ENV || '').toLowerCase() === 'development') {
  app.use(morgan('dev'));
}

// Health first (so Render can pass health checks even if DB is cold)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running' });
});

// DB readiness guard (fail fast instead of hanging)
const requireDb = (req, res, next) => {
  if (mongoose.connection.readyState !== 1) {
    return res
      .status(503)
      .json({ success: false, message: 'Database is not connected. Please retry.' });
  }
  next();
};

// Safe require so missing routes don’t crash startup
const safeRequire = (p) => {
  try { return require(p); } catch (e) {
    console.warn(`[routes] Skipping ${p}: ${e.message}`);
    return null;
  }
};
const mount = (path, modPath, needsDb = true) => {
  const r = safeRequire(modPath);
  if (r) needsDb ? app.use(path, requireDb, r) : app.use(path, r);
};

// Mount only routes that exist in deploy
mount('/api/auth', './routes/authRoutes');        // DB-backed
mount('/api/mess', './routes/messRoutes');        // DB-backed
mount('/api/jobs', './routes/jobRoutes', false);  // fire-and-forget endpoints

// (Add others only if they exist in your Render build)
// mount('/api/users', './routes/userRoutes');
// mount('/api/membership', './routes/membershipRoutes');
// mount('/api/attendance', './routes/attendanceRoutes');
// mount('/api/leave', './routes/leaveRoutes');
// mount('/api/billing', './routes/billingRoutes');
// mount('/api/menu', './routes/menuRoutes');
// mount('/api/reviews', './routes/reviewRoutes');

// Central error handler
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && 'body' in err) {
    return res.status(400).json({ success: false, message: 'Invalid JSON payload' });
  }
  console.error(err.stack);
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Server Error',
    ...((process.env.NODE_ENV || '') === 'development' && { stack: err.stack }),
  });
});

// 404 fallback
app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

// Start server first so /health is live during cold starts
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});

// Connect DB in background; do not crash the process on first failure
(async () => {
  try {
    await connectDB();
    console.log('MongoDB connected');
  } catch (e) {
    console.error('Initial DB connect failed:', e.message);
  }
})();
