// server.js (replace entire file)
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const compression = require('compression');
const connectDB = require('./config/db');

// Load env
dotenv.config();

// Connect DB
connectDB();

// --- Load Jobs ---
require('./jobs/absentJob'); // schedules every 5 min internally
const { scheduleBillingJob } = require('./jobs/billingJob');
scheduleBillingJob(); // ensure monthly billing is scheduled

const app = express();

// Trust proxy (Render)
app.set('trust proxy', 1);

// Security headers
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

// CORS
app.use(cors());

// Parsers
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Compression and logging
app.use(compression());
app.use(morgan('dev'));

// Static files (optional legacy local uploads)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/mess', require('./routes/messRoutes'));
app.use('/api/membership', require('./routes/membershipRoutes'));
app.use('/api/attendance', require('./routes/attendanceRoutes'));
app.use('/api/leave', require('./routes/leaveRoutes'));
app.use('/api/billing', require('./routes/billingRoutes'));
app.use('/api/menu', require('./routes/menuRoutes'));
app.use('/api/reviews', require('./routes/reviewRoutes'));

// Internal cron trigger routes
app.use('/api/cron', require('./routes/cronRoutes'));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running' });
});

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
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
