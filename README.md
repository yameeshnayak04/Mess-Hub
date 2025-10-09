# 🍽️ Mess Hub: A Mess Discovery & Management Platform

**Mess Hub** is a full-stack, multi-tenant platform designed to connect users with local mess services.  
It acts as a **central aggregator**, allowing users to discover, join, and manage memberships with various messes — while providing mess owners with a **powerful suite of tools** to streamline operations, automate billing, and gain new customers.

This project is built with a focus on **clean architecture**, **scalability**, and a **high-quality user experience**, leveraging a modern and professional technology stack.

---

## ✨ Core Features

### 🧑‍🍽️ For Customers
- 📍 **Mess Discovery:** Find nearby messes on a list or map view.  
- 🔍 **Advanced Filtering:** Filter messes by service type (Monthly, Daily, Both).  
- 💳 **Multi-Membership:** Join multiple messes (e.g., lunch at one, dinner at another).  
- 📅 **Leave Management:** Mark leaves for any membership to get rebates.  
- 🧾 **Transparent Billing:** View detailed, automated monthly invoices.  
- 🔒 **Secure OTP Login:** Password-less authentication via phone number.  

### 🧑‍💼 For Mess Owners
- 📈 **Business Dashboard:** Live stats on meals served and members.  
- 👥 **Member Management:** View and manage all registered members.  
- ⚙️ **Rule Configuration:** Set custom leave and billing rebate rules.  
- 🖥️ **Integrated Kiosk:** A simple tablet interface for meal tracking.  
- 📊 **Historical Data:** Access detailed reports on member activity.  
- 📢 **Increased Visibility:** List your mess to attract local customers.  

---

## 🛠️ Technology Stack & Architecture

This project emphasizes a **professional, production-grade architecture** for maximum performance and maintainability.

---

### 🧭 Frontend (Flutter)

Built using a **Clean Architecture** approach to separate business logic from UI — ensuring the codebase is **modular**, **scalable**, and **highly testable**.

| **Layer**              | **Technology**   | **Why?** |
|------------------------|------------------|-----------|
| **State Management**   | Riverpod (v2+)   | Compile-safe, minimal boilerplate, and highly performant — the modern standard for scalable Flutter apps. |
| **Networking**         | Dio              | Advanced control over API requests with interceptors (for JWTs), caching, and robust error handling. |
| **Local Storage**      | Hive / Isar      | Blazing-fast NoSQL database for caching essential offline data like user profiles and mess lists. |
| **Architecture**       | Clean Architecture | Enforces separation of concerns (Data, Domain, Presentation layers) for a modular, testable app. |
| **Async Updates**      | StreamProvider   | Enables real-time UI updates (e.g., live dashboard counters) by listening to backend data streams. |

---

### ⚙️ Backend (Node.js)

A robust and scalable **REST API** built to handle multiple tenants (messes) securely.

| **Layer**              | **Technology**   | **Why?** |
|------------------------|------------------|-----------|
| **Framework**          | Express.js       | Fast, unopinionated, and minimalist — perfect for building powerful REST APIs. |
| **Database**           | MongoDB (Atlas)  | Flexible NoSQL database that handles diverse data structures easily and scales with Atlas. |
| **ODM**                | Mongoose         | Elegant object data modeling for MongoDB with schema validation and middleware hooks. |
| **Authentication**     | JWT & OTP        | Secure, password-less authentication flow using phone numbers and JSON Web Tokens. |

---

## 🚀 Getting Started

Detailed setup and installation instructions can be found in the `/docs` folder.

📘 **Documentation Index**

- 🧩 [System Design](/docs/SYSTEM_DESIGN.md)  
- 🧠 [API Specification](/docs/API_SPECIFICATION.md)  
- 🗺️ [Project Roadmap](/docs/ROADMAP.md)  
- 📄 [Software Requirements](/docs/SRS.md)

---

> _Mess Hub combines smart architecture with seamless UX — designed to simplify daily mess operations for both owners and customers._
