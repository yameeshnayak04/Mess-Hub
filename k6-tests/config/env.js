// k6-tests/config/env.js
function required(name, fallback = null) {
  const v = __ENV[name] ?? fallback;
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

export const BASE_URL = required('BASE_URL') || 'https://mess-hub-backend.onrender.com';  // Base URL of your backend, e.g., "https://your-app.onrender.com"
export const API_PREFIX = __ENV.API_PREFIX || '/api';

export const CUSTOMER_PHONE = required('CUSTOMER_PHONE');
export const CUSTOMER_PASSWORD = required('CUSTOMER_PASSWORD');

export const MANAGER_PHONE = required('MANAGER_PHONE');
export const MANAGER_PASSWORD = required('MANAGER_PASSWORD');

export const P95_MS = Number(__ENV.P95_MS || 2000);
if (!Number.isFinite(P95_MS) || P95_MS <= 0) throw new Error('P95_MS must be a positive number');
