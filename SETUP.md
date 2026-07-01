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

### 4. Supabase project (free, no credit card needed)
1. Go to https://supabase.com → sign up (email, no card required) → New Project
2. Pick any name/region and set a database password (save it somewhere — you likely won't need it again, but the SQL Editor login won't ask for it)
3. Once the project is ready: open the **SQL Editor** (left sidebar) → New query
   - Paste the contents of `supabase/schema.sql` → Run
   - Paste the contents of `supabase/seed.sql` → Run
   - (Editing `app/assets/data/mall_data.json` and want to regenerate seed data? Run `powershell -File tool/generate_seed.ps1`, then re-run the new `supabase/seed.sql` in the SQL Editor.)
4. Go to **Project Settings → API** → copy the **Project URL** and the **anon public** key
5. Open `app/lib/config/supabase_config.dart` (create it by copying `supabase_config.example.dart` if it doesn't exist) and paste both values in

Stay on the free tier — don't add a payment method. See project memory for why this is safe (no card on file = cannot be charged).

Skipping this for now? The app runs fine without it — `app/lib/config/supabase_config.dart` still has placeholder
values, so `DataService` automatically falls back to the bundled `assets/data/mall_data.json` demo venue instead of
trying to reach a real backend. Once you fill in real values, it switches to Supabase automatically.

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

Venue data now lives in Supabase, not the bundled JSON — `assets/data/mall_data.json` is kept only as the source
for `tool/generate_seed.ps1` (handy for editing venue layouts locally and re-seeding).

To add or update a venue:
1. Edit `assets/data/mall_data.json` (or write new SQL by hand against `supabase/schema.sql`) — same schema, real coordinates
2. Regenerate: `powershell -File tool/generate_seed.ps1`
3. Run the resulting `supabase/seed.sql` in the Supabase SQL Editor
4. Point the app at it by changing `_venueId` in `app/lib/main.dart`

The navigation, AR, and map screens require zero code changes — only the data changes.

For a visual editor instead of hand-editing JSON/SQL, use `admin/index.html` (open directly in any browser,
no build needed) — it already supports a real floor-plan image background and printable QR code export.
