// backend/server.js
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

// Load env before using any env vars
dotenv.config();

// DB connection
const connectDB = require('./config/db.js');

// Jobs
const { scheduleBillingJob } = require('./jobs/billingJob.js');
require('./jobs/absentJob'); // schedules internal cron when the app is running

// Connect DB
connectDB();

const app = express();

// Trust proxy (Render)
app.set('trust proxy', 1);

// Security headers
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

// Core middleware
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
if ((process.env.NODE_ENV || '').toLowerCase() === 'development') {
  app.use(morgan('dev'));
}
app.use(compression());

// Static files (legacy local uploads if any)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check
app.get('/health', (req, res) => res.status(200).json({ status: 'OK' }));

// Routes
app.use('/api/auth', require('./routes/authRoutes.js'));
app.use('/api/users', require('./routes/userRoutes.js'));
app.use('/api/mess', require('./routes/messRoutes.js'));
app.use('/api/membership', require('./routes/membershipRoutes.js'));
app.use('/api/attendance', require('./routes/attendanceRoutes.js'));
app.use('/api/leave', require('./routes/leaveRoutes.js'));
app.use('/api/billing', require('./routes/billingRoutes.js'));
app.use('/api/menu', require('./routes/menuRoutes.js'));
app.use('/api/reviews', require('./routes/reviewRoutes.js'));
app.use('/api/cron', require('./routes/cronRoutes.js')); // make sure routes/cronRoutes.js exists

// Error handler (after routes)
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

// 404 fallback (last)
app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

// Start cron scheduler(s) after app is fully configured
scheduleBillingJob();

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
