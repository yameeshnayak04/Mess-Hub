// k6-tests/utils/headers.js
export function jsonHeaders(token = null, extra = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...extra,
  };

  if (token) headers.Authorization = `Bearer ${token}`;
  return { headers };
}
