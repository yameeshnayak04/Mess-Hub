// index.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const connectDB = require('./config/db.js');
const { notFound, errorHandler } = require('./middlewares/error.middleware.js');

const authRoutes = require('./routes/auth.routes.js');
const messRoutes = require('./routes/mess.routes.js');
const customerRoutes = require('./routes/customer.routes.js');
const managerRoutes = require('./routes/manager.routes.js');
const kioskRoutes = require('./routes/kiosk.routes.js');

connectDB();

const app = express();

app.set('trust proxy', 1);
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(compression());

// Health
app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }));

// APIs
app.use('/api/auth', authRoutes);
app.use('/api/messes', messRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/manager', managerRoutes);
app.use('/api/kiosk', kioskRoutes);

// Errors
app.use(notFound);
app.use(errorHandler);

// Use dynamic import because get-port is ESM-only
(async () => {
  const { default: getPort } = await import('get-port');
  const preferred = Number(process.env.PORT) || 3000;
  const port = await getPort({ port: [preferred, preferred + 1, preferred + 2] });
  app.listen(port, '0.0.0.0', () => console.log(`Server running on port ${port}`));
})().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
