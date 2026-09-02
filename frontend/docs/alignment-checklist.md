# new_frontend -> new_backend drift checklist

Baseline: `new_frontend/` is byte-identical to the old Mongo-era `frontend/`.
`flutter analyze` baseline = 0 errors, 898 style infos.

## Global drift (affects everything)

| # | Drift | Old (frontend) | New (backend) |
|---|---|---|---|
| G1 | Entity id | `_id` (Mongo ObjectId string) | `id` (integer) |
| G2 | Location | GeoJSON `{type:'Point', coordinates:[lng,lat]}` | `{longitude, latitude}` |
| G3 | Envelope | checks `statusCode` only | must branch on `success` + `code` |
| G4 | Base URL | old Render deploy | new backend (`:4000`) |
| G5 | Money | `rate`, `billingRate`, `rebatePerThali`, `dailyThaliRate`, `securityDeposit`, `minMonthlyCharge` | all `*Rupees` |
| G6 | Meal field | `mealType` | `meal` |
| G7 | Dates | `toIso8601String()` (instant) sent for business dates | plain `YYYY-MM-DD` |
| G8 | Rating | flat `averageRating`/`reviewCount` | nested `rating:{average,count}` |
| G9 | Timings | nested `{lunch:{start,end},dinner:{...}}` | flat `{lunchStart,lunchEnd,dinnerStart,dinnerEnd}` |
| G10 | Distance | `distance` | `distanceMetres` |
| G11 | Plan identity | plan chosen by `planName` | chosen by `planId`; plan has `meals[]`, `isActive` |

## Endpoint-by-endpoint

| # | Frontend call (old) | Backend (new) | Drift |
|---|---|---|---|
| 1 | `POST /auth/login` | same | envelope; `data.user`+`data.token` |
| 2 | `POST /auth/register` | same | `location` shape (G2); Manager must NOT send pin/location |
| 3 | `POST /auth/logout` | same | ok |
| 4 | `GET /users/profile/me` | `GET /auth/me` | **path** |
| 5 | `PUT /users/profile/me` | `PATCH /auth/me` | **path + method** |
| 6 | `GET /mess/discover` | `GET /messes/discover` | path; `search` now server-side; `distanceMetres` |
| 7 | `GET /mess/$id` | `GET /messes/$id` | path; body shape |
| 8 | `GET /mess/my-mess` | `GET /messes/my-mess` | path |
| 9 | `PUT /mess/my-mess` | `PATCH /messes/my-mess` | **method**; field names |
| 10 | `POST /mess` (create) | `POST /messes` | path; whole payload reshaped |
| 11 | `GET /mess/my-mess/dashboard` | `GET /messes/my-mess/dashboard` | path; counts shape |
| 12 | `GET /mess/dashboard/members-eating` | `GET /messes/my-mess/dashboard/members?status=Present` | **collapsed into 1 param'd route** |
| 13 | `GET /mess/dashboard/members-on-leave` | `...?status=Leave` | same collapse |
| 14 | `GET /mess/dashboard/members-skipped` | `...?status=Skipped` | same collapse |
| 15 | (none) | `...?status=Remaining` | new capability |
| 16 | `POST /membership/join/$messId` body `{planName}` | `POST /memberships/join/$messId` body `{planId}` | path + **body field** |
| 17 | `GET /membership/my-memberships` | `GET /memberships/mine` | path |
| 18 | `GET /membership/details/$id` | `GET /memberships/$id` | path |
| 19 | `GET /membership/member/$id` | `GET /memberships/$id` | **merged with 18** |
| 20 | `GET /membership/mess` | `GET /memberships/mess` | path |
| 21 | `PUT /membership/approve/$id` | `POST /memberships/$id/approve` | path + method |
| 22 | `PUT /membership/reject/$id` | `POST /memberships/$id/reject` | path + method |
| 23 | `PUT /membership/request-discontinue/$id` | `POST /memberships/$id/discontinue` | path + method |
| 24 | `PUT /membership/approve-discontinue/$id` | `POST /memberships/$id/discontinue/approve` | path + method |
| 25 | `PUT /membership/reject-discontinue/$id` | `POST /memberships/$id/discontinue/reject` | path + method |
| 26 | `POST /attendance/skip` body `{membershipId,mealType,date}` | `POST /attendance/$membershipId/skip` body `{meal}` | path + body; **date no longer accepted (today only)** |
| 27 | `GET /attendance/my-calendar/$id` | `GET /attendance/$id/calendar` | path; response is `{month,year,days[]}` not a flat list |
| 28 | `GET /attendance/member/$id` | `GET /attendance/$id/calendar` | **merged with 27** |
| 29 | `POST /attendance/kiosk/mark` body `{userId,kioskPin,mealType}` | body `{membershipId,pin,meal}` | **all 3 body fields** |
| 30 | `POST /attendance/kiosk/daily` body `{mealType}` | `POST /attendance/kiosk/walkin` body `{meal,quantity}` | path + body |
| 31 | (none) | `POST /attendance/kiosk/override-leave` | **new — Step 3.2** |
| 32 | `POST /leave/apply/$id` ISO datetimes | `POST /leave/$id` `YYYY-MM-DD` | path + date format |
| 33 | `GET /leave/my/$id` | `GET /leave/$id` | path |
| 34 | `GET /leave/member/$id` | `GET /leave/$id` | **merged with 33** |
| 35 | (`/leave/mess-leaves`) | `GET /leave/mess`, `GET /leave/mess/today` | path |
| 36 | `GET /billing/my-bills/$id` | `GET /billing/membership/$id` | path |
| 37 | `GET /billing/member/$id` | `GET /billing/membership/$id` | **merged with 36** |
| 38 | `GET /billing/pending-approvals` | `GET /billing/mess?status=Pending Approval` | **collapsed to filter** |
| 39 | `GET /billing/due-bills` | `GET /billing/mess?status=Due` | **collapsed to filter** |
| 40 | `GET /billing/all-bills` | `GET /billing/mess` | path |
| 41 | `POST /billing/submit-proof/$id` | `POST /billing/$id/proof` | path (multipart field `paymentProof` unchanged) |
| 42 | `PUT /billing/approve-payment/$id` | `POST /billing/$id/approve` | path + method |
| 43 | `PUT /billing/reject-payment/$id` | `POST /billing/$id/reject` | path + method |
| 44 | `GET /billing/payment/$id` | `GET /billing/$id/proof` (signed URL) | path + **response is `{viewUrl,expiresInSeconds}` not a bill** |
| 45 | (none) | `GET /billing/$id/history` | new capability |
| 46 | `GET /reviews/$messId/me` | `GET /reviews/$messId/mine` | path |
| 47 | `PUT /reviews/$messId` | same | ok; response fields renamed |
| 48 | `GET /reviews/$messId` | same | `meta.averageRating` |
| 49 | `POST /menu` body `{date,...}` | `PUT /menus/my-mess` body `{serviceDate,...}` | path + method + body field |
| 50 | `GET /menu/$messId?startDate&endDate` | `GET /menus/$messId?from&to` | path + query names |

## Step 3 items
- **3.1 live pricing**: membership `rateRupees` is the plan's live rate; drop any client-side caching; manager plan-edit copy must not say "new members only".
- **3.2 leave override**: `POST /attendance/kiosk/override-leave` body `{membershipId,pin,meal}`; only today, only the meal being served.
