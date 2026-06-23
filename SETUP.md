# Indoor Navigation — Setup Guide

## What you need to install

### 1. Flutter SDK
1. Go to https://docs.flutter.dev/get-started/install/windows
2. Download the Flutter SDK zip and extract to `C:\flutter`
3. Add `C:\flutter\bin` to your Windows PATH:
   - Start → "Edit the system environment variables" → Environment Variables → PATH → New → `C:\flutter\bin`
4. Open a new PowerShell and run: `flutter doctor`

### 2. Android Studio (provides the Android SDK + emulator)
1. Download from https://developer.android.com/studio
2. During install, include "Android SDK", "Android SDK Platform", and "Android Virtual Device"
3. After install, open Android Studio → More Actions → SDK Manager → install Android 13 (API 33) or newer

### 3. Flutter & Dart plugins for IntelliJ IDEA (you already have it)
1. Open IntelliJ IDEA → File → Settings → Plugins → Marketplace
2. Search "Flutter" → Install (installs Dart automatically)
3. Restart IntelliJ

---

## Running the app

```powershell
# From the Navigation directory:
cd app
flutter pub get          # downloads all dependencies
flutter run              # launches on connected device or emulator
```

To open the project in IntelliJ: File → Open → select the `app/` folder.

---

## Project structure

```
app/
├── lib/
│   ├── models/          # Data structures (nodes, edges, POIs, floors)
│   ├── services/        # A* pathfinding, data loading
│   ├── state/           # AppState (Provider) — all navigation logic here
│   ├── screens/         # HomeScreen, MapScreen, ARScreen, QRScanScreen
│   └── widgets/         # FloorMapPainter, AROverlayWidget
└── assets/data/
    └── mall_data.json   # THE MALL — replace this file to change venue
```

## How QR codes work (for testing without printing physical codes)

In the app, tap the QR scanner icon. Any QR code encoding one of these strings will work:

| QR Content  | Location              |
|-------------|-----------------------|
| QR_G_01     | Ground — North Entrance |
| QR_G_02     | Ground — West Wing    |
| QR_G_03     | Ground — Center / Escalators |
| QR_G_04     | Ground — Food Court   |
| QR_G_05     | Ground — South Entrance |
| QR_U_01     | Upper — Cinema        |
| QR_U_02     | Upper — Center        |
| QR_U_03     | Upper — Near Zara     |
| QR_U_04     | Upper — Kids Zone     |
| QR_U_05     | Upper — Near Apple Store |

Generate test QR codes at https://qr.io or https://www.qr-code-generator.com

## To swap in a real mall

Edit `assets/data/mall_data.json` — same schema, real coordinates.
The navigation, AR, and map screens require zero code changes.
