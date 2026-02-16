// k6-tests/tests/manager-dashboard.test.js
import { sleep } from 'k6';
import { options as baseOptions } from '../config/options.js';
import { getManagerToken } from '../flows/auth.flow.js';
import { getManagerDashboardStats } from '../flows/managerDash.flow.js';

export const options = {
  ...baseOptions,
  scenarios: {
    manager_dash: {
      executor: 'constant-vus',
      vus: 10,
      duration: '2m',
      tags: { scenario: 'manager_dash' },
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<2000'],
    'http_req_duration{scenario:manager_dash}': ['p(95)<2000'],
  },
};

export default function () {
  const managerToken = getManagerToken();
  getManagerDashboardStats(managerToken);
  sleep(1);
}
