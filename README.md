# Indoor Navigation

A Flutter app for finding your way inside a venue (mall, campus, etc.) using
QR codes for location fixing, A* pathfinding for turn-by-turn routes, and an
AR compass overlay for on-the-ground guidance.

## How it works

1. **Scan a QR code** posted somewhere in the venue to tell the app where
   you're standing right now.
2. **Pick a destination** — a point of interest (store, gate, restroom, etc.).
3. The app runs **A\* pathfinding** over a graph of nodes/edges (per floor,
   with inter-floor connections for stairs/escalators/elevators) to compute
   the shortest route.
4. The route is shown on a **2D floor map** and as an **AR arrow overlay**
   through the camera, using the device compass heading to point the way.

## Project structure

```
app/            Flutter application (the indoor nav app itself — see app/README.md)
admin/          Browser-based map editor (admin/index.html, no build step) for
                drawing floors, nodes, edges, QR codes, and POIs over a floor-plan image
supabase/       Postgres schema + seed SQL for the multi-tenant backend
tool/           PowerShell script to regenerate supabase/seed.sql from mall_data.json
```

## Backend

Venue data (floors, nodes, edges, QR codes, POIs) is served from a
[Supabase](https://supabase.com) Postgres project via its auto-generated REST
API. Row Level Security is enabled with read-only policies for the public
`anon` key, so the app can only ever read venue data, never write it.

If no Supabase project is configured, the app automatically falls back to a
bundled demo venue (`app/assets/data/mall_data.json`) — useful for trying it
out or developing offline with zero setup.

## Getting started

See **[SETUP.md](SETUP.md)** for the full environment setup (Flutter SDK,
Android Studio, IDE plugins, Supabase project) and how to run the app.

Quick start once Flutter is installed:

```powershell
cd app
flutter pub get
flutter run
```

## Editing venue data

Use `admin/index.html` (just open it in a browser) to visually edit floors,
nodes, edges, QR codes, and POIs over a floor-plan image, with printable QR
code export. See [SETUP.md](SETUP.md#to-swap-in-a-real-mall) for how edits
make their way into Supabase.
