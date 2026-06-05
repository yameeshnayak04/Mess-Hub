// k6-tests/config/options.js
import { P95_MS } from './env.js';

export const options = {
  scenarios: {
    customer_journey: {
      executor: 'ramping-vus',
      stages: [
       { duration: '2m', target: 50 },
       { duration: '2m', target: 100 },
       { duration: '2m', target: 100 },
       { duration: '1m', target: 0 }
      ],
      gracefulRampDown: '30s',
      tags: { scenario: 'customer_journey' },
    },
  },

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: [`p(95)<${P95_MS}`],
    // per-scenario P95
    'http_req_duration{scenario:customer_journey}': [`p(95)<${P95_MS}`],
  },

  // Helps keep P95 clean (less TCP noise)
  noConnectionReuse: false,
  userAgent: 'k6-mess-app-tests/1.0',
};
