// index.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db.js');

const { notFound, errorHandler } = require('./middlewares/error.middleware.js');

const authRoutes = require('./routes/auth.routes.js');
const messRoutes = require('./routes/mess.routes.js');
const customerRoutes = require('./routes/customer.routes.js');
const managerRoutes = require('./routes/manager.routes.js');
const kioskRoutes = require('./routes/kiosk.routes.js');
const { connect } = require('mongoose');

connectDB();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/messes', messRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/managers', managerRoutes);
app.use('/api/kiosk', kioskRoutes);

app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';
app.listen(PORT, HOST, () => console.log(`Server running on port ${PORT} and listening on all interfaces.`));
