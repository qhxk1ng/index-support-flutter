# Local Development Guide

## Overview

This guide explains how to run the Flutter app against your **local backend** without modifying any source files.

---

## Prerequisites

- Flutter SDK installed
- Android emulator or physical device connected
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

### Android Emulator
```powershell
flutter run --dart-define=BASE_URL=http://10.0.2.2:5000
```
> Android emulator uses `10.0.2.2` to reach your PC's `localhost`.

### Chrome / Web
```powershell
flutter run -d chrome --dart-define=BASE_URL=http://localhost:5000
```

### Windows Desktop
```powershell
flutter run -d windows --dart-define=BASE_URL=http://localhost:5000
```

### Physical Android Device (on same Wi-Fi)
```powershell
# Replace 192.168.x.x with your PC's local IP (run ipconfig to find it)
flutter run --dart-define=BASE_URL=http://192.168.x.x:5000
```

---

## Step 3 — Test Two Roles Simultaneously

Open **two separate terminals** and run:

**Terminal 1 — Admin (Chrome):**
```powershell
flutter run -d chrome --dart-define=BASE_URL=http://localhost:5000
```

**Terminal 2 — Technician (Android Emulator):**
```powershell
flutter run -d emulator-5554 --dart-define=BASE_URL=http://10.0.2.2:5000
```

Check available device IDs with:
```powershell
flutter devices
```

---

## Step 4 — Test API Endpoints Directly (Postman / PowerShell)

### Get auth token
```powershell
$response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/admin-login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"your@email.com","password":"yourpassword"}'
$token = $response.data.token
```

### Test any endpoint
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/admin/live-tracking" `
  -Headers @{Authorization="Bearer $token"}

Invoke-RestMethod -Uri "http://localhost:5000/api/admin/staff/STAFF_ID/route?startDate=2026-04-04&endDate=2026-04-04" `
  -Headers @{Authorization="Bearer $token"}
```

---

## Building for Production

When building the release APK, **do not pass `--dart-define=BASE_URL`** — it will automatically use the production URL `https://api.indexinformatics.in`.

```powershell
flutter build apk --release
```

Or with only the Mapbox token (production default URL):
```powershell
flutter build apk --release --dart-define=MAPBOX_PUBLIC_TOKEN=your_mapbox_public_token_here
```

---

## Environment Summary

| Environment | BASE_URL dart-define | Flutter command |
|-------------|----------------------|-----------------|
| Production (default) | *(not needed)* | `flutter run` |
| Local — Android emulator | `http://10.0.2.2:5000` | `flutter run --dart-define=BASE_URL=http://10.0.2.2:5000` |
| Local — Chrome/Windows | `http://localhost:5000` | `flutter run -d chrome --dart-define=BASE_URL=http://localhost:5000` |
| Local — Physical device | `http://192.168.x.x:5000` | `flutter run --dart-define=BASE_URL=http://192.168.x.x:5000` |

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
