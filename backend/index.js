// This is the main entry point for the backend server.

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const { notFound, errorHandler } = require('./middlewares/error.middleware.js');

// Import Route Files
const authRoutes = require('./routes/auth.routes.js');
const messRoutes = require('./routes/mess.routes.js');
const customerRoutes = require('./routes/customer.routes.js');
const managerRoutes = require('./routes/manager.routes.js');
const kioskRoutes = require('./routes/kiosk.routes.js');

// Connect to Database
connectDB();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/messes', messRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/managers', managerRoutes);
app.use('/api/kiosk', kioskRoutes);

// --- ERROR HANDLING MIDDLEWARE ---
// This middleware should be placed AFTER all your routes.
// It will catch requests for routes that don't exist.
app.use(notFound);
// This is the general error handler that will catch any errors passed by 'next(error)'.
app.use(errorHandler);


const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});