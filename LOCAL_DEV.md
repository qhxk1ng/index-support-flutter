# Local Development Guide

## Overview

This guide explains how to run the Flutter app against your **local backend** without modifying any source files.

---

## Prerequisites

- Flutter SDK installed
- iOS Simulator or physical iOS device connected
- Local backend running (see below)

---

## Step 1 — Start the Backend Locally

Open a terminal in the backend folder and run:

```powershell
cd "d:\Index App and Webiste Development\Service App and Web\index-support-backend"
npm run dev
```

You should see:
```
🚀 Server running on port 5000
📍 Environment: development
```

> The backend uses `nodemon` — it auto-restarts whenever you save a `.ts` file.

---

## Step 2 — Run Flutter Against Local Backend

**No code changes needed.** Use `--dart-define=BASE_URL` to override the server URL at run time.

### iOS Simulator
```bash
flutter run --dart-define=BASE_URL=http://localhost:5000
```
> iOS Simulator shares localhost with your Mac directly, so `http://localhost:5000` connects straight to your local backend.

### Physical iOS Device (on same Wi-Fi)
```bash
# Replace 192.168.x.x with your Mac's local IP
flutter run --dart-define=BASE_URL=http://192.168.x.x:5000
```

### Xcode Direct Running
Open `ios/Runner.xcworkspace` in Xcode, select your target Simulator or Device, and click the **Run (Play)** button.

---

## Step 3 — Test Two Roles Simultaneously

Open **two separate terminals** and run:

**Terminal 1 — Admin (Simulator):**
```bash
flutter run -d "iPhone 15 Pro" --dart-define=BASE_URL=http://localhost:5000
```

**Terminal 2 — Technician (Simulator):**
```bash
flutter run -d "iPhone 15" --dart-define=BASE_URL=http://localhost:5000
```

Check available device IDs with:
```bash
flutter devices
```

---

## Step 4 — Test API Endpoints Directly (curl)

### Get auth token
```bash
curl -X POST http://localhost:5000/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpassword"}'
```

---

## Building for Production / Release

When building for iOS:

```bash
flutter build ipa --release
```

Or run directly from Xcode using **Runner.xcworkspace** with the Release scheme.

---

## Environment Summary

| Environment | BASE_URL dart-define | Flutter command |
|-------------|----------------------|-----------------|
| Production (default) | *(not needed)* | `flutter run` |
| Local — iOS Simulator | `http://localhost:5000` | `flutter run --dart-define=BASE_URL=http://localhost:5000` |
| Local — Physical iOS device | `http://192.168.x.x:5000` | `flutter run --dart-define=BASE_URL=http://192.168.x.x:5000` |

---

## What Was Changed in the Codebase

Only one file was modified to enable this:

**`lib/core/config/app_config.dart`**
```dart
// Before:
static const String baseUrl = 'https://api.indexinformatics.in';

// After:
static const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://api.indexinformatics.in',
);
```

This means:
- If no `--dart-define=BASE_URL` is passed → uses production URL (safe default)
- If `--dart-define=BASE_URL=http://10.0.2.2:5000` is passed → uses local backend
- **No code file needs to be edited** to switch environments
