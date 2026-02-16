// k6-tests/tests/core-flow.test.js
import { options } from '../config/options.js';
import { sleep } from 'k6';

import { getCustomerToken } from '../flows/auth.flow.js';
import { discoverMesses, getMessById } from '../flows/discovery.flow.js';
import { getMyMemberships } from '../flows/membership.flow.js';

export { options };

export default function () {
  const customerToken = getCustomerToken();

  // 1) Discover
  const discover = discoverMesses(customerToken);
  sleep(1);

  // 2) Fetch one mess details if available
  const messId =
    discover && discover.data && discover.data.length
      ? (discover.data[0]._id || discover.data[0].id)
      : null;

  if (messId) {
    getMessById(customerToken, messId);
  }
  sleep(1);

  // 3) Memberships
  getMyMemberships(customerToken);
  sleep(1);
}
