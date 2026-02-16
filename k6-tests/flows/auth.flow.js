// k6-tests/flows/auth.flow.js
import { CUSTOMER_PHONE, CUSTOMER_PASSWORD, MANAGER_PHONE, MANAGER_PASSWORD } from '../config/env.js';
import { loginWithPhonePassword } from '../utils/auth.js';

// Per-VU token caching (k6 keeps module state per VU between iterations)
let cachedCustomerToken = null;
let cachedManagerToken = null;

export function getCustomerToken() {
  if (cachedCustomerToken) return cachedCustomerToken;
  cachedCustomerToken = loginWithPhonePassword(CUSTOMER_PHONE, CUSTOMER_PASSWORD, { actor: 'customer' });
  return cachedCustomerToken;
}

export function getManagerToken() {
  if (cachedManagerToken) return cachedManagerToken;
  cachedManagerToken = loginWithPhonePassword(MANAGER_PHONE, MANAGER_PASSWORD, { actor: 'manager' });
  return cachedManagerToken;
}
