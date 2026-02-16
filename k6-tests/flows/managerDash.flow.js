// k6-tests/flows/managerDash.flow.js
import { BASE_URL, API_PREFIX } from '../config/env.js';
import { jsonHeaders } from '../utils/headers.js';
import { get, expect2xx } from '../utils/http.js';

export function getManagerDashboardStats(managerToken) {
  // GET /mess/my-mess/dashboard (manager-only) [file:9]
  const url = `${BASE_URL}${API_PREFIX}/mess/my-mess/dashboard`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /mess/my-mess/dashboard' } };

  const { res, body } = get(url, params, 'manager_dashboard');
  expect2xx(res, 'manager_dashboard');
  return body;
}
