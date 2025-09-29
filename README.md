# 🍽️ Smart Mess Management System

A full-stack digital platform designed to bring modern efficiency and transparency to traditional mess and canteen operations. The system eliminates food wastage, prevents financial leakage, and ensures fairness for all users through a **foolproof Integrated Counter System**.

---

## 🚀 Core Idea

The system merges **meal dispatch with attendance marking**, ensuring every served thali is tracked in real-time.
Built for scalability, it can be deployed in:

* 🎓 College Hostels
* 🏢 Corporate Canteens
* 🏠 Private Messes

---

## ⚡ Features

### 👤 User Mobile App (Flutter)

* Secure Authentication (JWT)
* Leave Management with calendar UI
* Profile Management (PIN reset, profile edit)
* Transparent Meal & Billing History

### 👨‍🍳 Manager Dashboard (Flutter)

* Live Meal Tracking
* Meals to Prepare vs. Meals Served
* Monthly/Daily User Count
* Automated Monthly Billing
* User Oversight (profiles, logs)
* Business Rule Configuration

### 📟 Integrated Counter (Kiosk)

* **Monthly Users:** Photo + PIN verification
* **Daily Users:** Quick "+1 Daily User" button
* Backend logs meal instantly
* Prevents duplicate meal entries

---

## 🛠️ Technology Stack

### Frontend (Flutter)

* Framework: Flutter (Dart)
* State Management: Riverpod

### Backend (Node.js)

* Runtime: Node.js (Express.js)
* Authentication: JWT
* Password Hashing: bcrypt.js

### Database

* MongoDB with Mongoose ODM

---

## 🏗️ Architecture

* **Client (Flutter Apps):** User App, Manager Dashboard, Kiosk App
* **Server (Node.js + Express):** RESTful API layer
* **Database (MongoDB):** Persistent storage

All communication is **JSON over HTTP**.

---

## 📂 Project Structure (Planned)

```
smart-mess-management/
│── frontend/              # Flutter apps (User, Manager, Kiosk)
│── backend/               # Node.js + Express server
│   ├── models/            # Mongoose schemas
│   ├── routes/            # API endpoints
│   ├── controllers/       # Business logic
│   ├── middlewares/       # JWT, auth checks
│   └── utils/             # Helper functions
│── docs/                  # Documentation
│   ├── SYSTEM_DESIGN.md
│   └── ROADMAP.md
│── README.md
```

---

## 📌 Future Enhancements

* QR/Face Recognition based check-in
* Online payment integration for daily users
* AI-driven meal prediction system

---

## 🤝 Contributing

Pull requests are welcome! For significant changes, please open an issue first to discuss what you’d like to change.

---

## 📄 License

MIT License © 2025
