# UniPlan

UniPlan is a **university timetable scheduling** mobile app built with **Flutter**. It gives **students** and **admins** role-based access: students view schedules and announcements, admins manage slots with validation, and everyone gets a modern Material 3 UI with optional dark mode.

## Features

- **Authentication** — Email/password via Firebase Auth; routing by role (`student`,  `admin`).
- **Student** — Today’s classes, semester/division timetable, **PDF export & share** for the weekly grid, **notifications** panel (pin / delete per user, badge count), profile, **offline-friendly** cache with connectivity banner.
- **Admin** — Timetable CRUD, **conflict checks** (teacher, room, same class at same time), **weekly subject limits** (e.g. lectures + lab), **rooms from Firebase**, suggested **free time slots** and **available rooms**, broadcast announcements (stored for the notifications panel).
- **Theming** — Light/dark mode (persisted with `shared_preferences`).

## Tech Stack

| Area | Technology |
|------|------------|
| UI | Flutter (Dart), Material 3, `provider` |
| Backend | Firebase Auth, Firebase Realtime Database |
| Messaging | Firebase Cloud Messaging + `flutter_local_notifications` |
| Local | `sqflite` cache, `connectivity_plus` |
| PDF | `pdf`, `printing` |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; Dart SDK compatible with `pubspec.yaml`)
- [Android Studio](https://developer.android.com/studio) or VS Code / Cursor with Flutter extensions
- A **Firebase** project with **Authentication** (Email/Password), **Realtime Database**, and **Cloud Messaging** enabled (Android app registered)

## Project Setup

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd uniplan
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase — Android**

   - Place your Firebase Android config in **`android/app/google-services.json`** (download from Firebase Console for your app).
   - This project initializes Firebase using **`lib/firebase_options.dart`**. If you use a **new** Firebase project, update `DefaultFirebaseOptions.android` in that file to match the values from your `google-services.json` (or regenerate via `flutterfire configure` and adjust `main.dart` if you switch to the generated options).

4. **Realtime Database structure (high level)**

   Typical nodes used by the app include: `timetables`, `semesters`, `divisions`, `subjects`, `teachers`, `rooms`, `users`, `announcements`, `userAnnouncements`. Configure **security rules** in the Firebase Console so only authorized roles can read/write admin data; test rules with the Emulator or Rules Playground before production.

5. **Run the app**

   ```bash
   flutter run
   ```

   Use a physical device or emulator with Google Play services where needed for FCM.



## Useful Commands

| Command | Purpose |
|---------|---------|
| `flutter analyze` | Static analysis (may report info-level lints) |
| `flutter test` | Run unit/widget tests |
| `flutter build apk` | Release APK build |

