# WHO Logbook

A professional digital logging application built with Flutter and Firebase. This system is designed for high-integrity data collection, featuring dynamic form generation and a multi-tier approval workflow for administrators and supervisors.

## 📱 Features

* **Dynamic Form Engine**: Generates UI inputs (Text, Number, Date, Time) based on Firestore templates.
* **Role-Based Access Control**: Custom views and permissions for Operators, Supervisors, and Admins.
* **Identity Management**: Prevents duplicate logs for the same time period (Daily, Weekly, Monthly, etc.).
* **Approval System**: Supervisors can review, approve, or reject logs with real-time status updates.
* **WHO Branding**: Integrated Teal-Water (#0B6E69) theme and custom logo implementation.

---

## 📂 Project Structure & File Map



### **Core Layer** (`/lib/core`)
* `constants.dart`: Centralized brand colors, LogTypes, and Status definitions.
* `firebase_refs.dart`: Type-safe shorthands for Firestore collections.
* `time_period.dart`: Logic for generating unique `periodKey` and `logId`.

### **Feature Layer** (`/lib/features`)
* **auth/**: Contains `login_screen.dart` (branded login) and `auth_gate.dart` (routing logic).
* **dashboard/**: Role-specific home screens with dynamic navigation tiles.
* **logs/**:
    * `dynamic_log_screen.dart`: The core engine that builds forms from templates.
    * `widgets/`: Contains `dynamic_input_field.dart` and `repeater_field.dart`.
* **review/**: Workflow for supervisors to filter, view, and approve/reject logs.
* **templates/**: Error handling and fallback screens for unconfigured log types.

### **Data Layer** (`/lib/models`)
* `app_user.dart`: Model for user profiles including `roleId` and `assignedDistrictIds`.
* `form_template.dart`: Schema for dynamic field configurations.
* `log_entry.dart`: The structure for submitted log data.

### **Logic Layer** (`/lib/services` & `/lib/stores`)
* `log_service.dart`: Handles the logic for submitting logs and preventing duplicates.
* `auth_service.dart`: Manages Firebase Authentication sessions.
* `session_store.dart`: Manages global state for the currently logged-in user.

---

## 🛠️ Technical Specifications

### **Dependencies**
* **Framework**: Flutter ^3.10.4
* **Database**: Cloud Firestore
* **Auth**: Firebase Auth
* **State Management**: Store-based session management
* **Icons**: Generated via `flutter_launcher_icons`

### **Theming**
| Component | Color Code |
| :--- | :--- |
| Primary Teal | `#0B6E69` |
| Background | `#F7F8FA` |
| Card/Surface | `#FFFFFF` |
| Text Primary | `#2D3142` |

---

## 🛡️ Security Rules (Firestore)



The system uses a strict security model:
1.  **Operators**: Can `create` logs where `userId == request.auth.uid`.
2.  **Supervisors**: Can `read` and `update` (approve) logs where the `districtId` is found in their `assignedDistrictIds` array.
3.  **Admins**: Global read/write permissions for all collections.

---

## 🚀 Setup & Installation

1.  **Initialize Project**:
    ```bash
    flutter pub get
    ```
2.  **Generate Launcher Icons**:
    ```bash
    flutter pub run flutter_launcher_icons
    ```
3.  **Configure Firebase**:
    * Place `google-services.json` in `android/app/`.
    * Place `GoogleService-Info.plist` in `ios/Runner/`.
4.  **Run Application**:
    ```bash
    flutter run
    ```

---

## 📝 Usage Notes

* **Custom IDs**: Logs are stored with a document ID format of `UID_LOGTYPE_PERIODKEY` to ensure data integrity.
* **Validation**: All dynamic fields utilize Bengali validation messages (e.g., "এই ঘরটি পূরণ করুন").