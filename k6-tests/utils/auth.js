// k6-tests/utils/auth.js
import { BASE_URL, API_PREFIX } from '../config/env.js';
import { jsonHeaders } from './headers.js';
import { post, expect2xx } from './http.js';

export function loginWithPhonePassword(phone, password, tags = {}) {
  const url = `${BASE_URL}${API_PREFIX}/auth/login`;

  const payload = JSON.stringify({ phone, password }); // matches your backend [file:12]
  const params = { ...jsonHeaders(null), tags: { name: 'POST /auth/login', ...tags } };

  const { res, body } = post(url, payload, params, 'auth_login');
  expect2xx(res, 'auth_login');

  if (!body || !body.token) throw new Error(`Login failed: status=${res.status} body=${res.body}`);
  return body.token;
}
