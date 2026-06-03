# CoolRoute — Implementation Status vs. Spec

> Audit of the current codebase against `CoolRoute_Concepts_Functions_Implementation2.0.pdf`
> (Group 10, Integrated Project 2). Last reviewed: **2026-06-03**.
>
> This is a living reference. Update the status tags as features land.

## ✅ Live data is now configured & verified (2026-06-03)

The "real data" features are no longer just *coded* — they're **running on live data**:
- **Weather** — `WEATHER_API_KEY` set in `.env`; WeatherAPI.com returns live conditions. ✅
- **Google Maps** — `GOOGLE_MAPS_API_KEY` set in `.env` (one key serves web + Android); live map renders. ✅
- **NASA GIBS** — live satellite imagery (keyless). ✅
- **OSM Cool Spots** — live OpenStreetMap data (keyless). ✅
- **Firebase Auth** — Anonymous provider enabled in console (`first-project-e258e`); guest sign-in works. ✅

Keys live in `.env` (gitignored — never committed). Firebase provider toggles are console-side.
**Next work is wiring the community/data-write half (see roadmap P0 below).**

**Legend:** ✅ Done · 🟡 Partial (UI exists, not wired / no persistence) · 🟠 Minimal (stub) · ❌ Missing

---

## TL;DR — where we are

The app is a **well-built UI prototype with a few features fully wired to real data**, but
the community/data-write half is mostly mock. Concretely:

- **Genuinely working with real data:** Cool Spot Finder (OpenStreetMap), Weather (WeatherAPI),
  NASA GIBS viewer, Auth (email/Google/guest code paths), Home dashboard, the map itself.
- **UI only, not connected:** Heat-safe routing, Hot Zone report **persistence**, Community
  verification.
- **Not implemented:** Tree-planting **events** (RSVP/water/donate), NDVI vegetation overlay,
  a "Reports" tab, real Profile / Saved Routes.
- **Dead/orphaned code:** `ReportService`, `CoolSpotService`, `UserProfileService`,
  `ProfileScreen`, `CoolSpotsScreen` — all defined but never called from the live UI.

The single biggest gap between code and spec: **Firestore is configured and even seeded on
login, but the UI reads/writes go to hardcoded `DummyData` instead of the services.** Reports
never reach the database.

---

## Spec §1 — Core Concepts

| Concept | Status | Notes |
|---|---|---|
| Heat-safe routing | 🟡 | `route_screen.dart` shows 3 dummy routes from `DummyData.routes`. Start/Destination fields and "Find safer route" button are **no-ops** (`onPressed: () {}`). `RouteService` just returns dummy. No routing engine, no heat scoring. |
| Community hot zone reports | 🟡 | Full report UI in two places, but **nothing persists**. `ReportSpotSheet` (Map) only drops a local "pending" pin via a callback. `CreateHotZoneReportScreen` (Home) just shows a snackbar. `ReportService.submitHotZoneReport()` exists but is **never called**. |
| Cool spot finder | ✅ | **Best-implemented feature.** `PlacesService` queries the OSM Overpass API for real nearby libraries, malls, water points, parks, cafés, etc. — real lat/lng, real distances, category buckets. Falls back to dummy on failure. Filters + live search work. |
| Weather integration | ✅ | `WeatherService` → WeatherAPI.com (`current.json`), parses temp/feels-like/humidity/UV. Falls back to dummy Bangkok weather when no key. Drives Home hero + Data info panel. |
| NASA GIBS viewer | ✅ | `NasaGibsService` builds Worldview Snapshot image URLs; `environmental_data_screen.dart` renders them in a pan/zoom `InteractiveViewer` with date presets + custom date picker + 6 layers. |
| Community tree-planting | 🟠 | Only **static viewing** of dummy tree pins on the Map (Trees 🌱 filter) + a detail sheet. No event creation, no RSVP/water/donate/attend, no NDVI overlay. |

---

## Spec §2 — Main Features and Modules

| Feature / Module | Status | Notes |
|---|---|---|
| Login and Sign-up | ✅ (code) | `FirebaseAuthService` + `login_screen.dart` implement email/password, Google (native `GoogleAuthProvider` — popup on web, provider flow on mobile, **no `google_sign_in` package needed**), and anonymous/guest. **Requires Firebase console config** (providers enabled) to actually authenticate. "profile, role, preferences, saved data" → not real (see Profile row). |
| Home Dashboard | ✅ | Weather hero (temp, feels-like, humidity, UV, "Extreme risk" badge), 4 quick actions (Route, Report Hot Zone, Find Cool Spot, Plant a Tree), recent-alert chips. Responsive 2-col / 4-col. |
| Heat-Safe Route Suggestion | 🟡 | See "Heat-safe routing" above. Inputs non-functional; no real start/destination handling. |
| Hot Zone Report | 🟡 | UI complete + validation; **no DB write**. Spec also wants tree-planting as a *separate report type from a Reports tab* → the report chooser only offers **Hot Zone / Cool Spot**, and **there is no Reports tab**. |
| Community Verification | 🟡 | "Still hot" / "Problem fixed" buttons exist in `hot_zone_bottom_sheet.dart` but are **no-ops**. `ReportService.verifyReport()` exists but is **never called**. No "shade available / water working / not accurate" options. |
| Cool Spot Finder | ✅ | Real data + filters (Water / Shade / Air-conditioned / Open Now) on the Map. "Verified" filter exists on the (orphaned) standalone screen. |
| NASA Environmental Data Viewer | 🟡 | 6 layers wired (Land Surface Temp, Sea Surface Temp, Cloud Cover, Aerosol/Air Quality, UV/Ozone, Weather Heat Index). **Missing the NDVI / vegetation layer** the spec calls out as candidate-planting-zone highlighting. |
| Profile and Saved Routes | 🟡 | `profile_screen.dart` is fully built **but orphaned** — no navigation entry reaches it (nav is Home/Route/Map/Data only). All content hardcoded ("Nicha", fake saved routes). `UserProfileService` unused. |
| Tree-Planting Events | ❌ | Not implemented beyond static pin viewing. No event model with RSVP/watering/donation/attendance, no creation flow. |

---

## Architecture as built (what actually runs)

```
main.dart
  → load .env (optional) → init Firebase (optional) → load web Maps JS → runApp
app.dart  → MaterialApp + AuthGate
AuthGate  → signed in ? AppShell + seed Firestore once : WelcomeScreen → LoginScreen
AppShell  → 4 tabs (IndexedStack): Home · Route · Map · Data
            (bottom nav < 800px, top nav bar ≥ 800px)
```

**Service layer pattern (real-or-dummy fallback):**
- ✅ Used live: `WeatherService`, `PlacesService`, `NasaGibsService`, `LocationService`,
  `EnvironmentalDataService`, `FirebaseAuthService`, `FirestoreSeedService`.
- ❌ Defined but **never called**: `ReportService`, `CoolSpotService`, `UserProfileService`.

**Firestore** (`backend/firestore.rules`): `hotZones` + `coolSpots` are world-readable,
create requires auth, updates limited to `verifications` / `verifiedBy`, no deletes;
`users/{uid}` is owner-only. Seeded on first login via `FirestoreSeedService` — **but the UI
never reads from these collections**, so seeded data is invisible.

---

## Orphaned / dead code to reconcile

These exist but are unreachable or unused. Either wire them up or delete them:
- `lib/screens/profile/profile_screen.dart` — no nav entry.
- `lib/screens/cool_spots/cool_spots_screen.dart` — superseded by the Map "Cool Spots" mode.
- `lib/services/report_service.dart`, `cool_spot_service.dart`, `user_profile_service.dart`.
- Verify buttons + `CreateHotZoneReportScreen` submit are wired to the UI but not to data.

---

## Prioritized roadmap to conform to the spec

Ordered by impact-to-spec vs. effort. Follow the existing **service + real-or-dummy fallback**
pattern; keep everything **web-safe** (no `dart:io`).

### P0 — close the "looks done but isn't" gaps
1. **Persist hot-zone reports.** Wire `ReportSpotSheet._submit()` and
   `CreateHotZoneReportScreen._submit()` to `ReportService.submitHotZoneReport()` (pass the
   current `userId`). Keep the optimistic local pin.
2. **Read reports from Firestore.** Replace `DummyData.hotZones` usage in `map_screen.dart` /
   `home_screen.dart` with `ReportService.getHotZoneReports()` (already has dummy fallback).
3. **Wire community verification.** Make "Still hot" / "Problem fixed" call
   `ReportService.verifyReport(id)`; add the spec's other verification options.

### P1 — the headline feature
4. **Real heat-safe routing.** Replace the dummy route list + dead form with a routing API
   (Google Directions, or keyless OpenRouteService). Score each route by heat exposure using
   hot-zone density + weather + (optionally) NASA layers. This is the app's core promise and is
   currently a mockup.

### P2 — community + climate depth
5. **Tree-Planting Events.** Add an event model (location, date, RSVPs, waterings, donations),
   a creation flow, and contribution actions. Decide: a dedicated **Reports tab** (matches spec)
   vs. extending the current report chooser.
6. **NDVI vegetation layer.** Add an NDVI GIBS layer to `DummyData.layers` and surface
   low-vegetation areas as candidate planting zones (ties into #5).
7. **Real Profile + Saved Routes.** Make `ProfileScreen` reachable (add nav/menu entry), back it
   with `UserProfileService` + Firestore `users/{uid}`, and persist saved routes / preferences.

### P3 — config / housekeeping
8. ✅ **DONE** — Real API keys added to `.env` (`GOOGLE_MAPS_API_KEY`, `WEATHER_API_KEY`) and
   Firebase Anonymous auth enabled. Still TODO: enable **Email/Password** + **Google** providers,
   confirm Firestore database is created, and deploy `backend/firestore.rules`.
9. Delete or integrate the orphaned screens/services listed above.

---

## How to run (local)

```powershell
cd CoolRoute
flutter pub get
flutter run -d chrome      # web
# or: flutter run           # Android device/emulator
```
With an empty `.env`, the app runs on built-in fallbacks (painted map + dummy weather). Firebase
falls back to the dummy-data prototype path if not configured. `flutter analyze` is currently clean.
