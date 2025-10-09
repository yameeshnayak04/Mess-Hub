# 🍽️ Mess Hub Platform — API Route Specification

**Base URL:** `/api`  
**Authentication:** Protected routes require `Authorization: Bearer <token>`

---

## 🔐 1. Authentication Routes — `/api/auth`

| Method | Endpoint | Description | Access | Request Body | Success Response |
|--------|-----------|--------------|---------|----------------|------------------|
| **POST** | `/register/send-otp` | Sends OTP for new user registration | Public | `{ "name", "phone", "role" }` | `{ "message": "OTP sent." }` |
| **POST** | `/register/verify-otp` | Verifies OTP and creates a new user | Public | `{ "phone", "otp" }` | `{ "user": {...}, "token": "..." }` |
| **POST** | `/login/send-otp` | Sends OTP for existing user login | Public | `{ "phone" }` | `{ "message": "OTP sent." }` |
| **POST** | `/login/verify-otp` | Verifies OTP and logs in user | Public | `{ "phone", "otp" }` | `{ "user": {...}, "token": "..." }` |

---

## 🏠 2. Mess Routes — `/api/messes`

| Method | Endpoint | Description | Access | Request Body / Query | Success Response |
|--------|-----------|--------------|---------|----------------------|------------------|
| **POST** | `/` | Mess Owner registers a new mess | Mess Owner | `{ "name", "address", ... }` | `{ "mess": {...} }` |
| **GET** | `/nearby` | Gets messes near given geo-coordinates | Customer | `?lat=...&lng=...` | `[ { "mess": {...} }, ... ]` |
| **GET** | `/:messId` | Gets public profile of a specific mess | Public | None | `{ "mess": {...} }` |
| **PUT** | `/:messId` | Updates mess details | Mess Owner | `{ "name", "address", ... }` | `{ "mess": {...} }` |
| **POST** | `/:messId/memberships` | Customer joins a mess | Customer | `{ "mealPlanId" }` | `{ "membership": {...} }` |

---

## 👤 3. Customer Routes — `/api/customers`

| Method | Endpoint | Description | Access | Request Body | Success Response |
|--------|-----------|--------------|---------|----------------|------------------|
| **GET** | `/me/profile` | Fetch logged-in user profile | Customer | None | `{ "user": {...} }` |
| **GET** | `/me/memberships` | Get all active memberships | Customer | None | `[ { "membership": {...} }, ... ]` |
| **POST** | `/me/memberships/:id/leaves` | Mark leave for a membership | Customer | `{ "startDate", "endDate" }` | `{ "message": "Leave marked." }` |
| **GET** | `/me/memberships/:id/billing` | Get billing history | Customer | None | `[ { "invoice": {...} }, ... ]` |

---

## 🧑‍🍳 4. Manager Routes — `/api/managers`

| Method | Endpoint | Description | Access | Request Body | Success Response |
|--------|-----------|--------------|---------|----------------|------------------|
| **GET** | `/my-mess` | Get manager’s mess profile | Mess Owner | None | `{ "mess": {...} }` |
| **GET** | `/my-mess/dashboard-stats` | Get live dashboard statistics | Mess Owner | None | `{ "mealsToPrepare": ..., ... }` |
| **GET** | `/my-mess/members` | List all mess members | Mess Owner | None | `[ { "user": {...} }, ... ]` |
| **PUT** | `/my-mess/rules` | Update operational rules | Mess Owner | `{ "leaveCutoffTime", ... }` | `{ "message": "Rules updated." }` |

---

## 🖥️ 5. Kiosk Routes — `/api/kiosk`

| Method | Endpoint | Description | Access | Request Body | Success Response |
|--------|-----------|--------------|---------|----------------|------------------|
| **GET** | `/messes/:id/active-members` | Fetch all active members for Kiosk grid | Kiosk | None | `[ { "userId", "name", ... }, ... ]` |
| **POST** | `/messes/:id/log-monthly` | Log meal for monthly member | Kiosk | `{ "userId", "pin" }` | `{ "message": "Meal logged." }` |
| **POST** | `/messes/:id/log-daily` | Log a daily meal entry | Kiosk | None | `{ "message": "Daily meal logged." }` |

---

## ✅ Summary

This API structure supports:
- **Role-based Access Control (RBAC)** for `Customer`, `Mess Owner`, and `Kiosk`.
- **OTP-based Authentication** for secure login.
- **Geo-location support** for nearby mess discovery.
- **Real-time dashboard and meal logging system**.

---

📘 **Version:** 1.0  
📅 **Last Updated:** October 2025  
🧩 **Developed for:** *Mess Hub Platform — Flutter + Node.js Full-Stack Project*
