# WHO Logbook – Digital Transformation System

A production-grade digital logging application built with **Flutter** and **Firebase**.

This system replaces manual paper-based logbooks used by field operators and administrative personnel. It ensures structured data collection, eliminates duplication, enables supervisory workflows, and maintains long-term audit traceability.

---

## 📱 Core Features

### 🔹 Dynamic Form Engine
- UI fields (Text, Number, Date, Time, Dropdown) are generated dynamically from Firestore templates.
- Templates are configured based on:
  - User Role
  - District (e.g., Netrokona, Sunamganj)
  - Log Type
- Fully configurable without app updates.

### 🔹 Role-Based Access Control (RBAC)
Granular permission control for:
- Operators
- Mechanics
- Inspectors
- Water Superintendents
- Executive Engineers
- Admins

Access rules enforced via:
- Firestore Security Rules
- Firebase Custom Claims

### 🔹 Multi-Cycle Logging Support
Supports structured logging cycles:
- Daily
- Weekly
- Monthly
- Quarterly
- Half-Yearly
- Yearly
- Flood-Time Logs
- New Connection Logs

### 🔹 Data Integrity Protection
- Prevents duplicate submissions using composite keys.
- Uses Firestore transactions.
- Unique `periodKey` generation (e.g., `2026-W02`).

### 🔹 Review & Approval Workflow
Multi-stage approval system:
- Pending → Approved
- Pending → Rejected (with feedback)
- Approved → Locked (immutable)

Supervisors can filter by:
- District
- Role
- Status

### 🔹 Offline-First Architecture
- Firestore local persistence enabled.
- Seamless auto-sync when connectivity is restored.
- Designed for low-network rural environments.

### 🔹 Full Bangla Support
- Bangla field labels
- Bangla data entry
- Unicode-safe rendering
- Optimized for field operators

---

# 🏗️ Architecture Overview

The project follows a clean, layered structure.

```
lib/
 ├── core/
 ├── features/
 ├── models/
 ├── services/
```

---

# 📂 Project Structure

## 1️⃣ Core Layer (`/lib/core`)

### `constants.dart`
- Brand colors (#0B6E69)
- Global enums
- System-wide constants

### `firebase_refs.dart`
- Type-safe Firestore references:
  - `/users`
  - `/logs`
  - `/formTemplates`
  - `/auditLogs`

### `time_period.dart`
- Generates unique `periodKey`
- Ensures cycle-based uniqueness
- Example output:
  - `2026-D-001`
  - `2026-W02`
  - `2026-M01`

---

## 2️⃣ Feature Layer (`/lib/features`)

### 🔐 auth/
- `login_screen.dart`
- Firebase Phone + OTP Authentication
- Secure role fetching post-login

### 📊 dashboard/
- Role-based dynamic home screen
- Filters log types based on permissions

### 📝 logs/
- `dynamic_log_screen.dart`
  - Loads templates based on:
    - Role
    - District
    - Log Type
  - Renders dynamic UI fields
- `widgets/`
  - Bangla-supported input components
  - Validation handlers

### 🔍 review/
- Supervisory dashboard
- Filter logs by:
  - District
  - Role
  - Status
- Approve / Reject with feedback

---

## 3️⃣ Data Layer (`/lib/models`)

### `app_user.dart`
```dart
roleId
districtId
assignedDistrictIds
displayName
phoneNumber
```

### `form_template.dart`
```dart
roleId
districtId
logType
fields[]
version
```

### `log_entry.dart`
```dart
userId
districtId
logType
periodKey
formVersion
status
auditTrail[]
```

---

## 4️⃣ Logic Layer (`/lib/services`)

### `log_service.dart`
- Secure log submission
- Transaction-based writes
- Cloud Function validation
- Audit trail updates

### `export_service.dart`
- PDF generation
- Excel generation
- Upload to Firebase Storage
- Supervisor-accessible reports

---

# 🔥 Backend Infrastructure

## Authentication
- Firebase Phone/OTP Authentication
- Custom Claims for RBAC

## Database
- Cloud Firestore (NoSQL)
- Real-time sync
- Indexed composite queries
- Transaction-protected writes

## Server Logic
- Firebase Cloud Functions:
  - Submission validation
  - Role verification
  - Audit log tracking
  - Secure approval updates

## Storage
- Firebase Cloud Storage
- Exported PDF and Excel reports

---

# 🛡️ Security Model

Access control enforced using:

- Firestore Security Rules
- Firebase Authentication
- Custom Claims
- Server-side validation via Cloud Functions

### Role Permissions

### Operators
- Can create logs
- Can edit only before approval
- Limited to own district

### Supervisors
- View all logs within `assignedDistrictIds`
- Approve / Reject submissions
- Cannot modify submitted data

### Admins
- Full system access
- Manage:
  - Users
  - Roles
  - Templates
  - District configurations

---

# 📦 Firestore Collections Structure

```
/users
/formTemplates
/logs
/auditLogs
/exports
```

---

# 📱 Minimum Hardware Requirements

| Requirement | Minimum |
|------------|----------|
| Android OS | 8.0+ |
| RAM        | 2GB |
| Storage    | 32GB |
| Internet   | Intermittent supported |

---

# 🚀 Deployment

## Build APK
```bash
flutter build apk --release
```

## Build App Bundle
```bash
flutter build appbundle --release
```

## Enable Firestore Offline Persistence
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```

---

# 🧪 Production Best Practices Implemented

- Composite Indexing
- Transaction-safe writes
- Strict RBAC enforcement
- Versioned form templates
- Immutable approval locking
- Audit trail logging
- Offline-first design

---

# 📊 System Impact

This system eliminates:
- Manual paper errors
- Duplicate log entries
- Lost field records
- Approval delays
- Non-traceable corrections

It introduces:
- Structured digital governance
- Real-time supervisory visibility
- Secure audit trails
- Scalable infrastructure

---

# 👨‍💻 Built With

- Flutter (Frontend)
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Cloud Storage

---

# 📄 License

Private / Internal Use Only

---

# ✨ Maintained By

OneLine Solution
