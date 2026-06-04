# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read this file completely before making any changes. Also read `DESIGN.md` before touching any UI file.

---

## Project Overview

CoolRoute is a heat-safe navigation and community reporting Flutter app targeting **Android** and **Flutter Web**. Helps users reduce heat exposure via cooler walking routes, community-reported hot zones, cool spot discovery, and NASA GIBS environmental data.

**Stage:** Fully wired production app — Firebase/Firestore, OpenRouteService, WeatherAPI, NASA GIBS, Google Maps, OpenStreetMap. Not a prototype.

---

## Commands

```powershell
flutter pub get          # install dependencies
flutter run -d chrome    # run on web (use -d edge if Chrome unavailable)
flutter run              # run on connected Android device/emulator
flutter analyze          # lint — must be clean before any commit
```

---

## Hard Platform Rules

- **Never use `dart:io`** — breaks on web. Use `dart:typed_data` or `kIsWeb` checks.
- **Never use `File` from `dart:io`** — use `Uint8List` or conditional imports.
- **Never use `path_provider`** for anything that runs on web.
- All packages must be web-safe — check pub.dev before adding any.
- Use `kIsWeb` from `flutter/foundation.dart` for platform branching.

---

## Architecture

### Boot sequence

```
main.dart
  → flutter_dotenv loads .env (graceful if missing)
  → Firebase.initializeApp() (firebaseReady flag on failure)
  → injects Google Maps JS script on web
  → runApp(CoolRouteApp(firebaseReady: ...))

CoolRouteApp (app.dart)
  → MaterialApp + AppTheme.light()
  → AuthGate(firebaseReady)

AuthGate (screens/auth/auth_gate.dart)
  → Firebase signed in? → AppShell + FirestoreSeedService.seedIfEmpty()
  → else → WelcomeScreen → LoginScreen

AppShell (screens/shell/app_shell.dart)
  → IndexedStack of 5 screens (keeps map camera alive)
  → mobile: bottom NavigationBar | web (>800px): top _WebNavBar
```

### 5-tab navigation

| Index | Tab | Screen file |
|---|---|---|
| 0 | Home | `screens/home/home_screen.dart` |
| 1 | Route | `screens/route/route_screen.dart` |
| 2 | Map | `screens/map/map_screen.dart` |
| 3 | Data | `screens/data/environmental_data_screen.dart` |
| 4 | Profile | `screens/profile/profile_screen.dart` |

Cool Spots is a **filter mode inside the Map tab**, not a separate tab. `cool_spots_screen.dart` is orphaned — do not wire it in.

### Service layer

All services follow a **real-or-dummy fallback** pattern: attempt the real call, catch errors, return sensible fallback so the app never crashes.

| Service | What it does |
|---|---|
| `WeatherService` | WeatherAPI.com — drives Home hero + Data panel |
| `PlacesService` | OSM Overpass API — real nearby cool spots |
| `NasaGibsService` | Builds WMTS tile URLs for `flutter_map` |
| `RoutingService` | OpenRouteService — geocoding (Pelias: venue/address/street) + walking directions |
| `RoutePlanner` | Scores `RawRoute` list by hot-zone proximity → `RouteOption` list |
| `ReportService` | Firestore `hotZones` — full CRUD: submit, read (with 48h expiry), verifyReport, resolveReport (3-vote takedown), updateReport, deleteReport, getUserHotZoneReports |
| `CoolSpotService` | Firestore `coolSpots` — submit (with 48h expiry on read), getUserCoolSpots, deleteCoolSpot |
| `TreeEventService` | Firestore `treeEvents` — createEvent, contribute (RSVP/water/donate/attend), getUserTreeEvents, deleteTreeEvent |
| `UserProfileService` | Firestore `users/{uid}` — profile CRUD, saved routes, stat counters |
| `FirebaseAuthService` | Email-password / Google / anonymous sign-in |
| `FirestoreSeedService` | Seeds initial hot zones + cool spots on first login (only if collections are empty) |
| `LocationService` | `geolocator` — real device/browser location; skips `isLocationServiceEnabled()` on web (unreliable); falls back to Bangkok center with `isReal: false` flag |

### Live data requirements (`.env` in project root)

```
GOOGLE_MAPS_API_KEY=...   # web + Android
WEATHER_API_KEY=...       # WeatherAPI.com
ORS_API_KEY=...           # OpenRouteService (routing + geocoding)
```

`.env` is bundled as a Flutter asset loaded by `flutter_dotenv`. Keys are optional — every service degrades gracefully without them.

### Firestore collections & rules

| Collection | Notes |
|---|---|
| `hotZones` | world-read; authed create; updates: verifications/verifiedBy/resolvedBy fields OR owner edits title/description/category; delete: owner OR resolvedBy.size() >= 3 |
| `coolSpots` | world-read; authed create; updates: verifiedBy; delete: owner |
| `treeEvents` | world-read; authed create; updates: rsvpBy/waterBy/donateBy/attendBy; delete: owner |
| `users/{uid}` | owner read/write only |

Rules file: `backend/firestore.rules`. Deploy with:
```
firebase deploy --only firestore:rules --config backend/firebase.json
```

### Delete / expiry architecture

Three delete paths for `hotZones`:
1. **48-hour auto-expiry** — `getHotZoneReports()` checks `createdAt`; expired docs are deleted fire-and-forget by the reading client and excluded from results.
2. **Community takedown** — `resolveReport()` transaction adds uid to `resolvedBy`; when `resolvedBy.length >= 3` the doc is deleted and the map removes the pin immediately.
3. **Owner delete** — `deleteReport(id)` called from Profile → My Contributions (with confirmation dialog).

Same 48-hour expiry applies to `coolSpots` (community-submitted only; OSM spots have no `createdAt`).

### Cross-screen refresh signals

Global `ValueNotifier<int>` instances in `lib/services/report_refresh.dart`. Services call the helper functions; screens listen via `addListener` / `ValueListenableBuilder`.

| Notifier | Helper | Trigger |
|---|---|---|
| `hotZoneRevision` | `notifyHotZonesChanged()` | new report, verification, or delete |
| `coolSpotRevision` | `notifyCoolSpotsChanged()` | new cool-spot suggestion |
| `treeEventRevision` | `notifyTreeEventsChanged()` | new tree event or contribution |
| `profileRevision` | `notifyProfileChanged()` | save/remove route, report, verify |

Never set `.value` directly — always call the helper.

### Custom map markers

`lib/widgets/map_marker_icons.dart` — `MapMarkerIcons.build(color, icon)` renders a teardrop pin bitmap async using `dart:ui` `PictureRecorder` + `TextPainter` at 3× pixel density. Returns a `BitmapDescriptor` for use with `google_maps_flutter`.

`_GoogleMapViewState` in `coolroute_map.dart` caches 7 variants in `initState` (hot-extreme, hot-medium, hot-low, cool-water, cool-shade, cool-ac, tree). Falls back to `defaultMarkerWithHue` while loading.

### Map screen architecture

Selected-marker state is held **at `MapScreen` level** (not inside the map widget) so both the bottom sheet (mobile) and side panel (web) can read it. Use `PointerInterceptor` around all floating UI overlaid on the Google Map to prevent mouse event bleed-through.

### Route screen architecture

`RouteScreen` → `RoutingService.geocode()` for destination search (returns venues/addresses/streets/localities), `RoutingService.walkingRoutes()` for raw paths, `RoutePlanner.score()` for heat-ranked `RouteOption` list. The map portion is `RouteMap` widget (`widgets/route_map.dart`). All floating panels wrapped in `PointerInterceptor`.

### Timestamps

`HotZoneReport.displayTimeAgo` — computed getter that derives a relative label from `createdAt` ("just now" / "N min ago" / "N hrs ago" / "yesterday" / "N days ago" / "Jan 5"). Falls back to the stored `timeAgo` string for legacy docs. Always use `displayTimeAgo` in the UI, never the raw `timeAgo` field.

---

## Layout Breakpoints

| Width | Mode |
|---|---|
| < 600px | Mobile: bottom nav, single column, bottom sheets |
| 600–800px | Tablet: bottom nav, wider cards |
| > 800px | Web: top nav bar, side panels, max-width 900px containers |

Web-specific:
- Route: left panel (~380px form + route cards) + right map fill
- Map: full-bleed map + right side panel (320px) instead of bottom sheet
- Data: left layer sidebar (280px) + right viz panel

Never use `showModalBottomSheet` for the map panel — use a custom positioned overlay so it coexists with the map.

---

## State Management

`StatefulWidget` + `setState` throughout. Do not introduce a new state management library.

---

## Design System

All colors → `AppTheme` static constants in `lib/theme/app_theme.dart`.  
All text styles → `Theme.of(context).textTheme` (never inline `TextStyle`).  
Max font weight: **500**.  
Spacing constants: `AppTheme.spaceXS/SM/MD/LG/XL` (4/8/16/24/32px).  
No Material elevation shadows on cards — use `borderLight` border instead.  
Environmental Data screen is **dark-themed throughout** (`bgDark` scaffold) — no white sections.

Full token list and component specs are in `DESIGN.md`.

---

## Fallback map

When `GOOGLE_MAPS_API_KEY` is missing or map init fails, `CoolRouteMap` shows `_PlaceholderMapView` — a custom-painted canvas with styled roads, buildings, and `_Marker` widgets. Never crash or show blank screen.

---

## What Not To Do

- Do not use `dart:io`.
- Do not put the bottom nav inside the map's `Scaffold` — it belongs in `AppShell`.
- Do not put business logic inside screen files — services only.
- Do not use `showModalBottomSheet` for the map side panel.
- Do not set refresh notifier `.value` directly — use the helper functions.
- Do not use `report.timeAgo` in the UI — use `report.displayTimeAgo`.

---

## Conflict Resolution

1. User's latest instruction takes priority.
2. `DESIGN.md` controls all visual decisions.
3. This file controls architecture and structure.
4. Do not break existing working screens while changing another.
