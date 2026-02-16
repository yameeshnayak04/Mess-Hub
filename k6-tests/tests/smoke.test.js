// k6-tests/tests/smoke.test.js
import { options as baseOptions } from '../config/options.js';
import { getCustomerToken } from '../flows/auth.flow.js';
import { discoverMesses } from '../flows/discovery.flow.js';

export const options = {
  ...baseOptions,
  scenarios: {
    smoke: { executor: 'per-vu-iterations', vus: 1, iterations: 1 },
  },
  thresholds: { http_req_failed: ['rate<0.01'] },
};

export default function () {
  const token = getCustomerToken();
  discoverMesses(token);
}
