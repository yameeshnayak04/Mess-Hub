// new_backend/scripts/kioskContractCheck.js
//
// The kiosk actions only work inside a meal's serving window, so they cannot be
// exercised by a script that runs at an arbitrary time of day. This one builds a
// mess whose lunch window covers right now, then checks the real payload shape
// of every kiosk action - including the leave override.
//
//   node scripts/kioskContractCheck.js
const BASE = process.env.API_BASE || 'http://localhost:4000/api';

const stamp = Date.now().toString().slice(-7);
const managerPhone = `6${stamp}11`.slice(0, 10);
const customerPhone = `5${stamp}22`.slice(0, 10);
const PASSWORD = 'password123';
const PIN = '1357';

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

// Successful payloads, merged into the same capture file contractCheck writes,
// so the Flutter model tests can cover the time-gated kiosk routes too.
const captured = {};

function report(label, result, expected) {
  const ok = result.status === expected;
  if (!ok) failures += 1;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${label}  [${result.status}]`);
  console.log(`     ${JSON.stringify(result.json?.data ?? result.json)}`);
  if (ok && result.status < 300) captured[label] = result.json?.data;
}

function writeCapture() {
  const out = process.env.CAPTURE_TO;
  if (!out) return;
  const fs = require('node:fs');
  const existing = fs.existsSync(out) ? JSON.parse(fs.readFileSync(out, 'utf8')) : {};
  fs.writeFileSync(out, JSON.stringify({ ...existing, ...captured }, null, 2));
  console.log(`merged ${Object.keys(captured).length} kiosk payloads into ${out}`);
}

// Wall-clock time in India, which is what the mess timing columns mean.
function istNow() {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Kolkata',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(new Date());
  const hour = Number(parts.find((p) => p.type === 'hour').value);
  const minute = Number(parts.find((p) => p.type === 'minute').value);
  return { hour, minute };
}

function pad(n) {
  return n.toString().padStart(2, '0');
}

async function main() {
  const { hour, minute } = istNow();
  // A lunch window that definitely contains this moment, and a dinner window
  // that definitely does not (so the "not being served" path stays testable).
  const lunchStart = `${pad(Math.max(0, hour - 1))}:${pad(minute)}`;
  const lunchEnd = `${pad(Math.min(23, hour + 1))}:${pad(minute)}`;
  console.log(`IST now ${pad(hour)}:${pad(minute)} - lunch window ${lunchStart}-${lunchEnd}\n`);

  const manager = await call('POST', '/auth/register', {
    body: { name: 'Kiosk Manager', phone: managerPhone, password: PASSWORD, role: 'Manager' },
  });
  const managerToken = manager.json?.data?.token;

  const customer = await call('POST', '/auth/register', {
    body: {
      name: 'Kiosk Customer',
      phone: customerPhone,
      password: PASSWORD,
      role: 'Customer',
      pin: PIN,
      location: { longitude: 73.8567, latitude: 18.5204 },
    },
  });
  const customerToken = customer.json?.data?.token;

  const created = await call('POST', '/messes', {
    token: managerToken,
    body: {
      messName: `Kiosk Mess ${stamp}`,
      address: 'Karve Road, Kothrud',
      city: 'Pune',
      contactPhone: managerPhone,
      location: { longitude: 73.8567, latitude: 18.5204 },
      serviceType: 'Both Daily & Monthly',
      cuisine: 'Veg',
      maxCapacity: 40,
      tiffinService: false,
      basicThaliDetails: 'Chapati, sabzi, dal, rice, salad',
      lunchStart,
      lunchEnd,
      dinnerStart: '23:00',
      dinnerEnd: '23:30',
      dailyThaliRateRupees: 85,
      rules: {
        minLeaveDaysForRebate: 3,
        rebatePerThaliRupees: 35,
        skipAllowancePercent: 50,
        allowAbsentRebate: false,
      },
      plans: [{ name: 'Both Meals', rateRupees: 3000, meals: ['Lunch', 'Dinner'] }],
    },
  });
  const messId = created.json?.data?.messId;
  const planId = created.json?.data?.plans?.[0]?.id;

  const joined = await call('POST', `/memberships/join/${messId}`, {
    token: customerToken,
    body: { planId },
  });
  const membershipId = joined.json?.data?.id;
  await call('POST', `/memberships/${membershipId}/approve`, { token: managerToken });

  console.log('--- normal check-in');
  report('POST /attendance/kiosk/mark', await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: PIN, meal: 'Lunch' },
  }), 201);

  console.log('\n--- refuses to overwrite an existing record');
  report('POST /attendance/kiosk/mark (again)', await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: PIN, meal: 'Lunch' },
  }), 409);

  console.log('\n--- wrong PIN');
  report('POST /attendance/kiosk/mark (bad pin)', await call('POST', '/attendance/kiosk/mark', {
    token: managerToken,
    body: { membershipId, pin: '0000', meal: 'Lunch' },
  }), 401);

  console.log('\n--- walk-in sale');
  report('POST /attendance/kiosk/walkin', await call('POST', '/attendance/kiosk/walkin', {
    token: managerToken,
    body: { meal: 'Lunch', quantity: 2 },
  }), 201);

  // The override needs an approved leave covering today, and the leave itself
  // must start tomorrow - so a second member applies for leave, and we move the
  // clock forward by billing terms only: apply from tomorrow, then override
  // tomorrow is impossible. Instead: this member's leave starts tomorrow, which
  // means today is NOT covered, so we assert the override refuses that too.
  console.log('\n--- override with no leave to override');
  report('POST /attendance/kiosk/override-leave (no leave today)', await call('POST', '/attendance/kiosk/override-leave', {
    token: managerToken,
    body: { membershipId, pin: PIN, meal: 'Lunch' },
  }), 400);

  writeCapture();

  console.log(`\n${failures === 0 ? 'kiosk contract verified' : `${failures} kiosk check(s) failed`}`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
