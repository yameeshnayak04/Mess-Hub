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
- 🔒 **Secure Password Login:** Password authentication via phone number.  

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

# Mess Management System - Backend

A complete backend solution for managing mess operations with dual roles (Customers and Managers).

## Features

- **Dual Role System**: Customer and Manager roles with distinct permissions
- **Geospatial Discovery**: Find nearby messes using MongoDB geospatial queries
- **Membership Management**: Join, approve, and manage mess memberships
- **Attendance Tracking**: Kiosk-based attendance with meal tracking
- **Leave Management**: Apply for leaves with rebate eligibility
- **Billing System**: Automated monthly bill generation with rebate calculations
- **Menu Management**: Daily menu planning for lunch and dinner
- **Review System**: Rate and review messes
- **Payment Proof**: Upload and verify payment screenshots

## Tech Stack

- Node.js
- Express.js
- MongoDB with Mongoose
- JWT Authentication
- Bcrypt for password hashing
- Multer for file uploads
- Joi for validation

## Installation

1. Clone the repository
2. Install dependencies:

## 🚀 Getting Started

Detailed setup and installation instructions can be found in the `/docs` folder.

📘 **Documentation Index**

- 🧩 [System Design](/docs/SYSTEM_DESIGN.md)  
- 🧠 [API Specification](/docs/API_SPECIFICATION.md)  
- 🗺️ [Project Roadmap](/docs/ROADMAP.md)  
- 📄 [Software Requirements](/docs/SRS.md)

---

> _Mess Hub combines smart architecture with seamless UX — designed to simplify daily mess operations for both owners and customers._

version - 1 : 23/10/2025
