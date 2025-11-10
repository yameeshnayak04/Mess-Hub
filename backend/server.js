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

// Connect DB
connectDB();

// --- Load Jobs ---
require('./jobs/absentJob'); // Marks users absent
require('./jobs/billingJob'); // Generates monthly bills

const app = express();
app.set('trust proxy', 1);

// Security headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' }, // allow serving images from /uploads
  })
);

// CORS
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());
app.use(morgan('dev'));

// Static files for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./routes/authRoutes'));               // register/login/logout
app.use('/api/users', require('./routes/userRoutes'));              // get/update my profile
app.use('/api/mess', require('./routes/messRoutes'));               // discover, mess details, manager CRUD, dashboard
app.use('/api/membership', require('./routes/membershipRoutes'));   // join/leave/approve/reject/details
app.use('/api/attendance', require('./routes/attendanceRoutes'));   // skip meal, kiosk mark, calendars
app.use('/api/leave', require('./routes/leaveRoutes'));             // apply + history (no status workflow)
app.use('/api/billing', require('./routes/billingRoutes'));         // generate bills, approvals, customer bills
app.use('/api/menu', require('./routes/menuRoutes'));               // set/get menu
app.use('/api/reviews', require('./routes/reviewRoutes'));          // get/add reviews

// Health check
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
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// 404 fallback
app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
