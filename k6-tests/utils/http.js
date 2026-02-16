// k6-tests/utils/http.js
import http from 'k6/http';
import { check } from 'k6';

export function parseJsonSafe(res) {
  try {
    return res && res.body ? JSON.parse(res.body) : null;
  } catch (_) {
    return null;
  }
}

export function expect2xx(res, label) {
  check(res, {
    [`${label} status is 2xx`]: (r) => r.status >= 200 && r.status < 300,
  });
}

export function get(url, params = {}, label = 'GET') {
  const res = http.get(url, params);
  return { res, body: parseJsonSafe(res), label };
}

export function post(url, payload, params = {}, label = 'POST') {
  const res = http.post(url, payload, params);
  return { res, body: parseJsonSafe(res), label };
}

export function put(url, payload, params = {}, label = 'PUT') {
  const res = http.put(url, payload, params);
  return { res, body: parseJsonSafe(res), label };
}
