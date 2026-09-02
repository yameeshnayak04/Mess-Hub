// new_backend/scripts/contractCheck.js
//
// Prints the ACTUAL response shape of every endpoint the Flutter app calls,
// against a running server. This exists so frontend models are checked against
// real payloads rather than against the docs.
//
//   node scripts/contractCheck.js
const BASE = process.env.API_BASE || 'http://localhost:4000/api';

const stamp = Date.now().toString().slice(-7);
const managerPhone = `8${stamp.slice(0, 9).padEnd(9, '1')}`;
const customerPhone = `9${stamp.slice(0, 9).padEnd(9, '2')}`;
const PASSWORD = 'password123';
const PIN = '4321';

let failures = 0;

async function call(method, path, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(BASE + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const json = await res.json().catch(() => null);
  return { status: res.status, json };
}

// A compact description of a payload's shape: keys and their types, one level
// into nested objects and into the first element of arrays.
function shape(value, depth = 0) {
  if (value === null) return 'null';
  if (Array.isArray(value)) {
    return value.length === 0 ? '[]' : `[${shape(value[0], depth + 1)}]`;
  }
  if (typeof value !== 'object') return typeof value;
  if (depth > 2) return '{...}';
  const parts = Object.keys(value).map((key) => `${key}: ${shape(value[key], depth + 1)}`);
  return `{ ${parts.join(', ')} }`;
}

// Every successful payload, keyed by label, so the Flutter model tests can
// parse the real thing instead of a hand-written fixture.
const captured = {};

function report(label, result, expectedStatus = 200) {
  const ok = result.status === expectedStatus;
  if (!ok) failures += 1;
  console.log(`\n${ok ? 'ok  ' : 'FAIL'} ${label}  [${result.status}]`);
  const payload = result.json && 'data' in result.json ? result.json.data : result.json;
  console.log(ok ? `     ${shape(payload)}` : `     ${JSON.stringify(result.json)}`);
  // Only real successes are worth capturing: a time-gated route answering 400
  // is the rule working, but its error body is not a payload shape.
  if (ok && result.status < 300) captured[label] = payload;
  return payload;
}

async function main() {
  console.log(`contract check against ${BASE}`);
  const today = new Date().toISOString().slice(0, 10);

  // ---------------------------------------------------------------- auth
  const managerReg = await call('POST', '/auth/register', {
    body: { name: 'Contract Manager', phone: managerPhone, password: PASSWORD, role: 'Manager' },
  });
  report('POST /auth/register (manager)', managerReg, 201);
  const managerToken = managerReg.json?.data?.token;

  const customerReg = await call('POST', '/auth/register', {
    body: {
      name: 'Contract Customer',
      phone: customerPhone,
      password: PASSWORD,
      role: 'Customer',
      pin: PIN,
      location: { longitude: 73.8567, latitude: 18.5204 },
    },
  });
  report('POST /auth/register (customer)', customerReg, 201);
  const customerToken = customerReg.json?.data?.token;

  report('POST /auth/login', await call('POST', '/auth/login', {
    body: { phone: customerPhone, password: PASSWORD },
  }));
  report('GET /auth/me', await call('GET', '/auth/me', { token: customerToken }));

  // ---------------------------------------------------------------- mess
  const created = await call('POST', '/messes', {
    token: managerToken,
    body: {
      messName: `Contract Mess ${stamp}`,
      address: 'FC Road, Shivajinagar',
      city: 'Pune',
      contactPhone: managerPhone,
      location: { longitude: 73.8567, latitude: 18.5204 },
      serviceType: 'Both Daily & Monthly',
      cuisine: 'Both',
      maxCapacity: 50,
      tiffinService: true,
      basicThaliDetails: 'Two chapati, sabzi, rice, dal',
      lunchStart: '11:30',
      lunchEnd: '15:00',
      dinnerStart: '19:00',
      dinnerEnd: '22:30',
      dailyThaliRateRupees: 90,
      rules: {
        minLeaveDaysForRebate: 3,
        rebatePerThaliRupees: 40,
        skipAllowancePercent: 50,
        allowAbsentRebate: false,
        minMonthlyChargeRupees: 500,
        securityDepositRupees: 1000,
      },
      plans: [
        { name: 'Monthly (Both Meals)', rateRupees: 3000, meals: ['Lunch', 'Dinner'] },
        { name: 'Monthly (Lunch Only)', rateRupees: 1800, meals: ['Lunch'] },
      ],
    },
  });
  report('POST /messes', created, 201);
  const messId = created.json?.data?.messId;

  report('GET /messes/my-mess', await call('GET', '/messes/my-mess', { token: managerToken }));
  report('PATCH /messes/my-mess', await call('PATCH', '/messes/my-mess', {
    token: managerToken,
    body: { maxCapacity: 60, dailyThaliRateRupees: 95, lunchStart: '11:00', lunchEnd: '15:00' },
  }));

  // A manager's own profile, AFTER their mess exists. This is the only place
  // hasMess/messId appear - the login and register responses never carry them -
  // which is why the app has to call /auth/me once it has a token.
  report('GET /auth/me (manager with a mess)', await call('GET', '/auth/me', { token: managerToken }));

  report('GET /messes/discover', await call('GET', '/messes/discover?longitude=73.8567&latitude=18.5204&radiusKm=10', { token: customerToken }));
  report('GET /messes/:id', await call('GET', `/messes/${messId}`, { token: customerToken }));

  const plans = report('GET /messes/my-mess/plans', await call('GET', '/messes/my-mess/plans', { token: managerToken }));
  const bothMeals = (plans || []).find((plan) => plan.meals.length === 2) || (plans || [])[0];
  const planId = bothMeals?.id;
  // Keeps its own name: renaming it onto another plan's name is a real
  // duplicate and the server rightly refuses that.
  report('PATCH /messes/my-mess/plans/:id', await call('PATCH', `/messes/my-mess/plans/${planId}`, {
    token: managerToken,
    body: { name: bothMeals?.name, rateRupees: 3200, meals: bothMeals?.meals },
  }));

  // ---------------------------------------------------------- memberships
  const joined = await call('POST', `/memberships/join/${messId}`, {
    token: customerToken,
    body: { planId },
  });
  report('POST /memberships/join/:messId', joined, 201);
  const membershipId = joined.json?.data?.id;

  report('GET /memberships/mess', await call('GET', '/memberships/mess?status=Pending', { token: managerToken }));
  report('POST /memberships/:id/approve', await call('POST', `/memberships/${membershipId}/approve`, { token: managerToken }));
  report('GET /memberships/mine', await call('GET', '/memberships/mine', { token: customerToken }));
  report('GET /memberships/:id', await call('GET', `/memberships/${membershipId}`, { token: customerToken }));

  // ------------------------------------------------------------- dashboard
  report('GET /messes/my-mess/dashboard', await call('GET', '/messes/my-mess/dashboard', { token: managerToken }));
  report('GET /messes/my-mess/dashboard/members', await call('GET', '/messes/my-mess/dashboard/members?status=Remaining', { token: managerToken }));

  // ------------------------------------------------------------------ menu
  report('PUT /menus/my-mess', await call('PUT', '/menus/my-mess', {
    token: managerToken,
    body: { serviceDate: today, lunchItems: ['Paneer', 'Rice'], dinnerItems: ['Dal', 'Roti'] },
  }));
  report('GET /menus/:messId', await call('GET', `/menus/${messId}?date=${today}`, { token: customerToken }));

  // ---------------------------------------------------------------- leaves
  // Dates are IST calendar days on the server, so derive them from the server's
  // own idea of today rather than from a UTC timestamp.
  const dayAfter = (base, days) => {
    const d = new Date(`${base}T00:00:00Z`);
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
  };
  const leaveStart = dayAfter(today, 2);
  const leaveEnd = dayAfter(today, 5);
  const leave = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: leaveStart, endDate: leaveEnd, reason: 'Travelling home' },
  });
  report('POST /leave/:membershipId', leave, 201);
  report('GET /leave/:membershipId', await call('GET', `/leave/${membershipId}`, { token: customerToken }));

  // ------------------------------------------------------------ attendance
  // Skip and the kiosk actions are both time-gated to the meal being served, so
  // they only return 201 inside a meal window. Report whichever answer we get:
  // a VALIDATION_ERROR here is the rule working, not a contract mismatch.
  const skip = await call('POST', `/attendance/${membershipId}/skip`, {
    token: customerToken,
    body: { meal: 'Lunch' },
  });
  report('POST /attendance/:membershipId/skip', skip, skip.status);
  report('GET /attendance/:membershipId/calendar', await call('GET', `/attendance/${membershipId}/calendar`, { token: customerToken }));

  const kioskMark = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: PIN, meal: 'Lunch' },
  });
  report('POST /attendance/kiosk/mark', kioskMark, kioskMark.status);
  const walkin = await call('POST', '/attendance/kiosk/walkin', {
    token: managerToken,
    body: { meal: 'Lunch', quantity: 2 },
  });
  report('POST /attendance/kiosk/walkin', walkin, walkin.status);

  // The override needs a leave covering TODAY, so make one first.
  const override = await call('POST', '/attendance/kiosk/override-leave', {
    token: managerToken,
    body: { membershipId, pin: PIN, meal: 'Lunch' },
  });
  report('POST /attendance/kiosk/override-leave', override, override.status);

  // -------------------------------------------------------------- reviews
  report('PUT /reviews/:messId', await call('PUT', `/reviews/${messId}`, {
    token: customerToken,
    body: { rating: 4, comment: 'Good food, fair rebates.' },
  }));
  report('GET /reviews/:messId', await call('GET', `/reviews/${messId}`, { token: customerToken }));
  report('GET /reviews/:messId/mine', await call('GET', `/reviews/${messId}/mine`, { token: customerToken }));

  // -------------------------------------------------------------- billing
  report('POST /memberships/:id/discontinue', await call('POST', `/memberships/${membershipId}/discontinue`, { token: customerToken }));
  const myBills = report('GET /billing/membership/:id', await call('GET', `/billing/membership/${membershipId}`, { token: customerToken }));
  report('GET /billing/mess', await call('GET', '/billing/mess', { token: managerToken }));

  const billId = Array.isArray(myBills) ? myBills[0]?.id : undefined;
  if (billId) {
    report('GET /billing/:id/history', await call('GET', `/billing/${billId}/history`, { token: managerToken }));
  }

  const out = process.env.CAPTURE_TO;
  if (out) {
    require('node:fs').writeFileSync(out, JSON.stringify(captured, null, 2));
    console.log(`
captured ${Object.keys(captured).length} payloads to ${out}`);
  }

  console.log(`\n${failures === 0 ? 'all endpoints returned the expected status' : `${failures} endpoint(s) returned an unexpected status`}`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
