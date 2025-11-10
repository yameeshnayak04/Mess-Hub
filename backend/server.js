// server.js (drop-in)
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const mongoose = require('mongoose');
const path = require('path'); // REQUIRED for express.static
// Do not load jobs until the app is up; they can run after boot
// const connectDB = require('./config/db');

dotenv.config();

const app = express();
app.set('trust proxy', 1);

// Minimal middleware for health
app.get('/health', (_req, res) => res.status(200).json({ status: 'OK' }));

// Core middleware
app.use(
  helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } })
);
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());
if ((process.env.NODE_ENV || '').toLowerCase() === 'development') {
  app.use(morgan('dev'));
}

// Static files (now path is defined)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// DB readiness guard
const requireDb = (req, res, next) => {
  if (mongoose.connection.readyState !== 1) {
    return res.status(503).json({ success: false, message: 'Database is not connected. Please retry.' });
  }
  next();
};

// Safe require so missing routes never crash boot
const safeRequire = (p) => {
  try { return require(p); } catch (e) {
    console.warn(`[routes] Skipping ${p}: ${e.message}`);
    return null;
  }
};
const mount = (url, modPath, needsDb = true) => {
  const r = safeRequire(modPath);
  if (r) needsDb ? app.use(url, requireDb, r) : app.use(url, r);
};

// Mount only once (remove any duplicate app.use lines)
mount('/api/auth', './routes/authRoutes');
mount('/api/mess', './routes/messRoutes');
mount('/api/jobs', './routes/jobRoutes', false); // background triggers only
// Add others ONLY if they exist in the Render image:
// mount('/api/users', './routes/userRoutes');
// mount('/api/membership', './routes/membershipRoutes');
// mount('/api/attendance', './routes/attendanceRoutes');
// mount('/api/leave', './routes/leaveRoutes');
// mount('/api/billing', './routes/billingRoutes');
// mount('/api/menu', './routes/menuRoutes');
// mount('/api/reviews', './routes/reviewRoutes');

// Error handler
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && 'body' in err) {
    return res.status(400).json({ success: false, message: 'Invalid JSON payload' });
  }
  console.error(err.stack);
  res.status(err.statusCode || 500).json({ success: false, message: err.message || 'Server Error' });
});

// 404
app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

// Start server first so /health is up
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server listening on ${PORT}`));

// Connect DB after server starts; don’t crash on failure
(async () => {
  try {
    const connectDB = require('./config/db');
    await connectDB();
    console.log('MongoDB connected');

    // Start background jobs only after DB is ready
    // require('./jobs/absentJob');
    // require('./jobs/billingJob');
  } catch (e) {
    console.error('Initial DB connect failed:', e.message);
  }
})();
