# Mess Hub — Backend

Backend for **Mess Hub**, a two-sided marketplace connecting local mess owners
(small meal-subscription food businesses) with customers who subscribe to daily
lunch and dinner plans.

This is a **ground-up rewrite** of an earlier MongoDB backend. The original
still lives in [`../backend/`](../backend/), untouched, so the two can be
compared. Section [Why the rewrite](#why-the-rewrite) lists the specific bugs
that motivated it — that before-and-after is the most interesting part of this
project.

Node.js · Express · PostgreSQL + PostGIS · Knex · Docker

---

## Contents

- [What it does](#what-it-does)
- [Quick start](#quick-start)
- [Project layout](#project-layout)
- [Architecture in one minute](#architecture-in-one-minute)
- [API reference](#api-reference)
- [Testing](#testing)
- [Design decisions worth knowing](#design-decisions-worth-knowing)
- [Why the rewrite](#why-the-rewrite)
- [Documentation](#documentation)

---

## What it does

**Customers** find nearby messes on a map, compare plans and reviews, join one,
then manage their meals day to day: mark themselves present at the mess kiosk,
skip a meal they will miss, book leave in advance, and view and pay monthly
bills.

**Managers** set up their mess (timings, plans, pricing, rebate rules), approve
join requests, run a kiosk at mealtimes, watch a live count of who is eating
right now, and approve payments.

The part that has to be _correct_ rather than merely working is billing:
a base plan charge, prorated for partial months, minus rebates for approved
leave and skipped meals, floored at a minimum monthly charge.

---

## Quick start

Requires Docker Desktop.

```bash
cd new_backend
cp .env.example .env                                        # then fill in the values
docker compose -f docker-compose.dev.yml up --build -d
docker compose -f docker-compose.dev.yml exec backend npm run migrate:latest
curl http://localhost:4000/health
# {"status":"ok","database":"connected"}
```

Full command reference, including how to run tests inside the container and
what to do when something breaks: **[DOCKER.md](DOCKER.md)**.

---

## Project layout

```
new_backend/
├── routes/          one file per area; the whole API surface, with its guards
├── controllers/     parse request → call a service → send response. Nothing else
├── services/        all business logic and SQL. No req/res anywhere in here
├── middleware/      auth, ownership guards, validation, rate limits, errors
├── jobs/            absence marking + monthly billing, triggered by external cron
├── db/              schema.sql, migrations, the Knex connection pool
├── errors/          typed errors the global handler turns into HTTP responses
├── utils/           dates, money, pagination, config
├── scripts/         apiTest.js + the contract checks (see Testing)
└── docs/            HLD.md, LLD.md
```

The layering rule that keeps this simple: **controllers never contain business
logic or SQL, and services never touch `req`/`res`.** If you are unsure where
code belongs, ask whether it needs to know about HTTP. If not, it is a service —
and services are plain functions you can test without starting a server.

---

## Architecture in one minute

```
Flutter app ──HTTPS/JWT──▶ Express API ──▶ Services ──▶ PostgreSQL + PostGIS
                                │                          ▲
External cron ──shared secret──▶┘                          │
                                └──▶ Cloudinary (images) ───┘
```

- **One REST API, not microservices.** Membership, attendance and billing are
  one tightly-coupled transactional unit; splitting them would mean
  re-implementing transactions over the network for no benefit at this scale.
- **PostgreSQL, not MongoDB.** The data is a four-level foreign-key chain with
  date-range rules and money that needs real constraints. The old codebase was
  hand-rolling in JavaScript the guarantees Postgres simply has.
- **Background jobs run in the same process**, triggered by an external cron
  hitting `/api/cron/*` with a shared secret. The workload does not justify a
  separate queue or worker.

More detail, with diagrams: **[docs/HLD.md](docs/HLD.md)**.

---

## API reference

Every response uses the same envelope:

```jsonc
// success
{ "success": true, "data": { ... }, "meta": { ... } }   // meta on list endpoints
// failure
{ "success": false, "code": "VALIDATION_ERROR", "message": "..." }
```

All routes are under `/api`. Auth is `Authorization: Bearer <jwt>`.
**C** = customer, **M** = manager, **–** = any signed-in user.

### Auth

| Method | Path             | Who    | Purpose                                      |
| ------ | ---------------- | ------ | -------------------------------------------- |
| POST   | `/auth/register` | public | Sign up as Customer or Manager               |
| POST   | `/auth/login`    | public | Log in (rate limited)                        |
| POST   | `/auth/logout`   | –      | Client discards its token                    |
| GET    | `/auth/me`       | –      | Current profile; managers also get `hasMess` |
| PATCH  | `/auth/me`       | –      | Update name, or a customer's kiosk PIN       |

### Messes and plans

| Method | Path                                | Who | Purpose                                          |
| ------ | ----------------------------------- | --- | ------------------------------------------------ |
| POST   | `/messes`                           | M   | Create the mess with its plans (one per manager) |
| GET    | `/messes/my-mess`                   | M   | Own mess, including retired plans                |
| PATCH  | `/messes/my-mess`                   | M   | Update details, timings or rules                 |
| GET    | `/messes/my-mess/dashboard`         | M   | Live counts for the current meal                 |
| GET    | `/messes/my-mess/dashboard/members` | M   | Drill-down behind a count                        |
| GET    | `/messes/my-mess/plans`             | M   | List plans                                       |
| POST   | `/messes/my-mess/plans`             | M   | Add a plan                                       |
| PATCH  | `/messes/my-mess/plans/:planId`     | M   | Edit a plan                                      |
| DELETE | `/messes/my-mess/plans/:planId`     | M   | Retire a plan (never deleted)                    |
| GET    | `/messes/discover`                  | C   | Nearby messes, nearest first                     |
| GET    | `/messes/:messId`                   | –   | Public mess detail                               |
| GET    | `/messes/:messId/plans`             | –   | Plans a customer can join                        |

### Memberships

| Method | Path                                             | Who | Purpose                              |
| ------ | ------------------------------------------------ | --- | ------------------------------------ |
| POST   | `/memberships/join/:messId`                      | C   | Request to join on a plan            |
| GET    | `/memberships/mine`                              | C   | My memberships                       |
| GET    | `/memberships/mess`                              | M   | Members, filterable by status        |
| GET    | `/memberships/:membershipId`                     | –   | Dashboard payload for one membership |
| POST   | `/memberships/:membershipId/approve`             | M   | Approve a join request               |
| POST   | `/memberships/:membershipId/reject`              | M   | Reject a join request                |
| POST   | `/memberships/:membershipId/discontinue`         | C   | Ask to leave; partial bill is raised |
| POST   | `/memberships/:membershipId/discontinue/approve` | M   | Close the membership                 |
| POST   | `/memberships/:membershipId/discontinue/reject`  | M   | Decline; membership continues        |

### Attendance

| Method | Path                                 | Who | Purpose                                                        |
| ------ | ------------------------------------ | --- | -------------------------------------------------------------- |
| POST   | `/attendance/:membershipId/skip`     | C   | Skip today's meal                                              |
| GET    | `/attendance/:membershipId/calendar` | –   | A month of attendance                                          |
| POST   | `/attendance/kiosk/mark`             | M   | Mark present via PIN (rate limited)                            |
| POST   | `/attendance/kiosk/override-leave`   | M   | Member turned up mid-leave: mark present and correct the leave |
| POST   | `/attendance/kiosk/walkin`           | M   | Record a walk-in thali sale                                    |

### Leave, billing, reviews, menus

| Method | Path                                | Who    | Purpose                                    |
| ------ | ----------------------------------- | ------ | ------------------------------------------ |
| POST   | `/leave/:membershipId`              | C      | Book leave (auto-approved if long enough)  |
| GET    | `/leave/:membershipId`              | –      | Leave history                              |
| GET    | `/leave/mess`                       | M      | All leave in the mess                      |
| GET    | `/leave/mess/today`                 | M      | Who is away today                          |
| GET    | `/billing/mess`                     | M      | All bills, filterable by status/month/year |
| GET    | `/billing/membership/:membershipId` | –      | Bills for one membership                   |
| POST   | `/billing/:billId/proof`            | C      | Upload payment proof                       |
| POST   | `/billing/:billId/approve`          | M      | Approve a submitted payment                |
| POST   | `/billing/:billId/reject`           | M      | Reject it; bill returns to Due             |
| GET    | `/billing/:billId/proof`            | M      | Short-lived signed link to the proof       |
| GET    | `/billing/:billId/history`          | M      | Full audit trail for a bill                |
| GET    | `/reviews/:messId`                  | –      | Reviews, paginated                         |
| GET    | `/reviews/:messId/mine`             | C      | My review, for pre-filling the form        |
| PUT    | `/reviews/:messId`                  | C      | Write or edit my review                    |
| PUT    | `/menus/my-mess`                    | M      | Set a day's menu                           |
| GET    | `/menus/:messId`                    | –      | Menu for today, or a date range            |
| POST   | `/cron/absence`                     | secret | Mark absences for closed meals             |
| POST   | `/cron/billing`                     | secret | Generate last month's bills                |

Money crosses the API as plain **rupees** (`rateRupees: 6000`); the database
stores whole smallest-currency units. See
[Design decisions](#design-decisions-worth-knowing).

---

## Testing

```bash
npm test                    # 35 unit tests: billing maths + the leave override
npm run test:api            # 151 checks: every route end-to-end, plus response times
npm run test:contract       # prints the real response shape of every route the app calls
npm run test:contract:kiosk # the kiosk actions, inside a meal window it builds itself
npm run test:contract:manager # the manager's member page, incl. cross-mess refusals
npm run lint
```

`test:contract` exists for the mobile app: it hits each endpoint and prints the
payload's actual field names and types, so client models are checked against
real responses instead of against the docs. `test:contract:kiosk` is separate
because the kiosk actions only work inside a meal's serving window, so it
creates a mess whose lunch window covers the moment it runs.

The billing service was written **test-first**. Its suite covers mid-month
joins, leave and skip rebates, the absent-rebate toggle, the minimum-charge
floor, rejoining the same mess in one month, incomplete attendance, and the
discontinuation freeze.

Both suites run against the **real Dockerized Postgres**, never a mock — this is
money code, and mocks would hide exactly the rounding and constraint behaviour
that matters. Each test runs inside a transaction that is rolled back, so they
leave nothing behind.

The API test asserts on actual response _values_, not just status codes, and
finishes by printing latency percentiles.

**Current numbers** — 35/35 unit, 155/155 API, 0 lint problems,
0 npm vulnerabilities. p50 **7 ms**, p90 **83 ms**, p99 **151 ms**. The slowest
calls are all bcrypt (register, login, kiosk PIN), which is intentional: a fast
password hash is a broken password hash.

---

## Design decisions worth knowing

**Money is integer, never float.** Every `*_price` column is a `BIGINT` holding
rupees × 100, so ₹6000 is stored as `600000`. There is no decimal anywhere to
round badly. `utils/money.js` is the only place the two representations meet.

**Calendar days are `DATE`, not timestamps.** Attendance, leave and menus care
about _which day_, not an instant in time. Every database connection is also
pinned to `Asia/Kolkata` on creation. Together these remove an entire class of
"marked absent 5½ hours early" bugs rather than patching them.

**The database enforces the rules, not just the app.** A leave shorter than the
mess minimum is rejected by a trigger; overlapping leave and overlapping active
memberships are rejected by `EXCLUDE USING gist` constraints; a bill can never
have a rebate larger than its base. These hold no matter which code path runs,
which is a stronger guarantee than an `if` statement in a service.

**Plan meals are a join table.** Whether a plan covers lunch is a row in
`plan_meals`, resolved with a `JOIN` — never a substring search on the plan's
display name.

**Concurrency is handled with row locks.** Capacity checks use
`SELECT … FOR UPDATE` inside the same transaction as the insert, so two people
clicking "join" simultaneously cannot both take the final place.

**Billing refuses to guess.** If any meal in a billing period has no attendance
record, `generateBillForMembership` throws rather than inventing a number. A
missing row usually means the absence job has not caught up; treating it as an
absence would silently give money away.

**Payment proofs are private.** They upload to Cloudinary as `authenticated`
assets and are only reachable through a signed URL that expires in ten minutes,
issued by an endpoint that checks who is asking.

---

## Why the rewrite

Every row below is a real bug found in the original `backend/`, not a
hypothetical.

| Problem in the old MongoDB backend                                                                                                                 | How this version prevents it                    |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Whether a plan included lunch was decided by `planName.includes('lunch')`, duplicated in 9 places — a plan named "Deluxe" silently covered nothing | `plan_meals` join table, resolved once          |
| "Does this manager own this mess?" copy-pasted into 17 controller functions                                                                        | One `requireManagerMess` middleware             |
| Leave overlap checked with a hand-rolled query — a race waiting to happen                                                                          | `EXCLUDE USING gist` constraint                 |
| Capacity checked by read-then-write (classic TOCTOU race)                                                                                          | `SELECT … FOR UPDATE` in one transaction        |
| Money stored as floats, patched with `Math.round(x*100)/100` in controllers                                                                        | `BIGINT` smallest units; no float touches money |
| "Today" computed by shifting UTC by 5½ hours by hand, inconsistently                                                                               | `DATE` columns and one pinned session timezone  |
| A missing attendance record was silently treated as a rebate                                                                                       | Completeness gate: billing refuses to run       |
| Bills keyed by `(user, mess, month)`, so rejoining a mess overwrote the earlier bill                                                               | Keyed by `(membership_id, period)`              |
| Rejecting a payment blanked the proof URL, erasing the evidence                                                                                    | Append-only `bill_events` audit trail           |
| A bill could jump straight from Due to Paid with no proof                                                                                          | State transitions are checked                   |
| Kiosk PINs stored in plain text                                                                                                                    | bcrypt, like passwords                          |
| `cors()` open to every origin                                                                                                                      | Restricted to a configured allow-list           |
| No tests at all, least of all on the billing maths                                                                                                 | 35 unit + 155 API checks                        |

---

## Documentation

| Document                           | What it covers                                                             |
| ---------------------------------- | -------------------------------------------------------------------------- |
| **[docs/HLD.md](docs/HLD.md)**     | High-level design: system shape, tech choices, key flows, deployment       |
| **[docs/LLD.md](docs/LLD.md)**     | Low-level design: schema, service contracts, algorithms, sequence diagrams |
| **[DOCKER.md](DOCKER.md)**         | Running, testing and troubleshooting the containers                        |
| **[db/schema.sql](db/schema.sql)** | The schema itself — every constraint is commented with why it exists       |
