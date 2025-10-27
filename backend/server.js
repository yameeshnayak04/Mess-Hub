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

const app = express();

// Trust proxy (useful behind reverse proxies/load balancers)
app.set('trust proxy', 1);

// Security headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' }, // allow serving images from /uploads
  })
);

// CORS
app.use(cors());

// Parsers
app.use(express.json({ limit: '1mb' })); // keep modest default to protect API
app.use(express.urlencoded({ extended: true }));

// Compression and logging
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

// Central error handler
app.use((err, req, res, next) => {
  // Malformed JSON guard
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
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
