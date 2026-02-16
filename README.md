# WHO Logbook - Digital Transformation System

A professional digital logging application built with **Flutter** and **Firebase**. [cite_start]This application digitizes manual log-book processes for field operators and administrative personnel, replacing paper-based workflows to ensure consistency, accuracy, and long-term traceability[cite: 8, 11, 14].

![App Logo](/home/muhammad/Desktop/log%20book%20app/img/edit.jpeg)

## 📱 Core Features

* [cite_start]**Dynamic Form Engine**: Generates UI inputs (Text, Number, Date, Time) based on Firestore templates specific to User Role, District (e.g., Netrokona, Sunamganj), and Log Type[cite: 91, 97].
* [cite_start]**Role-Based Access Control (RBAC)**: Custom permissions for Operators, Mechanics, Inspectors, Water Superintendents, Executive Engineers, and Admins[cite: 75, 82].
* [cite_start]**Multi-Cycle Logging**: Supports Daily, Weekly, Monthly, Quarterly, Half-Yearly, Yearly, Flood-time, and New Connection logs[cite: 107, 189].
* [cite_start]**Integrity Management**: Prevents duplicate log submissions for the same period using composite keys and Firestore transactions[cite: 110, 213].
* [cite_start]**Review & Approval Workflow**: Multi-level status transitions (Pending → Approved/Rejected → Locked) with feedback loops for rejections[cite: 162, 216].
* [cite_start]**Offline Persistence**: Designed for intermittent internet connectivity with Firestore local caching and automatic synchronization[cite: 62, 226].
* [cite_start]**Bilingual Support**: Full support for Bangla content input and display to accommodate field operators[cite: 66, 105, 192].

---

## 📂 Project Structure & File Map

### **Core Layer** (`/lib/core`)
* [cite_start]`constants.dart`: Centralized brand colors (#0B6E69) and system-wide definitions[cite: 23].
* [cite_start]`firebase_refs.dart`: Type-safe shorthands for Firestore collections (`/users`, `/logs`, `/formTemplates`)[cite: 212, 243].
* [cite_start]`time_period.dart`: Logic for generating unique `periodKey` (e.g., 2026-W02) to maintain data integrity[cite: 243].

### **Feature Layer** (`/lib/features`)
* [cite_start]**auth/**: `login_screen.dart` featuring Phone + OTP authentication via Firebase Auth[cite: 57, 210].
* [cite_start]**dashboard/**: Dynamic home screens that filter log categories based on the user's assigned role[cite: 190].
* **logs/**: 
    * [cite_start]`dynamic_log_screen.dart`: The engine loading templates based on Role + District + Type[cite: 103, 193].
    * [cite_start]`widgets/`: Custom Bangla-supported input fields and validation[cite: 192, 238].
* [cite_start]**review/**: Supervisory dashboard for filtering logs by District, Role, and Status[cite: 127, 154].

### **Data Layer** (`/lib/models`)
* [cite_start]`app_user.dart`: Profiles including `roleId`, `districtId`, and `assignedDistrictIds` for supervisors[cite: 241].
* [cite_start]`form_template.dart`: JSON schema for dynamic fields, labels, and validation rules[cite: 243].
* [cite_start]`log_entry.dart`: Structure for submitted data including `formVersion` and `auditTrail`[cite: 213, 244].

### **Logic Layer** (`/lib/services`)
* [cite_start]`log_service.dart`: Handles Firebase Cloud Functions for secure submission and approval[cite: 214, 250].
* [cite_start]`export_service.dart`: Manages PDF and Excel report generation via Cloud Storage[cite: 60, 218].

---

## 🛠️ Technical Specifications

### **Backend Infrastructure (Firebase)**
* [cite_start]**Auth**: Firebase Phone/OTP Authentication[cite: 210].
* [cite_start]**Database**: Cloud Firestore (NoSQL) for real-time sync and scalability[cite: 58, 234].
* [cite_start]**Logic**: Firebase Cloud Functions for server-side validation and audit logs[cite: 59, 231].
* [cite_start]**Storage**: Firebase Cloud Storage for exported reports (PDF/Excel)[cite: 218].

### **Minimum Hardware (Mobile)**
* [cite_start]**OS**: Android 8.0+[cite: 220].
* [cite_start]**RAM**: 2GB Minimum[cite: 220].
* [cite_start]**Storage**: 32GB Minimum[cite: 220].

---

## 🛡️ Security & Permissions (Firestore)

[cite_start]Access is enforced via Firestore Security Rules and Custom Claims[cite: 230]:
1. [cite_start]**Operators**: Read/Write access only to their own submissions within their assigned district[cite: 247].
2. [cite_start]**Supervisors**: View and Approve/Reject access for all users within their `assignedDistrictIds`[cite: 248].
3. [cite_start]**Admins**: Full global access to manage users, roles, and form templates[cite: 248].

