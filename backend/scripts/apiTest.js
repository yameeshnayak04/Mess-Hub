#!/usr/bin/env node
/*
 * Full API integration test.
 *
 * Unlike the unit tests in services/, this drives the real HTTP API against a
 * running server and checks the actual values that come back - not just that
 * a request returned 200. It also records how long every call took.
 *
 * Run with the stack up:   npm run test:api
 */

const BASE = process.env.API_BASE || 'http://localhost:4000';
const API = `${BASE}/api`;

let passed = 0;
let failed = 0;
const failures = [];
const timings = [];

function check(label, condition, detail = '') {
  if (condition) {
    passed += 1;
    console.log(`  ok    ${label}`);
  } else {
    failed += 1;
    failures.push(`${label}${detail ? ` -- ${detail}` : ''}`);
    console.log(`  FAIL  ${label}${detail ? `\n          ${detail}` : ''}`);
  }
}

function section(name) {
  console.log(`\n=== ${name} ===`);
}

async function call(method, path, { token, body, raw } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  const startedAt = process.hrtime.bigint();
  const response = await fetch(`${API}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : raw ? body : JSON.stringify(body),
  });
  const elapsedMs = Number(process.hrtime.bigint() - startedAt) / 1e6;

  let json;
  try {
    json = await response.json();
  } catch {
    json = null;
  }

  timings.push({ route: `${method} ${path.split('?')[0]}`, ms: elapsedMs });
  return { status: response.status, json, ms: elapsedMs };
}

// Two-digit clock helper for building mess timings.
const hhmm = (h, m) => `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;

function istNow() {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Kolkata',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(new Date());
  const get = (type) => Number(parts.find((p) => p.type === type).value);
  return { hour: get('hour'), minute: get('minute') };
}

function todayIst() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
}

function addDays(dateString, days) {
  const date = new Date(`${dateString}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

const stamp = Date.now().toString().slice(-9);
// Phone numbers are unique in the database, so each run needs fresh ones -
// seed from the clock rather than a fixed number, or a second run collides.
let phoneSeed = Number(stamp);
const nextPhone = () => String(9000000000 + (phoneSeed++ % 1000000000));

function messPayload(name, { lunch, dinner, serviceType = 'Both Daily & Monthly', extras = {} }) {
  return {
    messName: `${name} ${stamp}`,
    address: `${stamp} ${name} Road`,
    city: 'Pune',
    contactPhone: nextPhone(),
    location: { longitude: 73.8567, latitude: 18.5204 },
    serviceType,
    cuisine: 'Veg',
    maxCapacity: 50,
    tiffinService: true,
    basicThaliDetails: 'Roti, sabzi, dal, chawal, salad',
    lunchStart: lunch[0],
    lunchEnd: lunch[1],
    dinnerStart: dinner[0],
    dinnerEnd: dinner[1],
    dailyThaliRateRupees: 90,
    rules: {
      minLeaveDaysForRebate: 4,
      rebatePerThaliRupees: 50,
      skipAllowancePercent: 20,
      allowAbsentRebate: false,
      minMonthlyChargeRupees: 1200,
      securityDepositRupees: 2000,
    },
    plans: [
      { name: 'Both Meals', rateRupees: 6000, meals: ['Lunch', 'Dinner'] },
      { name: 'Lunch Only', rateRupees: 3500, meals: ['Lunch'] },
    ],
    ...extras,
  };
}

async function main() {
  const now = istNow();
  console.log(`IST now: ${hhmm(now.hour, now.minute)}   date: ${todayIst()}`);

  // Warm the process up so the first real measurement is not a cold start.
  await call('GET', '/../health');

  // ---------------------------------------------------------------- health
  section('health');
  {
    const r = await fetch(`${BASE}/health`);
    const body = await r.json();
    check(
      'GET /health returns ok + db connected',
      r.status === 200 && body.database === 'connected',
      JSON.stringify(body)
    );
  }

  // ---------------------------------------------------------------- auth
  section('auth');
  const managerPhone = nextPhone();
  const customerPhone = nextPhone();
  const customer2Phone = nextPhone();

  let r = await call('POST', '/auth/register', {
    body: { name: 'Meera Manager', phone: managerPhone, password: 'password123', role: 'Manager' },
  });
  check('POST /auth/register (manager) -> 201', r.status === 201, JSON.stringify(r.json));
  check(
    '  returns the user we sent',
    r.json?.data?.user?.name === 'Meera Manager' &&
      r.json?.data?.user?.phone === managerPhone &&
      r.json?.data?.user?.role === 'Manager'
  );
  check(
    '  id is a number, not a string',
    typeof r.json?.data?.user?.id === 'number',
    `got ${typeof r.json?.data?.user?.id}`
  );
  check('  token looks like a JWT', (r.json?.data?.token || '').split('.').length === 3);
  check(
    '  never leaks password_hash / pin_hash',
    !JSON.stringify(r.json).includes('password_hash') &&
      !JSON.stringify(r.json).includes('pin_hash')
  );
  const managerToken = r.json.data.token;

  r = await call('POST', '/auth/register', {
    body: {
      name: 'Chirag Customer',
      phone: customerPhone,
      password: 'password123',
      role: 'Customer',
      pin: '4321',
      location: { longitude: 73.85, latitude: 18.52 },
    },
  });
  check('POST /auth/register (customer) -> 201', r.status === 201, JSON.stringify(r.json));
  const customerToken = r.json.data.token;

  r = await call('POST', '/auth/register', {
    body: {
      name: 'Second Customer',
      phone: customer2Phone,
      password: 'password123',
      role: 'Customer',
      pin: '1111',
      location: { longitude: 73.85, latitude: 18.52 },
    },
  });
  const customer2Token = r.json.data.token;
  check('POST /auth/register (2nd customer) -> 201', r.status === 201);

  // A customer who never joins anything, so the "not a member" cases stay
  // valid even as the other customers gain memberships later on.
  r = await call('POST', '/auth/register', {
    body: {
      name: 'Outsider',
      phone: nextPhone(),
      password: 'password123',
      role: 'Customer',
      pin: '2222',
      location: { longitude: 73.85, latitude: 18.52 },
    },
  });
  const outsiderToken = r.json.data.token;
  check('POST /auth/register (non-member) -> 201', r.status === 201);

  r = await call('POST', '/auth/register', {
    body: { name: 'Dup', phone: managerPhone, password: 'password123', role: 'Manager' },
  });
  check(
    'duplicate phone rejected -> 400 PHONE_TAKEN',
    r.status === 400 && r.json?.code === 'PHONE_TAKEN',
    JSON.stringify(r.json)
  );

  r = await call('POST', '/auth/register', {
    body: { name: 'NoPin', phone: nextPhone(), password: 'password123', role: 'Customer' },
  });
  check('customer without pin/location rejected', r.status === 400, JSON.stringify(r.json));

  r = await call('POST', '/auth/register', {
    body: {
      name: 'M',
      phone: managerPhone,
      password: 'password123',
      role: 'Manager',
      pin: '1234',
      location: { longitude: 1, latitude: 1 },
    },
  });
  check('manager sending pin/location rejected (forbidden fields)', r.status === 400);

  r = await call('POST', '/auth/login', { body: { phone: managerPhone, password: 'password123' } });
  check('POST /auth/login -> 200 with token', r.status === 200 && Boolean(r.json?.data?.token));

  r = await call('POST', '/auth/login', { body: { phone: managerPhone, password: 'wrong' } });
  check(
    'wrong password -> 401 BAD_CREDENTIALS',
    r.status === 401 && r.json?.code === 'BAD_CREDENTIALS'
  );

  r = await call('POST', '/auth/login', { body: { phone: '9999999999', password: 'whatever' } });
  check(
    'unknown phone gives the SAME error (no user enumeration)',
    r.status === 401 && r.json?.code === 'BAD_CREDENTIALS',
    JSON.stringify(r.json)
  );

  r = await call('GET', '/auth/me', { token: managerToken });
  check(
    'GET /auth/me -> hasMess false before setup',
    r.status === 200 && r.json?.data?.hasMess === false,
    JSON.stringify(r.json)
  );

  r = await call('GET', '/auth/me');
  check(
    'GET /auth/me without token -> 401',
    r.status === 401 && r.json?.code === 'UNAUTHENTICATED'
  );

  r = await call('GET', '/auth/me', { token: 'not-a-real-token' });
  check('GET /auth/me with junk token -> 401', r.status === 401);

  r = await call('PATCH', '/auth/me', { token: customerToken, body: { name: 'Chirag Updated' } });
  check(
    'PATCH /auth/me updates the name',
    r.status === 200 && r.json?.data?.name === 'Chirag Updated',
    JSON.stringify(r.json)
  );

  r = await call('PATCH', '/auth/me', { token: customerToken, body: { pin: '8888' } });
  check('PATCH /auth/me accepts a new PIN', r.status === 200);

  r = await call('PATCH', '/auth/me', { token: managerToken, body: { pin: '8888' } });
  check('manager cannot set a kiosk PIN', r.status === 400, JSON.stringify(r.json));

  r = await call('POST', '/auth/logout', { token: managerToken });
  check('POST /auth/logout -> 200', r.status === 200);

  // ---------------------------------------------------------------- mess
  section('mess setup');
  // Lunch covers nearly the whole day so "a meal is being served now" is true
  // and the kiosk / skip / walk-in paths can actually be exercised.
  const openMess = messPayload('Open Mess', {
    lunch: ['00:00', '22:59'],
    dinner: ['23:00', '23:59'],
  });

  r = await call('POST', '/messes', { token: managerToken, body: openMess });
  check('POST /messes -> 201', r.status === 201, JSON.stringify(r.json));
  check(
    '  returns messId + both plans',
    typeof r.json?.data?.messId === 'number' && r.json?.data?.plans?.length === 2
  );
  check(
    '  plan rate echoes back in rupees, not raw stored units',
    r.json?.data?.plans?.[0]?.rateRupees === 6000,
    JSON.stringify(r.json?.data?.plans?.[0])
  );
  check(
    '  plan meals are a real list',
    JSON.stringify(r.json?.data?.plans?.[0]?.meals) === '["Lunch","Dinner"]'
  );
  const messId = r.json.data.messId;
  const bothMealsPlanId = r.json.data.plans.find((p) => p.name === 'Both Meals').id;
  const lunchOnlyPlanId = r.json.data.plans.find((p) => p.name === 'Lunch Only').id;

  r = await call('POST', '/messes', {
    token: managerToken,
    body: messPayload('Dupe', { lunch: ['09:00', '10:00'], dinner: ['19:00', '20:00'] }),
  });
  check('second mess for same manager rejected', r.status === 400, JSON.stringify(r.json));

  r = await call('POST', '/messes', { token: customerToken, body: openMess });
  check('customer cannot create a mess -> 403', r.status === 403 && r.json?.code === 'FORBIDDEN');

  r = await call('POST', '/messes', {
    token: managerToken,
    body: { ...messPayload('Bad', { lunch: ['14:00', '12:00'], dinner: ['19:00', '20:00'] }) },
  });
  check('lunch ending before it starts is rejected', r.status >= 400, JSON.stringify(r.json));

  r = await call('GET', '/auth/me', { token: managerToken });
  check(
    'GET /auth/me now reports hasMess true + messId',
    r.json?.data?.hasMess === true && r.json?.data?.messId === messId
  );

  r = await call('GET', '/messes/my-mess', { token: managerToken });
  check('GET /messes/my-mess -> 200', r.status === 200);
  check(
    '  timings come back as HH:MM strings',
    r.json?.data?.timings?.lunchStart === '00:00' && r.json?.data?.timings?.dinnerEnd === '23:59',
    JSON.stringify(r.json?.data?.timings)
  );
  check(
    '  location round-trips correctly',
    Math.abs(r.json?.data?.location?.longitude - 73.8567) < 0.0001 &&
      Math.abs(r.json?.data?.location?.latitude - 18.5204) < 0.0001,
    JSON.stringify(r.json?.data?.location)
  );
  check(
    '  rules echo back in rupees',
    r.json?.data?.rules?.rebatePerThaliRupees === 50 &&
      r.json?.data?.rules?.minMonthlyChargeRupees === 1200 &&
      r.json?.data?.rules?.securityDepositRupees === 2000,
    JSON.stringify(r.json?.data?.rules)
  );
  check('  starts with an empty rating', r.json?.data?.rating?.count === 0);

  r = await call('PATCH', '/messes/my-mess', { token: managerToken, body: { maxCapacity: 75 } });
  check(
    'PATCH /messes/my-mess updates capacity',
    r.status === 200 && r.json?.data?.maxCapacity === 75
  );

  r = await call('PATCH', '/messes/my-mess', {
    token: managerToken,
    body: { rules: { rebatePerThaliRupees: 60 } },
  });
  check(
    'PATCH updates a single nested rule',
    r.status === 200 && r.json?.data?.rules?.rebatePerThaliRupees === 60,
    JSON.stringify(r.json?.data?.rules)
  );
  await call('PATCH', '/messes/my-mess', {
    token: managerToken,
    body: { rules: { rebatePerThaliRupees: 50 } },
  });

  r = await call('PATCH', '/messes/my-mess', { token: managerToken, body: {} });
  check('PATCH with empty body -> 400', r.status === 400);

  r = await call('GET', `/messes/${messId}`, { token: customerToken });
  check('GET /messes/:id (customer view) -> 200', r.status === 200);
  check(
    '  includes plans and live status',
    r.json?.data?.plans?.length === 2 && ['Open', 'Closed'].includes(r.json?.data?.liveStatus)
  );
  check(
    '  a meal is currently being served',
    r.json?.data?.currentMeal === 'Lunch',
    `currentMeal=${r.json?.data?.currentMeal}`
  );

  r = await call('GET', '/messes/999999999', { token: customerToken });
  check('GET /messes/<missing> -> 404', r.status === 404 && r.json?.code === 'NOT_FOUND');

  // ---------------------------------------------------------------- plans
  section('plans');
  r = await call('GET', '/messes/my-mess/plans', { token: managerToken });
  check('GET my-mess/plans lists both', r.status === 200 && r.json?.data?.length === 2);

  r = await call('POST', '/messes/my-mess/plans', {
    token: managerToken,
    body: { name: 'Dinner Only', rateRupees: 3200, meals: ['Dinner'] },
  });
  check('POST adds a plan', r.status === 201 && r.json?.data?.rateRupees === 3200);
  const dinnerPlanId = r.json.data.id;

  r = await call('PATCH', `/messes/my-mess/plans/${dinnerPlanId}`, {
    token: managerToken,
    body: { name: 'Dinner Only', rateRupees: 3400, meals: ['Dinner'] },
  });
  check('PATCH updates a plan rate', r.status === 200 && r.json?.data?.rateRupees === 3400);

  r = await call('DELETE', `/messes/my-mess/plans/${dinnerPlanId}`, { token: managerToken });
  check('DELETE retires an unused plan', r.status === 200 && r.json?.data?.isActive === false);

  r = await call('GET', `/messes/${messId}/plans`, { token: customerToken });
  check('retired plan hidden from customers', r.status === 200 && r.json?.data?.length === 2);

  // ---------------------------------------------------------------- discovery
  section('discovery');
  r = await call('GET', '/messes/discover', { token: customerToken });
  check('GET /messes/discover -> 200', r.status === 200);
  check('  includes a real distance', typeof r.json?.data?.[0]?.distanceMetres === 'number');
  check(
    '  results are nearest-first',
    r.json.data.every((m, i, arr) => i === 0 || arr[i - 1].distanceMetres <= m.distanceMetres)
  );
  check(
    '  has pagination meta',
    typeof r.json?.meta?.total === 'number' && typeof r.json?.meta?.hasNextPage === 'boolean'
  );

  r = await call('GET', '/messes/discover?limit=1', { token: customerToken });
  check('  respects ?limit', r.json?.data?.length === 1 && r.json?.meta?.limit === 1);

  r = await call('GET', '/messes/discover?cuisine=Non-Veg', { token: customerToken });
  check(
    '  cuisine filter excludes our Veg mess',
    !r.json.data.some((m) => m.id === messId),
    JSON.stringify(r.json?.meta)
  );

  r = await call('GET', '/messes/discover?limit=999', { token: customerToken });
  check(
    '  limit above the 100 maximum -> 400 (explicit, not silently clamped)',
    r.status === 400 && r.json?.code === 'VALIDATION_ERROR',
    JSON.stringify(r.json)
  );

  r = await call('GET', '/messes/discover?cuisine=Purple', { token: customerToken });
  check('  invalid cuisine -> 400', r.status === 400 && r.json?.code === 'VALIDATION_ERROR');

  r = await call('GET', '/messes/discover', { token: managerToken });
  check('  manager cannot use customer discovery -> 403', r.status === 403);

  // ---------------------------------------------------------------- menu
  section('menus');
  const today = todayIst();
  r = await call('PUT', '/menus/my-mess', {
    token: managerToken,
    body: {
      serviceDate: today,
      lunchItems: ['Roti', 'Dal', 'Rice'],
      dinnerItems: ['Paneer', 'Naan'],
    },
  });
  check('PUT /menus/my-mess -> 200', r.status === 200);
  check(
    '  stores both item lists',
    JSON.stringify(r.json?.data?.lunchItems) === '["Roti","Dal","Rice"]' &&
      r.json?.data?.dinnerItems?.length === 2
  );

  r = await call('PUT', '/menus/my-mess', {
    token: managerToken,
    body: { serviceDate: today, lunchItems: ['Poha'], dinnerItems: ['Khichdi'] },
  });
  check(
    '  re-posting the same date overwrites it',
    JSON.stringify(r.json?.data?.lunchItems) === '["Poha"]'
  );

  r = await call('GET', `/menus/${messId}`, { token: customerToken });
  check(
    'GET /menus/:messId returns today by default',
    r.status === 200 && r.json?.data?.length === 1 && r.json.data[0].lunchItems[0] === 'Poha'
  );

  r = await call('GET', `/menus/${messId}?from=${today}&to=${addDays(today, 3)}`, {
    token: customerToken,
  });
  check('  accepts a date range', r.status === 200 && Array.isArray(r.json?.data));

  r = await call('PUT', '/menus/my-mess', {
    token: managerToken,
    body: { serviceDate: 'not-a-date' },
  });
  check('  invalid date -> 400', r.status === 400);

  // ---------------------------------------------------------------- membership
  section('membership lifecycle');
  r = await call('POST', `/memberships/join/${messId}`, {
    token: customerToken,
    body: { planId: bothMealsPlanId },
  });
  check(
    'POST /memberships/join -> 201 Pending',
    r.status === 201 && r.json?.data?.status === 'Pending',
    JSON.stringify(r.json)
  );
  check(
    '  reports the current plan rate (live pricing, not a snapshot)',
    r.json?.data?.rateRupees === 6000
  );
  const membershipId = r.json.data.id;

  r = await call('POST', `/memberships/join/${messId}`, {
    token: customerToken,
    body: { planId: bothMealsPlanId },
  });
  check('joining twice is rejected', r.status === 409, JSON.stringify(r.json));

  r = await call('POST', `/memberships/join/${messId}`, {
    token: customerToken,
    body: { planId: 999999 },
  });
  check('joining with a bogus plan -> 400', r.status === 400);

  r = await call('GET', '/memberships/mine', { token: customerToken });
  check(
    'GET /memberships/mine lists it',
    r.status === 200 && r.json?.data?.some((m) => m.id === membershipId)
  );
  check('  includes the mess name for display', Boolean(r.json?.data?.[0]?.messName));

  r = await call('GET', '/memberships/mess?status=Pending', { token: managerToken });
  check(
    'manager sees the pending request',
    r.status === 200 && r.json?.data?.some((m) => m.id === membershipId)
  );
  check(
    '  includes member name + phone',
    Boolean(r.json?.data?.[0]?.memberName && r.json?.data?.[0]?.memberPhone)
  );
  check('  paginated', typeof r.json?.meta?.total === 'number');

  r = await call('GET', `/memberships/${membershipId}`, { token: outsiderToken });
  check('another customer cannot read this membership -> 403', r.status === 403);

  r = await call('POST', `/memberships/${membershipId}/approve`, { token: customerToken });
  check('customer cannot approve their own membership -> 403', r.status === 403);

  r = await call('POST', `/memberships/${membershipId}/approve`, { token: managerToken });
  check(
    'POST approve -> Active',
    r.status === 200 && r.json?.data?.status === 'Active',
    JSON.stringify(r.json)
  );
  check('  joinedDate set to today', String(r.json?.data?.joinedDate).startsWith(today));

  r = await call('POST', `/memberships/${membershipId}/approve`, { token: managerToken });
  check('approving twice -> 400', r.status === 400);

  r = await call('GET', `/memberships/${membershipId}`, { token: customerToken });
  check('GET membership details -> 200', r.status === 200);
  check(
    '  has month-to-date attendance summary',
    typeof r.json?.data?.monthToDate?.present === 'number'
  );
  check("  includes today's menu", r.json?.data?.todaysMenu?.lunchItems?.[0] === 'Poha');
  check('  includes recent bills array', Array.isArray(r.json?.data?.recentBills));

  r = await call('GET', `/memberships/${membershipId}`, { token: managerToken });
  check('manager can read their own member', r.status === 200);

  // ---------------------------------------------------------------- attendance
  section('attendance');
  r = await call('GET', `/attendance/${membershipId}/calendar`, { token: customerToken });
  check('GET calendar -> 200', r.status === 200 && Array.isArray(r.json?.data?.days));

  r = await call('GET', `/attendance/${membershipId}/calendar?month=13`, { token: customerToken });
  check('  invalid month -> 400', r.status === 400);

  r = await call('POST', `/attendance/${membershipId}/skip`, {
    token: customerToken,
    body: { meal: 'Dinner' },
  });
  check(
    'POST skip dinner -> 201 Skipped',
    r.status === 201 && r.json?.data?.status === 'Skipped',
    JSON.stringify(r.json)
  );

  r = await call('POST', `/attendance/${membershipId}/skip`, {
    token: customerToken,
    body: { meal: 'Dinner' },
  });
  check('skipping the same meal twice -> 409', r.status === 409, JSON.stringify(r.json));

  r = await call('POST', `/attendance/${membershipId}/skip`, {
    token: customerToken,
    body: { meal: 'Brunch' },
  });
  check('invalid meal name -> 400', r.status === 400);

  r = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: '0000', meal: 'Lunch' },
  });
  check('kiosk with wrong PIN -> 401 BAD_PIN', r.status === 401 && r.json?.code === 'BAD_PIN');

  r = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: '8888', meal: 'Lunch' },
  });
  check(
    'kiosk with correct PIN -> 201 Present',
    r.status === 201 && r.json?.data?.status === 'Present',
    JSON.stringify(r.json)
  );

  r = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: '8888', meal: 'Lunch' },
  });
  check('kiosk cannot mark the same meal twice -> 409', r.status === 409);

  r = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: '8888', meal: 'Dinner' },
  });
  check(
    'kiosk refuses a meal that is not being served now',
    r.status === 400 && /not being served/.test(r.json?.message || ''),
    JSON.stringify(r.json)
  );

  // The overwrite guard has to be tested on the meal that is actually being
  // served, otherwise the "is this meal on right now" check rejects first and
  // we never reach it. Second customer skips lunch, then turns up anyway.
  r = await call('POST', `/memberships/join/${messId}`, {
    token: customer2Token,
    body: { planId: lunchOnlyPlanId },
  });
  const membership2Id = r.json.data.id;
  await call('POST', `/memberships/${membership2Id}/approve`, { token: managerToken });

  r = await call('POST', `/attendance/${membership2Id}/skip`, {
    token: customer2Token,
    body: { meal: 'Lunch' },
  });
  check('second member skips lunch -> 201', r.status === 201, JSON.stringify(r.json));

  r = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId: membership2Id, pin: '1111', meal: 'Lunch' },
  });
  check(
    'kiosk refuses to overwrite an existing Skipped record',
    r.status === 409 && /Skipped/.test(r.json?.message || ''),
    JSON.stringify(r.json)
  );

  r = await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId: membership2Id, pin: '1111', meal: 'Dinner' },
  });
  check(
    'kiosk rejects a meal the plan does not cover',
    r.status === 400 && /does not include/.test(r.json?.message || ''),
    JSON.stringify(r.json)
  );

  // The override endpoint is only for a member who is genuinely mid-leave.
  // Its full behaviour (what happens to the leave row) is covered by the
  // leaveOverride unit tests; here we just prove it is wired up and guarded.
  r = await call('POST', '/attendance/kiosk/override-leave', {
    token: managerToken,
    body: { membershipId, pin: '8888', meal: 'Lunch' },
  });
  check(
    'override-leave refuses when today is not a Leave day',
    r.status === 400 && /not marked as Leave|marked as Present today/.test(r.json?.message || ''),
    JSON.stringify(r.json)
  );

  r = await call('POST', '/attendance/kiosk/override-leave', {
    token: managerToken,
    body: { membershipId, pin: '0000', meal: 'Lunch' },
  });
  check('override-leave still checks the PIN', r.status === 401 && r.json?.code === 'BAD_PIN');

  r = await call('POST', '/attendance/kiosk/override-leave', {
    token: customerToken,
    body: { membershipId, pin: '8888', meal: 'Lunch' },
  });
  check('customer cannot use override-leave -> 403', r.status === 403);

  r = await call('POST', '/attendance/kiosk/mark', {
    token: customerToken,
    body: { membershipId, pin: '8888', meal: 'Lunch' },
  });
  check('customer cannot use the kiosk endpoint -> 403', r.status === 403);

  r = await call('GET', `/attendance/${membershipId}/calendar`, { token: customerToken });
  const todaysMeals = r.json?.data?.days?.find((d) => d.date === today)?.meals;
  check(
    "calendar now shows both of today's records",
    todaysMeals?.Lunch === 'Present' && todaysMeals?.Dinner === 'Skipped',
    JSON.stringify(todaysMeals)
  );

  r = await call('POST', '/attendance/kiosk/walkin', {
    token: managerToken,
    body: { meal: 'Lunch', quantity: 3 },
  });
  check('POST walk-in sale -> 201', r.status === 201, JSON.stringify(r.json));
  check(
    '  charges the daily rate x quantity',
    r.json?.data?.quantity === 3 && r.json?.data?.totalRupees === 270,
    JSON.stringify(r.json?.data)
  );

  // ---------------------------------------------------------------- dashboard
  section('manager dashboard');
  r = await call('GET', '/messes/my-mess/dashboard', { token: managerToken });
  check('GET dashboard -> 200', r.status === 200, JSON.stringify(r.json));
  const counts = r.json?.data?.counts;
  check('  reports the live meal', r.json?.data?.currentMeal === 'Lunch');
  check('  counts our present member', counts?.eating === 1, JSON.stringify(counts));
  check('  counts the 3 walk-ins', counts?.walkins === 3, JSON.stringify(counts));
  check(
    '  numbers add up (eligible = eating+skipped+leave+absent+remaining)',
    counts.eligible ===
      counts.eating + counts.skipped + counts.onLeave + counts.absent + counts.remaining,
    JSON.stringify(counts)
  );
  check("  includes today's menu", r.json?.data?.todaysMenu?.lunchItems?.[0] === 'Poha');

  r = await call('GET', '/messes/my-mess/dashboard?meal=Dinner', { token: managerToken });
  check(
    '  dashboard can be asked about Dinner',
    r.json?.data?.meal === 'Dinner' && r.json?.data?.counts?.skipped === 1,
    JSON.stringify(r.json?.data?.counts)
  );

  r = await call('GET', '/messes/my-mess/dashboard/members?status=Present&meal=Lunch', {
    token: managerToken,
  });
  check(
    'drill-down Present lists the member',
    r.status === 200 && r.json?.data?.length === 1 && r.json.data[0].membershipId === membershipId,
    JSON.stringify(r.json?.data)
  );

  r = await call('GET', '/messes/my-mess/dashboard/members?status=Remaining&meal=Dinner', {
    token: managerToken,
  });
  check(
    'drill-down Remaining excludes the member who skipped',
    r.status === 200 && !r.json.data.some((m) => m.membershipId === membershipId)
  );

  r = await call('GET', '/messes/my-mess/dashboard/members', { token: managerToken });
  check('drill-down without status -> 400', r.status === 400);

  // ---------------------------------------------------------------- leave
  section('leave');
  const leaveStart = addDays(today, 3);
  r = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: leaveStart, endDate: addDays(today, 4) },
  });
  check(
    'leave shorter than the mess minimum -> 400',
    r.status === 400 && /at least 4 consecutive days/.test(r.json?.message || ''),
    JSON.stringify(r.json)
  );

  r = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: today, endDate: addDays(today, 6) },
  });
  check(
    'leave starting today -> 400 (must start tomorrow)',
    r.status === 400 && /tomorrow/.test(r.json?.message || '')
  );

  r = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: leaveStart, endDate: addDays(today, 6), reason: 'Trip home' },
  });
  check('valid 4-day leave -> 201', r.status === 201, JSON.stringify(r.json));
  check(
    '  marks 4 days x 2 meals = 8 attendance rows',
    r.json?.data?.mealsMarked === 8,
    JSON.stringify(r.json?.data)
  );

  r = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: addDays(today, 4), endDate: addDays(today, 9) },
  });
  check('overlapping leave -> 400', r.status === 400 && /overlap/i.test(r.json?.message || ''));

  r = await call('GET', `/leave/${membershipId}`, { token: customerToken });
  check('GET my leave -> 200 with one entry', r.status === 200 && r.json?.data?.length === 1);
  check(
    '  end date is inclusive as the user typed it',
    r.json?.data?.[0]?.endDate === addDays(today, 6),
    JSON.stringify(r.json?.data?.[0])
  );
  check('  reason stored', r.json?.data?.[0]?.reason === 'Trip home');

  r = await call('GET', '/leave/mess', { token: managerToken });
  check('GET /leave/mess -> 200', r.status === 200 && r.json?.data?.length >= 1);
  check('  includes member name', Boolean(r.json?.data?.[0]?.memberName));

  r = await call('GET', '/leave/mess/today', { token: managerToken });
  check(
    'GET /leave/mess/today -> 200',
    r.status === 200 && typeof r.json?.data?.count === 'number'
  );

  r = await call('GET', `/attendance/${membershipId}/calendar`, { token: customerToken });
  const leaveDay = r.json?.data?.days?.find((d) => d.date === leaveStart);
  check(
    'leave shows up on the calendar as Leave',
    leaveDay?.Lunch === undefined ? leaveDay?.meals?.Lunch === 'Leave' : false,
    JSON.stringify(leaveDay)
  );

  // ---------------------------------------------------------------- reviews
  section('reviews');
  r = await call('PUT', `/reviews/${messId}`, {
    token: outsiderToken,
    body: { rating: 5, comment: 'Never been a member' },
  });
  check('non-member cannot review -> 403', r.status === 403);

  r = await call('PUT', `/reviews/${messId}`, {
    token: customerToken,
    body: { rating: 5, comment: 'Excellent food' },
  });
  check('member can review -> 200', r.status === 200 && r.json?.data?.rating === 5);

  r = await call('PUT', `/reviews/${messId}`, {
    token: customerToken,
    body: { rating: 3, comment: 'Edited my mind' },
  });
  check(
    're-reviewing edits in place (no duplicate)',
    r.status === 200 && r.json?.data?.rating === 3
  );

  r = await call('PUT', `/reviews/${messId}`, { token: customerToken, body: { rating: 9 } });
  check('rating above 5 -> 400', r.status === 400);

  r = await call('PUT', `/reviews/${messId}`, {
    token: customer2Token,
    body: { rating: 5, comment: 'Second member view' },
  });
  check('a second member can add their own review', r.status === 200 && r.json?.data?.rating === 5);

  r = await call('GET', `/reviews/${messId}`, { token: customerToken });
  check('GET reviews -> both reviews', r.status === 200 && r.json?.data?.length === 2);
  check(
    '  average rating kept in sync by the DB trigger ((3+5)/2 = 4)',
    r.json?.meta?.averageRating === 4,
    JSON.stringify(r.json?.meta)
  );
  check('  includes author name', Boolean(r.json?.data?.[0]?.authorName));

  r = await call('GET', `/reviews/${messId}/mine`, { token: customerToken });
  check('GET my review -> 200', r.status === 200 && r.json?.data?.rating === 3);

  r = await call('GET', `/reviews/${messId}/mine`, { token: outsiderToken });
  check('GET my review when none -> data null', r.status === 200 && r.json?.data === null);

  r = await call('GET', `/messes/${messId}`, { token: customerToken });
  check(
    'mess detail reflects the new rating',
    r.json?.data?.rating?.count === 2 && r.json?.data?.rating?.average === 4,
    JSON.stringify(r.json?.data?.rating)
  );

  // ---------------------------------------------------------------- billing
  section('billing');
  r = await call('GET', '/billing/mess', { token: managerToken });
  check(
    'GET /billing/mess -> 200 paginated',
    r.status === 200 && typeof r.json?.meta?.total === 'number'
  );

  r = await call('GET', `/billing/membership/${membershipId}`, { token: customerToken });
  check('GET my bills -> 200', r.status === 200 && Array.isArray(r.json?.data));

  r = await call('GET', '/billing/mess?status=Paid', { token: managerToken });
  check('  status filter works', r.status === 200 && r.json.data.every((b) => b.status === 'Paid'));

  r = await call('GET', '/billing/mess?status=Nonsense', { token: managerToken });
  check('  invalid status -> 400', r.status === 400);

  r = await call('POST', '/billing/999999/approve', { token: managerToken });
  check('approving a non-existent bill -> 404', r.status === 404);

  // ---------------------------------------------------------------- discontinue
  section('discontinuation');
  r = await call('POST', `/memberships/${membershipId}/discontinue`, { token: customerToken });
  check('POST discontinue -> 200 with a partial bill', r.status === 200, JSON.stringify(r.json));
  check('  bill generated for this month', Boolean(r.json?.data?.bill));

  r = await call('POST', `/attendance/${membershipId}/skip`, {
    token: customerToken,
    body: { meal: 'Lunch' },
  });
  check(
    'frozen membership cannot mark attendance',
    r.status === 400 && /closing/.test(r.json?.message || ''),
    JSON.stringify(r.json)
  );

  r = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: addDays(today, 20), endDate: addDays(today, 25) },
  });
  check('frozen membership cannot apply for leave', r.status === 400);

  r = await call('POST', `/memberships/${membershipId}/discontinue/reject`, {
    token: managerToken,
  });
  check(
    'manager rejects the request -> unfrozen',
    r.status === 200 && r.json?.data?.discontinuationRequested === false
  );

  r = await call('POST', `/leave/${membershipId}`, {
    token: customerToken,
    body: { startDate: addDays(today, 20), endDate: addDays(today, 25) },
  });
  check('leave works again after un-freezing', r.status === 201, JSON.stringify(r.json));

  r = await call('POST', `/memberships/${membershipId}/discontinue`, { token: customerToken });
  check('customer can request again', r.status === 200);

  r = await call('POST', `/memberships/${membershipId}/discontinue/approve`, {
    token: managerToken,
  });
  const approveDiscontinue = r;
  if (approveDiscontinue.status === 409) {
    check(
      'approve blocked by unpaid bills (expected when a bill is Due)',
      r.json?.code === 'OUTSTANDING_BILLS',
      JSON.stringify(r.json)
    );
    // Clear the bill, then approve for real.
    const bills = await call('GET', `/billing/membership/${membershipId}`, {
      token: customerToken,
    });
    for (const bill of bills.json.data) {
      await call('POST', `/billing/${bill.id}/approve`, { token: managerToken });
    }
  } else {
    check(
      'approve discontinuation -> Inactive',
      r.status === 200 && r.json?.data?.status === 'Inactive',
      JSON.stringify(r.json)
    );
  }

  // ---------------------------------------------------------------- cron
  section('cron jobs');
  const cronSecret = process.env.CRON_SECRET_FOR_TEST;
  r = await call('POST', '/cron/absence', { body: {} });
  check('cron without the secret -> 401', r.status === 401);

  if (cronSecret) {
    const withSecret = async (path) => {
      const started = process.hrtime.bigint();
      const res = await fetch(`${API}${path}`, {
        method: 'POST',
        headers: { 'x-cron-secret': cronSecret, 'Content-Type': 'application/json' },
        body: '{}',
      });
      const ms = Number(process.hrtime.bigint() - started) / 1e6;
      timings.push({ route: `POST ${path}`, ms });
      return { status: res.status, json: await res.json(), ms };
    };

    r = await withSecret('/cron/absence');
    check(
      'absence job runs -> success',
      r.status === 200 && r.json?.data?.status === 'success',
      JSON.stringify(r.json)
    );
    check('  reports rows written', typeof r.json?.data?.rowsAffected === 'number');

    r = await withSecret('/cron/billing');
    check(
      'billing job runs -> success',
      r.status === 200 && r.json?.data?.status === 'success',
      JSON.stringify(r.json)
    );
    check('  reports the period billed', Boolean(r.json?.data?.period));
  } else {
    console.log('  (skipped authenticated cron checks - set CRON_SECRET_FOR_TEST)');
  }

  // ---------------------------------------------------------------- misc
  section('error handling');
  r = await call('GET', '/does-not-exist', { token: managerToken });
  check(
    'unknown route -> 404 ROUTE_NOT_FOUND',
    r.status === 404 && r.json?.code === 'ROUTE_NOT_FOUND'
  );

  r = await call('POST', '/auth/login', { body: '{bad json', raw: true });
  check('malformed JSON -> 400 INVALID_JSON', r.status === 400 && r.json?.code === 'INVALID_JSON');

  r = await call('GET', '/messes/not-a-number', { token: customerToken });
  check(
    'non-numeric id -> 4xx, not a 500',
    r.status >= 400 && r.status < 500,
    `status=${r.status} ${JSON.stringify(r.json)}`
  );

  // ---------------------------------------------------------------- timings
  section('response times');
  const sorted = [...timings].sort((a, b) => a.ms - b.ms);
  const p = (q) => sorted[Math.floor(sorted.length * q)]?.ms.toFixed(1);
  const slowest = [...timings].sort((a, b) => b.ms - a.ms).slice(0, 8);

  console.log(`  requests: ${timings.length}`);
  console.log(
    `  p50 ${p(0.5)} ms | p90 ${p(0.9)} ms | p99 ${p(0.99)} ms | max ${sorted.at(-1).ms.toFixed(1)} ms`
  );
  console.log('  slowest calls:');
  for (const t of slowest) console.log(`    ${t.ms.toFixed(1).padStart(7)} ms  ${t.route}`);

  const overBudget = slowest.filter((t) => t.ms > 500);
  check(
    `no request slower than 500 ms`,
    overBudget.length === 0,
    overBudget.map((t) => `${t.route} ${t.ms.toFixed(0)}ms`).join(', ')
  );

  // ---------------------------------------------------------------- summary
  console.log(`\n${'='.repeat(46)}`);
  console.log(`  PASSED ${passed}   FAILED ${failed}`);
  console.log('='.repeat(46));
  if (failures.length > 0) {
    console.log('\nFailures:');
    failures.forEach((f) => console.log(`  - ${f}`));
  }
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error('Test run crashed:', error);
  process.exit(1);
});
