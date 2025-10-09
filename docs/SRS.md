# Software Requirements Specification (SRS)  
**Mess Discovery & Management Platform**  
**Version:** 2.0  
**Date:** 09-10-2025  

---

## 1. Introduction

### 1.1 Purpose
This document provides a detailed description of the requirements for the Mess Discovery & Management Platform. Its purpose is to define the features and constraints of a multi-tenant system that connects users with local mess services, serving as a guiding blueprint for development.

### 1.2 Project Scope
The system will be a full-stack application consisting of:  
- A Flutter-based mobile app for Customers  
- A Flutter app for Mess Owners  
- A dedicated Kiosk interface  
- A centralized Node.js backend with a MongoDB database  

The scope includes mess discovery, filtering, profiles, and a membership management system.

---

## 2. Overall Description
The system is a multi-tenant platform where each mess is a "tenant" with its own members and rules.  
It relies on geolocation for "nearby" search functionality and provides distinct workflows for customers finding messes and owners managing them.  
The core attendance tracking uses the "Integrated Counter System" at each mess location.

---

## 3. Functional Requirements

### 3.1 Platform Authentication (FR-AUTH)
- **FR-AUTH-01:** Users (Customers, Mess Owners) shall register and log in using a phone number and OTP.  
- **FR-AUTH-02:** The system shall support "Customer" and "Mess Owner" roles with different permissions.

### 3.2 Mess Registration & Profile (FR-MESS)
- **FR-MESS-01:** Mess Owners shall register their mess with details including Name, Address, Geolocation, and Service Type (Daily Only, Monthly Only, Both).  
- **FR-MESS-02:** Mess Owners shall define one or more monthly meal plans with corresponding rates.

### 3.3 Customer: Discovery & Membership (FR-CUST)
- **FR-CUST-01:** Customers shall view nearby messes on a list and/or map.  
- **FR-CUST-02:** Customers shall filter messes by Service Type.  
- **FR-CUST-03:** Customers can join a mess that is not Daily Only.  
- **FR-CUST-04:** A customer can hold multiple active memberships simultaneously.  
- **FR-CUST-05:** Customers can mark leaves and view billing history for each membership.

### 3.4 Attendance & Meal Logging (FR-ATT)
- **FR-ATT-01:** Each mess Kiosk's "Monthly Member" grid shall only display members of that specific mess.  
- **FR-ATT-02:** The system shall verify a member's PIN and active membership status for the specific mess before logging a meal.  
- **FR-ATT-03:** The "Daily User" button on the Kiosk shall increment a counter for that specific mess.

### 3.5 Manager Dashboard (FR-MAN)
- **FR-MAN-01:** A manager's dashboard shall be strictly scoped to their own mess.  
- **FR-MAN-02:** The dashboard shall display live meal counts for their mess only.  
- **FR-MAN-03:** The manager shall configure leave and rebate rules for their mess only.

### 3.6 Billing System (FR-BILL)
- **FR-BILL-01:** The system shall automatically generate invoices per membership at the end of each month.  
- **FR-BILL-02:** The bill calculation shall be:  

Based on the specific mess's rules.

---

### 4. Non-Functional Requirements
- **Performance:** Geolocation search results must load in under 3 seconds. Kiosk verification must complete in under 2 seconds.  
- **Scalability:** The backend must support a growing number of users and messes.  
- **Data Integrity:** Strict data separation between messes (tenants) must be enforced.  
- **Security:** All communication must be encrypted. JWTs must be used for API authorization.

---

### 5. Technology Stack
- **Frontend:** Flutter (with Riverpod, Dio, Hive/Isar)  
- **Backend:** Node.js, Express.js  
- **Database:** MongoDB (using MongoDB Atlas)  
- **Geolocation:** Google Maps API or similar
