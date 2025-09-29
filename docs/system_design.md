# 🏗️ System Design: Smart Mess Management System

---

## 1. High-Level Architecture

The system follows a **Client-Server Architecture** with three clients:

1. **User Mobile App** (for students/employees)
2. **Manager Dashboard App** (for mess staff/admins)
3. **Kiosk App** (Integrated Counter System at food counter)

All clients communicate with a **Node.js + Express backend**, which interacts with **MongoDB** as the persistence layer.

---

## 2. Workflow Diagrams

### Regular Member Flow

1. User approaches counter
2. Selects photo + enters 4-digit PIN on kiosk
3. Backend validates & logs entry
4. Kiosk greys out user to prevent re-check-in
5. Manager dispatches meal

### Daily User Flow

1. User pays manager directly
2. Manager taps "+1 Daily User" button
3. Backend increments daily count
4. Meal is served

---

## 3. Component Design

### 3.1 Frontend (Flutter + Riverpod)

* **User App**

  * Authentication UI
  * Calendar Leave Management
  * Profile & PIN reset
  * Meal & Billing History
* **Manager Dashboard**

  * Live meal count screen
  * Rule settings
  * Billing automation
  * User management
* **Kiosk**

  * Photo grid of members
  * PIN entry keypad
  * "+1 Daily User" quick button

### 3.2 Backend (Node.js + Express)

* **Authentication**

  * JWT tokens for session management
  * bcrypt.js for password hashing
* **API Endpoints**

  * `/auth/register` `/auth/login`
  * `/meals/log` (Kiosk logging)
  * `/leaves/apply`
  * `/billing/generate`
  * `/users/list`
* **Business Logic**

  * Leave handling & meal count adjustment
  * Prevent duplicate entries per meal session
  * Automated billing with rebates

### 3.3 Database (MongoDB + Mongoose)

* **Users Collection**

  ```json
  {
    "_id": "ObjectId",
    "name": "John Doe",
    "email": "john@example.com",
    "pin": "hashed",
    "role": "user/manager",
    "mealPlan": "monthly/daily",
    "history": [ mealRecordIds ]
  }
  ```
* **MealRecords Collection**

  ```json
  {
    "_id": "ObjectId",
    "userId": "ObjectId | null",
    "date": "2025-09-29",
    "mealType": "lunch/dinner",
    "timestamp": "ISODate",
    "isDailyUser": false
  }
  ```
* **Leaves Collection**

  ```json
  {
    "userId": "ObjectId",
    "startDate": "2025-10-01",
    "endDate": "2025-10-03",
    "status": "approved/pending"
  }
  ```
* **Invoices Collection**

  ```json
  {
    "userId": "ObjectId",
    "month": "2025-09",
    "totalMeals": 45,
    "rebates": 3,
    "amount": 2200
  }
  ```

---

## 4. Security & Reliability

* JWT authentication with token expiry
* Bcrypt for password & PIN hashing
* Grey-out mechanism at Kiosk prevents re-check-in
* Role-based access (User / Manager / Admin)

---

## 5. Scalability Considerations

* MongoDB sharding for large datasets
* Stateless backend scaling with load balancers
* WebSockets for **real-time updates** (future enhancement)
* API rate limiting to prevent misuse

---

## 6. Future Enhancements

* QR/Face Recognition for faster check-in
* Digital payments for daily users
* Predictive analytics for meal planning
