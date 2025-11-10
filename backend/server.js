const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

dotenv.config();

const app = express();
app.set('trust proxy', 1);

// Health first
app.get('/health', (_req, res) => res.status(200).json({ status: 'OK' }));

// Core middleware
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
if ((process.env.NODE_ENV || '').toLowerCase() === 'development') {
  app.use(morgan('dev'));
}
app.use(compression());

// Static uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// MOUNT ROUTES (ensure this file exists at ./routes/authRoutes.js)
app.use('/api/auth', require('./routes/authRoutes')); // POST /api/auth/register

// 404 fallback (keep last)
app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
