// backend/server.js
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

dotenv.config();

const connectDB = require('./config/db.js');
connectDB();

const app = express();

// Trust proxy (Render)
app.set('trust proxy', 1);

// Security and core middleware
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging only in development
if ((process.env.NODE_ENV || '').toLowerCase() === 'development') {
  app.use(morgan('dev'));
}

// Enable compression in all envs
app.use(compression());

// Static and health
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.get('/health', (_req, res) => res.status(200).json({ ok: true }));

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

// Cron endpoints (always mounted)
app.use('/api/cron', require('./routes/cronRoutes.js'));

// Error handler (after routes)
app.use((err, req, res, _next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ success: false, message: 'Invalid JSON payload' });
  }
  console.error(err.stack);
  return res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// 404 fallback (last)
app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
