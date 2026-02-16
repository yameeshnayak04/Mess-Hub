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
