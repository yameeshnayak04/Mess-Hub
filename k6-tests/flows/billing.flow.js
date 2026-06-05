// k6-tests/flows/billing.flow.js
import { BASE_URL, API_PREFIX } from '../config/env.js';
import { jsonHeaders } from '../utils/headers.js';
import { get, expect2xx } from '../utils/http.js';

export function getMyBills(customerToken, membershipId) {
  // Customer route exists: GET /api/billing/my-bills/:membershipId [file:2]
  const url = `${BASE_URL}${API_PREFIX}/billing/my-bills/${membershipId}`;
  const params = { ...jsonHeaders(customerToken), tags: { name: 'GET /billing/my-bills/:membershipId' } };

  const { res, body } = get(url, params, 'my_bills');
  expect2xx(res, 'my_bills');
  return body;
}

export function getPendingApprovals(managerToken) {
  const url = `${BASE_URL}${API_PREFIX}/billing/pending-approvals`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /billing/pending-approvals' } };

  const { res, body } = get(url, params, 'pending_approvals');
  expect2xx(res, 'pending_approvals');
  return body;
}

export function getDueBills(managerToken) {
  const url = `${BASE_URL}${API_PREFIX}/billing/due-bills`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /billing/due-bills' } };

  const { res, body } = get(url, params, 'due_bills');
  expect2xx(res, 'due_bills');
  return body;
}

export function getAllBills(managerToken, opts = {}) {
  const { status, month, year, page = 1, limit = 20 } = opts;
  const query = [];
  if (status) query.push(`status=${encodeURIComponent(status)}`);
  if (month) query.push(`month=${encodeURIComponent(month)}`);
  if (year) query.push(`year=${encodeURIComponent(year)}`);
  if (page) query.push(`page=${encodeURIComponent(page)}`);
  if (limit) query.push(`limit=${encodeURIComponent(limit)}`);
  const qs = query.length ? `?${query.join('&')}` : '';

  const url = `${BASE_URL}${API_PREFIX}/billing/all-bills${qs}`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /billing/all-bills' } };

  const { res, body } = get(url, params, 'all_bills');
  expect2xx(res, 'all_bills');
  return body;
}

export function getPaymentDetails(managerToken, billId) {
  const url = `${BASE_URL}${API_PREFIX}/billing/payment/${billId}`;
  const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /billing/payment/:billId' } };

  const { res, body } = get(url, params, 'payment_details');
  expect2xx(res, 'payment_details');
  return body;
}
