// k6-tests/flows/membership.flow.js
import { BASE_URL, API_PREFIX } from '../config/env.js';
import { jsonHeaders } from '../utils/headers.js';
import { get, post, put, expect2xx } from '../utils/http.js';

export function getMyMemberships(customerToken) {
  const url = `${BASE_URL}${API_PREFIX}/membership/my-memberships`; // customer-only [file:7]
  const params = { ...jsonHeaders(customerToken), tags: { name: 'GET /membership/my-memberships' } };

  const { res, body } = get(url, params, 'my_memberships');
  expect2xx(res, 'my_memberships');
  return body;
}

export function joinMess(customerToken, messId, planName = 'Lunch') {
  const url = `${BASE_URL}${API_PREFIX}/membership/join/${messId}`; // customer-only [file:7]
  const payload = JSON.stringify({ planName });
  const params = { ...jsonHeaders(customerToken), tags: { name: 'POST /membership/join/:messId' } };

  const { res, body } = post(url, payload, params, 'join_mess');
  expect2xx(res, 'join_mess');
  return body;
}

export function approveMembership(managerToken, membershipId) {
  const url = `${BASE_URL}${API_PREFIX}/membership/approve/${membershipId}`; // manager-only [file:7]
  const params = { ...jsonHeaders(managerToken), tags: { name: 'PUT /membership/approve/:membershipId' } };

  const { res, body } = put(url, null, params, 'approve_membership');
  expect2xx(res, 'approve_membership');
  return body;
}
