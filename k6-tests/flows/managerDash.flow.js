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

export function getMembersEating(managerToken) {
  const url = `${BASE_URL}${API_PREFIX}/mess/dashboard/members-eating`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /mess/dashboard/members-eating' } };

  const { res, body } = get(url, params, 'members_eating');
  expect2xx(res, 'members_eating');
  return body;
}

export function getMembersOnLeave(managerToken) {
  const url = `${BASE_URL}${API_PREFIX}/mess/dashboard/members-on-leave`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /mess/dashboard/members-on-leave' } };

  const { res, body } = get(url, params, 'members_on_leave');
  expect2xx(res, 'members_on_leave');
  return body;
}

export function getMembersSkipped(managerToken) {
  const url = `${BASE_URL}${API_PREFIX}/mess/dashboard/members-skipped`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /mess/dashboard/members-skipped' } };

  const { res, body } = get(url, params, 'members_skipped');
  expect2xx(res, 'members_skipped');
  return body;
}

export function getMembersRemaining(managerToken) {
  const url = `${BASE_URL}${API_PREFIX}/mess/dashboard/members-remaining`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /mess/dashboard/members-remaining' } };

  const { res, body } = get(url, params, 'members_remaining');
  expect2xx(res, 'members_remaining');
  return body;
}
