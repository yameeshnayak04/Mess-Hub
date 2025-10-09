# 🏗️ System Design Document  
### Mess Discovery & Management Platform — Version 2.0

This document outlines the architecture and technical design decisions for the **Mess Hub** platform.

---

## 🧩 1. High-Level Architecture

The system follows a **Client–Server Architecture**, consisting of three distinct Flutter clients communicating with a central **Node.js backend** via REST APIs.

### 🧠 Components

#### Clients
- **Customer App (Flutter)** — For users to discover and manage mess memberships.  
- **Manager App (Flutter)** — For mess owners to manage business operations.  
- **Kiosk App (Flutter)** — A locked-down tablet interface for meal/attendance tracking.

#### Backend Server
- **Node.js + Express.js** handles business logic, authentication, and API routing.  
- **MongoDB Atlas** serves as the primary database for scalability and persistence.

---

## 🎯 2. Frontend Architecture (Flutter)

To ensure the app is scalable, maintainable, and performant, a **Clean Architecture pattern** is adopted.

### 🧱 2.1 Architectural Pattern — Clean Architecture

The app is divided into **three primary layers**:

| Layer | Responsibility |
|-------|----------------|
| **Presentation Layer** | Contains UI (Widgets) and State Management (Riverpod). Handles rendering and user input. |
| **Domain Layer** | Core business logic, entities, and use cases. Independent of UI and data sources. |
| **Data Layer** | Handles data operations via repositories (API + local cache). Responsible for networking and persistence. |

This separation ensures **testability, scalability, and modularity**.

---

### ⚙️ 2.2 Frontend Technology Choices

| Layer | Technology | Justification |
|-------|-------------|---------------|
| **State Management** | **Riverpod (v2+)** | Compile-time safety, minimal boilerplate, predictable and performant — ideal for complex apps. |
| **Networking** | **Dio** | Interceptors for JWT tokens, caching, and advanced error handling. |
| **Local Storage** | **Hive / Isar** | High-performance NoSQL databases for caching mess listings, profiles, and offline support. |
| **Async Updates** | **StreamProvider (Riverpod)** | Enables real-time dashboard and live counters without manual refreshes. |
| **App Optimization** | **Memoization (Riverpod)** | Prevents redundant widget rebuilds and expensive computations, improving FPS and efficiency. |

---

## ⚙️ 3. Backend Architecture (Node.js)

The backend follows a **multi-tenant REST API** design.

| Component | Technology | Purpose |
|------------|-------------|----------|
| **Framework** | **Express.js** | Lightweight, fast, and flexible API framework. |
| **Database** | **MongoDB (Atlas)** | Scalable NoSQL cloud database suited for varied structures (messes, users, rules). |
| **ODM** | **Mongoose** | Provides schema validation, hooks, and clean modeling of documents. |
| **Authentication** | **JWT + OTP** | Secure password-less login using phone numbers and tokens. |
| **Middleware** | **Custom protect, isManager, isCustomer** | Handles authentication and role-based authorization. |

---

## 🗂️ 4. Database Schema (High-Level)

| Collection | Description |
|-------------|--------------|
| **users** | Stores user profiles and roles (customer or manager). |
| **messes** | Details of each mess (name, location, owner, plans, rules). |
| **memberships** | Links a user to a mess with a chosen plan. |
| **leaves** | Records user leave requests for rebates. |
| **mealRecords** | Logs daily meal attendance for members. |

---

## 🧩 5. System Architecture Diagram

```mermaid
flowchart LR
    subgraph Client_Side["📱 Client Applications (Flutter)"]
        A1["👤 Customer App"]
        A2["🏢 Manager App"]
        A3["💳 Kiosk App"]
    end

    subgraph Server_Side["🖥️ Backend (Node.js / Express.js)"]
        B1["REST API Controllers"]
        B2["Business Logic Layer"]
        B3["Authentication (JWT, OTP)"]
        B4["Middleware (protect, isManager, isCustomer)"]
    end

    subgraph Database["🗄️ MongoDB Atlas"]
        C1["users"]
        C2["messes"]
        C3["memberships"]
        C4["leaves"]
        C5["mealRecords"]
    end

    A1 -->|HTTP (JSON)| B1
    A2 -->|HTTP (JSON)| B1
    A3 -->|HTTP (JSON)| B1
    B1 --> B2
    B2 --> B3
    B2 --> B4
    B2 -->|CRUD Ops| C1 & C2 & C3 & C4 & C5

erDiagram
    USERS {
        string _id PK
        string name
        string phone
        string role  // customer | manager
    }

    MESSES {
        string _id PK
        string name
        string location
        string ownerId FK
        string mealPlans[]
        object rules
    }

    MEMBERSHIPS {
        string _id PK
        string userId FK
        string messId FK
        string planType
        date startDate
        date endDate
    }

    LEAVES {
        string _id PK
        string membershipId FK
        date startDate
        date endDate
        string reason
    }

    MEALRECORDS {
        string _id PK
        string membershipId FK
        date mealDate
        string mealType // lunch | dinner
        boolean present
    }

    USERS ||--o{ MEMBERSHIPS : "has"
    MESSES ||--o{ MEMBERSHIPS : "includes"
    MEMBERSHIPS ||--o{ LEAVES : "records"
    MEMBERSHIPS ||--o{ MEALRECORDS : "logs"
