# k6-tests

## Prereqs
- k6 installed
- Your backend running and reachable

## Required env vars
export BASE_URL="https://mess-hub-backend.onrender.com"
export API_PREFIX="/api"

export CUSTOMER_PHONE="9999999999"
export CUSTOMER_PASSWORD="password123"

export MANAGER_PHONE="8888888888"
export MANAGER_PASSWORD="password123"

# optional
export P95_MS="2000"

## Run smoke test
k6 run tests/smoke.test.js

## Run customer core flow (P95)
k6 run tests/core-flow.test.js

## Run manager dashboard load
k6 run tests/manager-dashboard.test.js

## Notes for clean P95
- Prefer read-heavy journeys in load (discover, details, list).
- Avoid mutation endpoints (join/approve/skip/menu writes) inside a high-iteration load test unless you also design unique test data per iteration.
