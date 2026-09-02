# new_backend API contract (extracted from running code, not docs)

Generated for the new_frontend alignment pass. Ground truth = route files +
`middleware/schemas.js` + `toPublic*()` mappers in `services/`.

## Envelope

- Success: `{ "success": true, "data": ..., "meta": {...} }` (`meta` only on list endpoints)
- Failure: `{ "success": false, "code": "...", "message": "..." }`
- Auth header: `Authorization: Bearer <jwt>`
- Pagination `meta`: `{ page, limit, total, totalPages, hasNextPage }`

## Error codes (LLD §9)

`VALIDATION_ERROR`, `UNAUTHENTICATED`, `BAD_CREDENTIALS`, `BAD_PIN`, `FORBIDDEN`,
`NOT_FOUND`, `CONFLICT`, `MESS_FULL`, `PHONE_TAKEN`, `OUTSTANDING_BILLS`,
`INCOMPLETE_ATTENDANCE_DATA`, `DUPLICATE`, `INVALID_REFERENCE`,
`OVERLAPPING_PERIOD`, `RULE_VIOLATION`, `INVALID_INPUT`, `INVALID_JSON`,
`ROUTE_NOT_FOUND`, `TOO_MANY_REQUESTS`, `INTERNAL_ERROR`

## All 49 routes

```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me
PATCH  /api/auth/me

POST   /api/messes/
GET    /api/messes/my-mess
PATCH  /api/messes/my-mess
GET    /api/messes/my-mess/dashboard
GET    /api/messes/my-mess/dashboard/members
GET    /api/messes/my-mess/plans
POST   /api/messes/my-mess/plans
PATCH  /api/messes/my-mess/plans/:planId
DELETE /api/messes/my-mess/plans/:planId
GET    /api/messes/discover
GET    /api/messes/:messId
GET    /api/messes/:messId/plans

POST   /api/memberships/join/:messId
GET    /api/memberships/mine
GET    /api/memberships/mess
GET    /api/memberships/:membershipId
POST   /api/memberships/:membershipId/approve
POST   /api/memberships/:membershipId/reject
POST   /api/memberships/:membershipId/discontinue
POST   /api/memberships/:membershipId/discontinue/approve
POST   /api/memberships/:membershipId/discontinue/reject

POST   /api/attendance/kiosk/mark
POST   /api/attendance/kiosk/override-leave
POST   /api/attendance/kiosk/walkin
POST   /api/attendance/:membershipId/skip
GET    /api/attendance/:membershipId/calendar

GET    /api/leave/mess
GET    /api/leave/mess/today
POST   /api/leave/:membershipId
GET    /api/leave/:membershipId

GET    /api/billing/mess
GET    /api/billing/membership/:membershipId
POST   /api/billing/:billId/proof
POST   /api/billing/:billId/approve
POST   /api/billing/:billId/reject
GET    /api/billing/:billId/proof
GET    /api/billing/:billId/history

GET    /api/reviews/:messId
GET    /api/reviews/:messId/mine
PUT    /api/reviews/:messId

PUT    /api/menus/my-mess
GET    /api/menus/:messId

POST   /api/cron/absence     (x-cron-secret header, not JWT)
POST   /api/cron/billing     (x-cron-secret header, not JWT)
```

## Response entity shapes (exact `toPublic*()` output)

**user** (`/auth/register`, `/auth/login` -> `data: { user, token }`; `/auth/me` -> `data` directly)
`{ id, name, phone, role }` — `/auth/me` additionally adds `hasMess`, `messId` for Managers.

**mess** — note `location` is an OBJECT, not a coordinates array
```
{ id, ownerId, messName, messImage, address, city, contactPhone,
  location: { longitude, latitude },
  serviceType, cuisine, maxCapacity, tiffinService, basicThaliDetails,
  timings: { lunchStart, lunchEnd, dinnerStart, dinnerEnd },   // "HH:MM" strings
  dailyThaliRateRupees,
  rules: { minLeaveDaysForRebate, rebatePerThaliRupees, skipAllowancePercent,
           allowAbsentRebate, minMonthlyChargeRupees, securityDepositRupees },
  rating: { average, count } }
```
extras: `GET /messes/:messId` adds `plans`, `liveStatus`, `currentMeal`;
`GET /messes/discover` adds `distanceMetres`; `my-mess` adds `plans`.

**plan** `{ id, messId, name, rateRupees, meals: ['Lunch','Dinner'], isActive }`

**membership** `{ id, userId, messId, planId, planName, rateRupees, status,
joinedDate, discontinuationRequested, messName, memberName, memberPhone }`
> `rateRupees` is now the plan's LIVE rate (no snapshot on the membership).

**bill** `{ id, membershipId, messId, period, baseRupees, rebateRupees,
totalRupees, status, hasPaymentProof, memberName, memberPhone, createdAt, updatedAt }`

**leave** `{ id, membershipId, startDate, endDate, reason, memberName, memberPhone }`
(startDate/endDate are INCLUSIVE plain 'YYYY-MM-DD')

**menu** `{ id, serviceDate, lunchItems: [], dinnerItems: [] }`

**review** `{ id, rating, comment, authorName, createdAt, updatedAt }`
list `meta` adds `averageRating`.

**membership details** (`GET /memberships/:id`)
```
{ membership: <membership>,
  monthToDate: { present, skipped, leave, absent },
  recentBills: [{ id, period, totalRupees, status }],
  todaysMenu: { lunchItems, dinnerItems } | null }
```

**dashboard** (`GET /messes/my-mess/dashboard`)
```
{ date, meal, liveStatus, currentMeal, nextMeal, nextMealIsTomorrow,
  counts: { eligible, eating, skipped, onLeave, absent, remaining, walkins },
  todaysMenu }
```

**dashboard members** (`?status=Present|Skipped|Leave|Absent|Remaining&meal=`)
`data: [{ membershipId, userId, name, phone, status }]`, `meta` adds `meal`, `date`.

**attendance calendar** (`?month=&year=`)
`{ month, year, days: [{ date, meals: { Lunch: 'Present', Dinner: 'Skipped' } }] }`

**attendance write** (skip / kiosk mark) `{ membershipId?, serviceDate, meal, status }`
**override-leave** `{ membershipId, serviceDate, meal, status, elapsedLeaveDays, elapsedLeaveKept, leaveEndedOn }`
**walkin** `{ serviceDate, meal, quantity, totalRupees }`

## Request bodies (from middleware/schemas.js — unknown keys are STRIPPED)

- register: `{ name, phone(10 digits), password(8-72), role: 'Customer'|'Manager',
  pin(4 digits, Customer only, FORBIDDEN for Manager),
  location: { longitude, latitude } (Customer only, FORBIDDEN for Manager) }`
- login: `{ phone, password }`
- updateProfile (PATCH /auth/me): `{ name?, pin? }` min 1 key
- createMess: `{ messName, address, city, contactPhone, location:{longitude,latitude},
  serviceType, cuisine, maxCapacity?, tiffinService, basicThaliDetails,
  lunchStart, lunchEnd, dinnerStart, dinnerEnd ("HH:MM"), dailyThaliRateRupees?,
  rules: { minLeaveDaysForRebate, rebatePerThaliRupees, skipAllowancePercent?,
           allowAbsentRebate?, minMonthlyChargeRupees?, securityDepositRupees? },
  plans: [{ name, rateRupees, meals: ['Lunch'|'Dinner'] }] }`
  (multipart field for image: `messImage`)
- updateMess (PATCH): same keys, all optional, min 1
- plan create/update: `{ name, rateRupees, meals: [...] }`
- joinMess: `{ planId }` (integer)
- skipMeal: `{ meal: 'Lunch'|'Dinner' }`
- kioskMark / override-leave: `{ membershipId, pin, meal }`
- walkin: `{ meal, quantity? (1-50) }`
- applyLeave: `{ startDate, endDate, reason? }` ('YYYY-MM-DD', inclusive)
- setMenu: `{ serviceDate, lunchItems: [], dinnerItems: [] }`
- upsertReview: `{ rating 1-5, comment? }`
- payment proof: multipart field `paymentProof`

## Query params

- discover: `cuisine, serviceType, search, page, limit(<=100)`
- dashboard: `meal`
- dashboard/members: `status`(required), `meal`, `page`, `limit`
- calendar: `month`, `year`
- billing/mess: `status, month, year, page, limit`
- memberships/mess: `status`(Pending|Active|Inactive), `page`, `limit`
- menus/:messId: `from`, `to`
- generic lists: `page`, `limit`

## Money

Everything crossing the API is **rupees** (`*Rupees`), possibly decimal.
`*_price` columns (integer smallest-unit) never leave the backend.
No `xxxPrice` field is exposed in any `toPublic*()` mapper.

## Dates

`period`, `serviceDate`, `joinedDate`, `startDate`, `endDate`, `date` are plain
calendar dates — do NOT apply timezone math client-side.
`createdAt` / `updatedAt` are real instants (TIMESTAMPTZ).
