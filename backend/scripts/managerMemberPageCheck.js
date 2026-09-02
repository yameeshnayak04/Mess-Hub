// new_backend/scripts/managerMemberPageCheck.js
//
// Every request the manager's "member details / attendance" page fires, run with
// a MANAGER token. Those routes are shared with the customer and gated by
// loadMembership, so this is the check that a manager is actually let through
// each one - and that a manager from a DIFFERENT mess is not.
//
//   node scripts/managerMemberPageCheck.js
const BASE = process.env.API_BASE || 'http://localhost:4000/api';

const stamp = Date.now().toString().slice(-6);
const PASSWORD = 'password123';

// Exactly ten digits, which is what the API requires.
function phoneFor(prefix) {
  return `${prefix}${stamp}`.padEnd(10, '0').slice(0, 10);
}

let failures = 0;

async function call(method, path, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(BASE + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, json: await res.json().catch(() => null) };
}

function check(label, result, expected) {
  const ok = result.status === expected;
  if (!ok) failures += 1;
  const detail = ok ? '' : `  ${JSON.stringify(result.json)}`;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${label}  [${result.status}]${detail}`);
  return ok;
}

async function makeManager(prefix, city) {
  const phone = phoneFor(prefix);
  const reg = await call('POST', '/auth/register', {
    body: { name: `Mgr ${prefix}`, phone, password: PASSWORD, role: 'Manager' },
  });
  const token = reg.json.data.token;

  const created = await call('POST', '/messes', {
    token,
    body: {
      messName: `Mess ${prefix}${stamp}`,
      address: `${city} Main Road 11`,
      city,
      contactPhone: phone,
      location: { longitude: 73.85, latitude: 18.52 },
      serviceType: 'Monthly Only',
      cuisine: 'Veg',
      maxCapacity: 30,
      tiffinService: false,
      basicThaliDetails: 'Chapati, sabzi, dal, rice',
      lunchStart: '11:30',
      lunchEnd: '15:00',
      dinnerStart: '19:00',
      dinnerEnd: '22:30',
      rules: { minLeaveDaysForRebate: 3, rebatePerThaliRupees: 40 },
      plans: [{ name: 'Both Meals', rateRupees: 3000, meals: ['Lunch', 'Dinner'] }],
    },
  });

  return {
    token,
    messId: created.json.data.messId,
    planId: created.json.data.plans[0].id,
  };
}

async function main() {
  const owner = await makeManager('4', 'Pune');
  const stranger = await makeManager('3', 'Nashik');

  // A customer who joins the first mess and gets approved.
  const customerPhone = phoneFor('2');
  const customer = await call('POST', '/auth/register', {
    body: {
      name: 'Page Customer',
      phone: customerPhone,
      password: PASSWORD,
      role: 'Customer',
      pin: '2244',
      location: { longitude: 73.85, latitude: 18.52 },
    },
  });
  const customerToken = customer.json.data.token;

  const joined = await call('POST', `/memberships/join/${owner.messId}`, {
    token: customerToken,
    body: { planId: owner.planId },
  });
  const membershipId = joined.json.data.id;
  await call('POST', `/memberships/${membershipId}/approve`, { token: owner.token });

  const today = new Date().toISOString().slice(0, 10);
  const month = Number(today.slice(5, 7));
  const year = Number(today.slice(0, 4));

  console.log('--- the page, as the owning manager');
  check(
    'GET /memberships/:id            (member info card)',
    await call('GET', `/memberships/${membershipId}`, { token: owner.token }),
    200
  );
  check(
    'GET /attendance/:id/calendar    (attendance calendar)',
    await call('GET', `/attendance/${membershipId}/calendar?month=${month}&year=${year}`, {
      token: owner.token,
    }),
    200
  );
  check(
    'GET /leave/:id                  (leave history card)',
    await call('GET', `/leave/${membershipId}`, { token: owner.token }),
    200
  );
  check(
    'GET /billing/membership/:id     (payment history card)',
    await call('GET', `/billing/membership/${membershipId}`, { token: owner.token }),
    200
  );
  check(
    'GET /messes/:messId             (plan meals for the filter)',
    await call('GET', `/messes/${owner.messId}`, { token: owner.token }),
    200
  );

  console.log('\n--- the calendar without month/year, the way the page first loads it');
  check(
    'GET /attendance/:id/calendar    (no query)',
    await call('GET', `/attendance/${membershipId}/calendar`, { token: owner.token }),
    200
  );

  console.log('\n--- the member themselves still gets through');
  check(
    'GET /attendance/:id/calendar    (as the customer)',
    await call('GET', `/attendance/${membershipId}/calendar`, { token: customerToken }),
    200
  );

  console.log('\n--- a manager from another mess must not');
  check(
    'GET /memberships/:id            (stranger)',
    await call('GET', `/memberships/${membershipId}`, { token: stranger.token }),
    403
  );
  check(
    'GET /attendance/:id/calendar    (stranger)',
    await call('GET', `/attendance/${membershipId}/calendar`, { token: stranger.token }),
    403
  );
  check(
    'GET /leave/:id                  (stranger)',
    await call('GET', `/leave/${membershipId}`, { token: stranger.token }),
    403
  );
  check(
    'GET /billing/membership/:id     (stranger)',
    await call('GET', `/billing/membership/${membershipId}`, { token: stranger.token }),
    403
  );

  console.log(
    `\n${failures === 0 ? 'manager member page verified' : `${failures} check(s) failed`}`
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
