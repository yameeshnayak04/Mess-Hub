// k6-tests/flows/discovery.flow.js
import { BASE_URL, API_PREFIX } from '../config/env.js';
import { jsonHeaders } from '../utils/headers.js';
import { get, expect2xx } from '../utils/http.js';

export function discoverMesses(customerToken) {
  // Your route is customer-protected: protect + authorize('Customer') [file:9]
  const url = `${BASE_URL}${API_PREFIX}/mess/discover`;
  const params = { ...jsonHeaders(customerToken), tags: { name: 'GET /mess/discover' } };

  const { res, body } = get(url, params, 'discover_messes');
  expect2xx(res, 'discover_messes');
  return body;
}

export function getMessById(anyAuthToken, messId) {
  // Route is protected (protect), any authenticated user can call [file:9]
  const url = `${BASE_URL}${API_PREFIX}/mess/${messId}`;
  const params = { ...jsonHeaders(anyAuthToken), tags: { name: 'GET /mess/:messId' } };

  const { res, body } = get(url, params, 'get_mess_by_id');
  expect2xx(res, 'get_mess_by_id');
  return body;
}
