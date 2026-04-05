# MOHAS Coach — Business Coaching Management App

> A full-stack mobile application built for **Mohas Consult** to manage the MESMER Business Coaching Program across Ethiopia. Designed for field coaches, supervisors, and program managers to track enterprise development, coaching visits, assessments, and graduation.

**Live Backend:** https://mohas-2.onrender.com

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Reference](#api-reference)
- [User Roles](#user-roles)
- [Deployment](#deployment)
- [Graduation Criteria](#graduation-criteria)

---

## Overview

MESMER Coach digitizes the entire lifecycle of the MESMER Business Coaching Program — from enterprise registration and baseline assessment through structured coaching visits, training sessions, quality control, and final graduation with certificate issuance.

The app replaces paper-based processes with a structured digital workflow that enforces program standards, captures evidence, and gives supervisors real-time visibility into coach performance.

---

## Features

### Coach
- Role-based login routing to the correct dashboard
- View assigned enterprises with search and filter
- Record coaching visits — key focus areas, issues, agreed actions, measurable results
- Capture and upload photo evidence directly to the server
- Complete Baseline, Midline, and Endline assessments
- Create and manage Individual Action Plans (IAP) per enterprise
- View full coaching history per enterprise
- Mark training session attendance
- Offline mode — visits saved locally and synced when back online

### Supervisor / Program Manager
- Full enterprise overview with live statistics
- Add new enterprises with detailed registration form (region, gender, sector dropdowns)
- Assign enterprises to coaches
- QC Queue — review, approve, or reject coaching visits with notes (Pending / Approved / Rejected tabs)
- Coach performance report — visits, enterprises handled, average sessions, completion rate
- Training session management — create sessions and record attendance
- Graduation checklist — triangulation lock (baseline + 8 approved visits + evidence)
- Issue and print PDF completion certificates
- Reports and document generation

---

## Tech Stack

### Backend
| Technology | Purpose |
|---|---|
| Node.js + Express | REST API server |
| PostgreSQL | Relational database |
| Prisma ORM | Schema, migrations, queries |
| JWT | Authentication tokens |
| bcryptjs | Password hashing |
| Multer | Evidence photo file uploads |
| dotenv | Environment variable management |

### Frontend
| Technology | Purpose |
|---|---|
| Flutter (Dart) | Cross-platform Android app |
| http / Dio | REST API calls and multipart file upload |
| flutter_secure_storage | Secure JWT token storage |
| sqflite | Local SQLite for offline mode |
| connectivity_plus | Network status detection |
| image_picker | Camera capture for evidence photos |
| pdf + printing | PDF certificate generation |
| fl_chart | Performance charts |

---

## Project Structure

```
mesmer-coach/
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma        # Database models
│   │   └── seed.js              # Creates test users (1 supervisor + 8 coaches)
│   ├── routes/
│   │   ├── auth.js              # Login, register, list coaches
│   │   ├── enterprises.js       # Enterprise CRUD + IAP + assign coach
│   │   ├── coaching-visits.js   # Visits + QC approve/reject
│   │   ├── assessments.js       # Baseline / Midline / Endline
│   │   ├── trainings.js         # Training sessions + attendance
│   │   ├── upload.js            # Evidence photo upload (Multer)
│   │   └── graduation.js        # Graduation checklist + certificate lock
│   ├── middleware/
│   │   └── auth.js              # JWT verification middleware
│   ├── uploads/                 # Stored evidence photos (gitignored)
│   ├── index.js                 # Express app entry point
│   └── .env                     # Local environment variables (gitignored)
│
└── frontend/mohas/
    └── lib/
        ├── main.dart
        ├── constants.dart           # Single place to change server URL
        ├── theme/
        │   └── app_theme.dart       # Mohas brand colors + Material 3 theme
        ├── screens/
        │   ├── login_screen.dart
        │   ├── dashboard_screen.dart
        │   ├── supervisor_dashboard.dart
        │   ├── enterprise_list_screen.dart
        │   ├── add_enterprise_screen.dart
        │   ├── assign_enterprise_screen.dart
        │   ├── coaching_visit_screen.dart
        │   ├── coaching_history_screen.dart
        │   ├── assessment_screen.dart
        │   ├── iap_screen.dart
        │   ├── training_screen.dart
        │   ├── training_attendance_screen.dart
        │   ├── qc_queue_screen.dart
        │   ├── graduation_screen.dart
        │   ├── coach_performance_screen.dart
        │   ├── all_visits_screen.dart
        │   └── reports_screen.dart
        └── services/
            └── offline_sync.dart
```

---

## Getting Started

### Prerequisites
- Node.js v18+
- PostgreSQL 14+
- Flutter SDK 3.10+

### Backend Setup

```bash
cd mesmer-coach/backend
npm install
```

Create `.env`:
```env
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/mesmer_coach"
JWT_SECRET="mesmercoach2026supersecret"
PORT=5000
```

```bash
npx prisma migrate dev --name init
npx prisma generate
npm run seed
npm run dev
```

### Frontend Setup

Update `lib/constants.dart`:
```dart
static const String baseUrl = 'https://mohas-2.onrender.com'; // production
// static const String baseUrl = 'http://YOUR_LOCAL_IP:5000'; // local dev
```

```bash
cd mesmer-coach/frontend/mohas
flutter pub get
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## Default Users (after seeding)

All passwords: `password123`

| Role | Email | Dashboard |
|---|---|---|
| Supervisor | supervisor@mohas.com | Supervisor |
| Coach | coach_habtamu@mohas.com | Coach |
| Coach | coach_tigist@mohas.com | Coach |
| Coach | coach_dawit@mohas.com | Coach |
| Coach | coach_selam@mohas.com | Coach |
| Coach | coach_yonas@mohas.com | Coach |
| Coach | coach_meron@mohas.com | Coach |
| Coach | coach_biruk@mohas.com | Coach |
| Coach | coach_hana@mohas.com | Coach |

---

## API Reference

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register` | Create user |
| POST | `/api/auth/login` | Login, returns JWT |
| GET | `/api/auth/coaches` | List all coaches |

### Enterprises
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/enterprises` | List all enterprises |
| POST | `/api/enterprises` | Create enterprise |
| PUT | `/api/enterprises/:id/assign-coach` | Assign coach |
| GET | `/api/enterprises/:id/iap` | Get IAP |
| POST | `/api/enterprises/:id/iap` | Save IAP |

### Coaching Visits
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/coaching-visits` | List visits |
| POST | `/api/coaching-visits` | Create visit |
| GET | `/api/coaching-visits/qc` | Pending QC visits |
| PATCH | `/api/coaching-visits/:id/qc` | Approve or reject |
| GET | `/api/coaching-visits/coach-performance` | Performance metrics |

### Training
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/trainings` | List sessions |
| POST | `/api/trainings` | Create session |
| GET | `/api/trainings/:id/attendance` | Get attendee list |
| POST | `/api/trainings/:id/attendance` | Save attendance |

### Upload
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/upload/photo` | Upload single photo |
| POST | `/api/upload/photos` | Upload up to 5 photos |

### Graduation
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/graduation/:id/check` | Check eligibility |
| POST | `/api/graduation/:id/issue-certificate` | Issue certificate |

---

## User Roles

| Role | Dashboard |
|---|---|
| `Coach` | Coach dashboard — assigned enterprises only |
| `M_E` | Supervisor dashboard — full access |
| `Admin` | Supervisor dashboard — full access |
| `ProgramManager` | Supervisor dashboard — full access |
| `RegionalCoordinator` | Supervisor dashboard — full access |

---

## Deployment

### Backend — Render
- Service type: Web Service
- Root directory: `mesmer-coach/backend`
- Build command: `npm install && npx prisma generate && npx prisma migrate deploy`
- Start command: `npm start`
- Add PostgreSQL database from Render dashboard
- Set env vars: `DATABASE_URL`, `JWT_SECRET`, `NODE_ENV=production`

### Frontend — APK
```bash
flutter build apk --release
```
Distribute via Google Drive, Telegram, or USB.
Enable "Install unknown apps" on each phone before installing.

---

## Graduation Criteria

Certificate is locked until all three pass:

1. **Baseline Assessment** — completed and saved
2. **8 Approved Visits** — approved by supervisor through QC queue
3. **Evidence Photos** — at least one visit has photos uploaded to server

---

*Built by Sumeya hassen (Mohas conselt) — empowering MSMEs across Ethiopia.*
