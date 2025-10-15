// This is the main entry point for the backend server.

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
// Import the error handling middleware
const { notFound, errorHandler } = require('./middlewares/error.middleware.js');

// Import all Route Files
const authRoutes = require('./routes/auth.routes.js');
const messRoutes = require('./routes/mess.routes.js');
const customerRoutes = require('./routes/customer.routes.js');
const managerRoutes = require('./routes/manager.routes.js');
const kioskRoutes = require('./routes/kiosk.routes.js');

// Connect to Database
connectDB();

const app = express();

// Core Middleware
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/messes', messRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/managers', managerRoutes);
app.use('/api/kiosk', kioskRoutes);

// --- ERROR HANDLING MIDDLEWARE ---
// This middleware must be placed AFTER all your routes.
app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Listen on all available network interfaces

app.listen(PORT, HOST, () => console.log(`Server running on port ${PORT} and listening on all interfaces.`));