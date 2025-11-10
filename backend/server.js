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

/*
// --- JOBS REMOVED ---
// These are now handled by GitHub Actions
// require('./jobs/absentJob'); 
// require('./jobs/billingJob'); 
*/

const app = express();
app.set('trust proxy', 1); 

// Security headers
app.use(helmet()); 

// CORS (This is already perfect)
app.use(cors());

// Parsers
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Compression and logging
app.use(compression());
// Only use morgan in development to avoid logging noise in production
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

/*
// --- STATIC PATH REMOVED ---
// This is not needed because we are using Cloudinary for images.
// app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
*/

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

// --- THIS IS THE NEW, IMPORTANT LINE ---
app.use('/api/jobs', require('./routes/jobRoutes')); // <-- ADD THIS

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

// This port logic is perfect for both local and production
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
});