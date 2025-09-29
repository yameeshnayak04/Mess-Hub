# 📡 API Documentation: Smart Mess Management System

Base URL:

```
http://localhost:5000/api
```

All requests and responses use **JSON**.
Authentication is handled via **JWT tokens** (passed in headers as `Authorization: Bearer <token>`).

---

## 🔐 Authentication

### 1. Register User

**POST** `/auth/register`

**Request**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "mypassword",
  "pin": "1234",
  "mealPlan": "monthly"
}
```

**Response**

```json
{
  "message": "User registered successfully",
  "userId": "64f9a2bc12e3..."
}
```

---

### 2. Login

**POST** `/auth/login`

**Request**

```json
{
  "email": "john@example.com",
  "password": "mypassword"
}
```

**Response**

```json
{
  "token": "jwt-token-here",
  "user": {
    "id": "64f9a2bc12e3...",
    "name": "John Doe",
    "mealPlan": "monthly"
  }
}
```

---

## 🍽️ Meal Logging

### 3. Log Meal (Monthly User via Kiosk)

**POST** `/meals/log`

**Headers**

```
Authorization: Bearer <jwt-token>
```

**Request**

```json
{
  "userId": "64f9a2bc12e3...",
  "mealType": "lunch"
}
```

**Response**

```json
{
  "message": "Meal logged successfully",
  "mealRecord": {
    "id": "671fbb12...",
    "userId": "64f9a2bc12e3...",
    "mealType": "lunch",
    "timestamp": "2025-09-29T12:30:00Z"
  }
}
```

---

### 4. Log Meal (Daily User)

**POST** `/meals/daily`

**Request**

```json
{
  "mealType": "dinner"
}
```

**Response**

```json
{
  "message": "Daily user meal logged",
  "mealRecord": {
    "id": "671fbb55...",
    "isDailyUser": true,
    "mealType": "dinner",
    "timestamp": "2025-09-29T20:00:00Z"
  }
}
```

---

## 📅 Leave Management

### 5. Apply Leave

**POST** `/leaves/apply`

**Headers**

```
Authorization: Bearer <jwt-token>
```

**Request**

```json
{
  "startDate": "2025-10-01",
  "endDate": "2025-10-03"
}
```

**Response**

```json
{
  "message": "Leave applied successfully",
  "leaveId": "672abc..."
}
```

---

### 6. Get User Leaves

**GET** `/leaves/my`

**Headers**

```
Authorization: Bearer <jwt-token>
```

**Response**

```json
[
  {
    "leaveId": "672abc...",
    "startDate": "2025-10-01",
    "endDate": "2025-10-03",
    "status": "approved"
  }
]
```

---

## 📊 Manager Dashboard

### 7. Get Live Meal Stats

**GET** `/dashboard/stats`

**Response**

```json
{
  "mealsToPrepare": 120,
  "monthlyMembersEaten": 85,
  "dailyUsersEaten": 10,
  "totalMealsServed": 95,
  "membersRemaining": 35
}
```

---

### 8. List All Users

**GET** `/users/list`

**Response**

```json
[
  {
    "id": "64f9a2bc12e3...",
    "name": "John Doe",
    "mealPlan": "monthly",
    "status": "active"
  },
  {
    "id": "64f9a2bc12e4...",
    "name": "Jane Smith",
    "mealPlan": "monthly",
    "status": "on-leave"
  }
]
```

---

## 💰 Billing

### 9. Generate Monthly Invoice

**POST** `/billing/generate`

**Request**

```json
{
  "userId": "64f9a2bc12e3...",
  "month": "2025-09"
}
```

**Response**

```json
{
  "message": "Invoice generated",
  "invoice": {
    "id": "673ccd...",
    "userId": "64f9a2bc12e3...",
    "month": "2025-09",
    "totalMeals": 45,
    "rebates": 3,
    "amount": 2200
  }
}
```

---

### 10. Get Invoice History

**GET** `/billing/my`

**Headers**

```
Authorization: Bearer <jwt-token>
```

**Response**

```json
[
  {
    "invoiceId": "673ccd...",
    "month": "2025-08",
    "totalMeals": 50,
    "amount": 2500
  },
  {
    "invoiceId": "673cce...",
    "month": "2025-09",
    "totalMeals": 45,
    "rebates": 3,
    "amount": 2200
  }
]
```

---

## 🛡️ Notes

* All sensitive data (passwords, PINs) are **hashed using bcrypt**.
* Authentication must be included for protected endpoints.
* Meal logging ensures **no duplicate entries per user per meal session**.
* API responses may include additional metadata for pagination in future.

---
