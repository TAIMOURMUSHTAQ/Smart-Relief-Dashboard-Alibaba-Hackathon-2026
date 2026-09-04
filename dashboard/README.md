# Relief Dashboard

A Flutter disaster-relief logistics application for coordinating relief supplies between field volunteers and coordinators/admins. The app supports real-time inventory tracking, relief request submission, stock allocation, interactive maps, and analytics dashboards.

## Features

- **Role-based access**
  - **Coordinator / Admin**: manage warehouses and inventory, review relief requests, allocate stock, update delivery status, view analytics dashboard and map.
  - **Field Volunteer**: submit new relief requests with location and photo, view submitted requests, and see request locations on a map.
- **Real-time data** with Cloud Firestore streams.
- **Firebase Authentication** using email and password.
- **Firebase Storage** for request photos.
- **Interactive maps** powered by `flutter_map` and OpenStreetMap tiles.
- **Admin analytics** with summary cards and a status bar chart using `fl_chart`.
- **Material 3** UI with a clean, responsive layout.

## Screenshots

### Authentication

![Sign up screen](screenshots/signup-screen.png)
*Account creation screen where users select their role (admin/coordinator or field volunteer).*

### Admin / Coordinator

![Admin dashboard](screenshots/admin-dashboard.png)
*Admin analytics dashboard showing active requests, critical/high priority count, and a requests-by-status bar chart.*

![Admin requests](screenshots/admin-requests.png)
*Relief request list with status filtering and one-tap stock allocation.*

![Admin inventory](screenshots/admin-inventory.png)
*Inventory grouped by category with warehouse and low-stock information.*

![Admin map](screenshots/admin-map.png)
*Interactive map showing warehouses and active relief requests by urgency.*

### Field Volunteer

![Volunteer new request](screenshots/volunteer-home.png)
*New relief request form with location coordinates, urgency level, and items needed.*

![Volunteer requests](screenshots/volunteer-requests.png)
*List of submitted requests with real-time status tracking.*

![Volunteer map](screenshots/volunteer-map.png)
*Map view of submitted request locations.*

## Demo credentials

Two demo accounts are seeded automatically the first time an admin opens the app and taps the seed button in the top-right menu:

| Role | Email | Password |
|------|-------|----------|
| Admin / Coordinator | `admin@relief.demo` | `demo123456` |
| Field Volunteer | `volunteer@relief.demo` | `demo123456` |

You can also register new accounts from the sign-up screen once Firebase is fully configured.

## Tech stack

- Flutter 3.47.0+
- Dart
- Firebase Core, Auth, Cloud Firestore, Storage
- `provider` for state management
- `flutter_map` + `latlong2` for maps
- `fl_chart` for analytics
- `image_picker` and `geolocator` for volunteer requests

## Project structure

```
dashboard/
├── android/                  # Android project files
│   └── app/google-services.json
├── lib/
│   ├── demo/                 # Temporary demo services (for screenshots without Firestore)
│   ├── main.dart             # Production entry point
│   ├── main_demo_admin.dart  # Demo entry point for admin UI
│   ├── main_demo_volunteer.dart
│   ├── main_signup.dart      # Demo entry point for sign-up UI
│   ├── firebase_options.dart # Firebase options for all platforms
│   ├── models/               # Data models
│   ├── screens/              # UI screens
│   ├── services/             # Firebase service classes
│   ├── theme/                # App theme
│   └── widgets/              # Reusable widgets
├── screenshots/              # UI screenshots for README
├── web/                      # Web support files
├── pubspec.yaml
└── README.md
```

## Setup

### 1. Prerequisites

- Flutter SDK installed and on your `PATH`
- A Firebase project

### 2. Firebase configuration

The app already contains the Firebase configuration for project `relief-dashboard`. You must still enable the following services in the Firebase Console:

1. **Authentication**
   - Go to **Build → Authentication → Sign-in method**.
   - Enable **Email/Password**.

2. **Cloud Firestore**
   - Go to **Build → Firestore Database**.
   - Click **Create database** and choose a region.
   - Set the security rules (see sample rules below).
   - Create the required indexes (see below).

3. **Cloud Storage**
   - Go to **Build → Storage**.
   - Click **Get started**.
   - Use the default bucket `relief-dashboard.firebasestorage.app`.
   - Set the storage rules (see sample rules below).

#### Sample Firestore security rules

```firestore-security-rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /warehouses/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /inventory/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /reliefRequests/{id} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

#### Required Firestore indexes

Create composite indexes in **Firestore Database → Indexes**:

Collection: `reliefRequests`

| Field 1 | Field 2 | Field 3 |
|---------|---------|---------|
| `submittedBy` | `submittedAt` | Descending |
| `status` | `submittedAt` | Descending |

Collection: `inventory`

| Field 1 | Field 2 |
|---------|---------|
| `category` | `name` |

#### Sample Cloud Storage rules

```storage-rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /request_images/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 3. Install dependencies

```bash
cd dashboard
flutter pub get
```

### 4. Run the app

```bash
flutter run -d chrome
```

For Android:

```bash
flutter run
```

## Seeding demo data

After signing in as `admin@relief.demo`, tap the **leaf icon** in the top-right app bar. This creates:

- A default warehouse: **Karachi Central Warehouse**
- Sample inventory items across Food, Water, Medicine, Shelter, and Clothing
- The two demo accounts listed above (if they do not already exist)

## Demo helper files

The following files are only for capturing UI screenshots when Firestore is disabled. Remove them before submitting or publishing:

- `lib/main_demo_admin.dart`
- `lib/main_demo_volunteer.dart`
- `lib/main_signup.dart`
- `lib/demo/demo_auth_service.dart`
- `lib/demo/demo_firestore_service.dart`

To run the real app, always use `lib/main.dart`.

## Running checks

```bash
flutter analyze
flutter test
```

## Troubleshooting

- **"User profile not found"** — Cloud Firestore is disabled or the `users` document does not exist. Enable Firestore and ensure the security rules allow reading the `users` collection.
- **Blank map tiles** — Verify the device or emulator has an internet connection. OpenStreetMap tiles are fetched online.
- **Photo upload fails on web** — The app uses `Image.network` and `putData` for web uploads; ensure Cloud Storage is enabled and CORS is configured for web access.

## License

This project is for educational/demonstration purposes.
