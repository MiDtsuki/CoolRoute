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

## ✅ Checklist (tick as features land)

**Core data integrations**
- [x] Weather (WeatherAPI) — live
- [x] Google Maps — live (one `.env` key serves web + Android)
- [x] NASA GIBS environmental viewer — live (keyless)
- [x] OSM cool-spot finder — live (keyless)
- [x] Firebase **Anonymous** auth — enabled + verified
- [ ] Firebase **Email/Password** + **Google** providers — enable in console
- [ ] Confirm Firestore database created + `backend/firestore.rules` deployed

**Screens / navigation**
- [x] Home dashboard
- [x] Map (hot zones · cool spots · trees)
- [x] Environmental data (NASA)
- [x] Profile tab — Firestore-backed (edit + sign out)
- [ ] Route screen — currently UI-only mockup

**P0 — community / data-write** ✅ DONE
- [x] Persist hot-zone reports to Firestore (`ReportService.submitHotZoneReport`)
- [x] Read hot zones from Firestore (Map + Home, replacing `DummyData.hotZones`)
- [x] Wire community verification ("Still hot" / "Problem fixed" → `verifyReport`)
- [x] Increment profile stat counters on report / verify (refresh on Profile to see)
- [x] One verification per user per report (transaction + `verifiedBy`; needs rules deploy)
- [x] New reports appear live on Map + Home without restart (refresh signal)
- [x] Persist cool-spot suggestions to Firestore (`CoolSpotService.submitCoolSpot`) + show on map
- [ ] *(follow-up)* richer verification options (shade available / water working / not accurate);
  time-based re-verification; verify community cool spots

**P1 — headline feature** ✅ DONE
- [x] Real walking routes (OpenRouteService) with geocoding search + tap-to-pick destination
- [x] Heat scoring: routes scored by proximity to reported hot zones; coolest = "Recommended"
- [x] Route drawn as a polyline on the map with start/destination + hot-zone markers
- [ ] *(follow-up)* factor cool spots / shade into scoring; turn-by-turn steps; save a planned route

**P2 — community + climate depth**
- [ ] Tree-planting events (create · RSVP · water · donate)
- [ ] NDVI vegetation layer in the Data viewer
- [x] Profile + saved-routes screen (core)
- [ ] Persist saved routes from the Route tab (`addSavedRoute`)

**P3 — housekeeping**
- [x] API keys in `.env`, Anonymous auth enabled
- [ ] Remove/integrate orphaned `cool_spots_screen`, `report_service`, `cool_spot_service`

---

## TL;DR — where we are

The app is a **well-built UI prototype with a few features fully wired to real data**, but
the community/data-write half is mostly mock. Concretely:

- **Genuinely working with real data:** Cool Spot Finder (OpenStreetMap), Weather (WeatherAPI),
  NASA GIBS viewer, Auth (email/Google/guest), Home dashboard, the map, the **Profile tab**, and
  the **community hot-zone loop** (report → persist → appears on map → verify → profile stats).
- **Not implemented:** Tree-planting **events** (RSVP/water/donate), NDVI vegetation overlay,
  a "Reports" tab, persisted saved routes.
- **Dead/orphaned code:** `CoolSpotsScreen` — superseded by the Map's Cool Spots mode.

With P0 and P1 done, the core loops are real: the community loop (report → persist → map →
verify → profile) and heat-safe routing (real walking routes scored by hot-zone exposure).
Remaining gaps are mostly P2: tree-planting events, an NDVI layer, and persisted saved routes.

---

## Spec §1 — Core Concepts

| Concept | Status | Notes |
|---|---|---|
| Heat-safe routing | ✅ | Real walking routes via **OpenRouteService** (`RoutingService`): start = current location, destination by geocoding search or map tap. `RoutePlanner` scores each route by proximity to reported hot zones and flags the coolest "Recommended"; routes draw as polylines (`route_map.dart`). Needs `ORS_API_KEY` in `.env`. *Follow-up:* fold cool spots/shade into scoring + turn-by-turn. |
| Community hot zone reports | ✅ | Reports now **persist to Firestore**. `ReportSpotSheet` (Map) drops an optimistic pin then writes via `ReportService.submitHotZoneReport()`; `CreateHotZoneReportScreen` (Home, now with field controllers) writes too. Map + Home **read** reports via `getHotZoneReports()`. Both bump the author's `reportCount`. |
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
| Heat-Safe Route Suggestion | ✅ | See "Heat-safe routing" above — real start/destination, real walking routes, heat-scored options drawn on the map. |
| Hot Zone Report | ✅ | Persists to Firestore (see §1 row). Spec's tree-planting-as-report-type + dedicated Reports tab still pending (P2). Cool-spot suggestions still local-only (P0 follow-up). |
| Community Verification | ✅ (core) | "Still hot" / "Problem fixed" now call `ReportService.verifyReport(id)` (optimistic count bump + persist) and credit the verifier's `verifiedReportCount`. Follow-up: per-user "already verified" guard and the richer option set (shade available / water working / not accurate). |
| Cool Spot Finder | ✅ | Real data + filters (Water / Shade / Air-conditioned / Open Now) on the Map. "Verified" filter exists on the (orphaned) standalone screen. |
| NASA Environmental Data Viewer | 🟡 | 6 layers wired (Land Surface Temp, Sea Surface Temp, Cloud Cover, Aerosol/Air Quality, UV/Ozone, Weather Heat Index). **Missing the NDVI / vegetation layer** the spec calls out as candidate-planting-zone highlighting. |
| Profile and Saved Routes | ✅ (core) | **Profile is now a live 5th tab.** `profile_screen.dart` loads the signed-in user's profile via `UserProfileService.getCurrentUserProfile()` (Firestore `users/{uid}`, auto-created on first load), shows contribution stats (reports / verifications / saved routes) + account type (guest vs email), and supports **editing** name/role/home-area/heat-sensitivity (persists via `updateProfile`) and **sign out** (mobile had none before). Falls back to dummy if Firebase is down. *Still TODO: stats counters (`reportCount`/`verifiedReportCount`) aren't incremented yet because reports/verification don't persist (P0); saved routes aren't written yet (needs `addSavedRoute` wired from the Route tab).* |
| Tree-Planting Events | ❌ | Not implemented beyond static pin viewing. No event model with RSVP/watering/donation/attendance, no creation flow. |

---

## Architecture as built (what actually runs)

```
main.dart
  → load .env (optional) → init Firebase (optional) → load web Maps JS → runApp
app.dart  → MaterialApp + AuthGate
AuthGate  → signed in ? AppShell + seed Firestore once : WelcomeScreen → LoginScreen
AppShell  → 5 tabs (IndexedStack): Home · Route · Map · Data · Profile
            (bottom nav < 800px, top nav bar ≥ 800px)
```

**Service layer pattern (real-or-dummy fallback):**
- ✅ Used live: `WeatherService`, `PlacesService`, `NasaGibsService`, `LocationService`,
  `EnvironmentalDataService`, `FirebaseAuthService`, `FirestoreSeedService`, `UserProfileService`,
  `ReportService`, `CoolSpotService`.
- All services are now wired into the live UI.

**Firestore** (`backend/firestore.rules`): `hotZones` + `coolSpots` are world-readable,
create requires auth, updates limited to `verifications` / `verifiedBy`, no deletes;
`users/{uid}` is owner-only. Seeded on first login via `FirestoreSeedService`. The Map + Home
**read `hotZones`** (and write new reports + verifications); the map merges **community-suggested
`coolSpots`** (with real coordinates) alongside the live OSM cool-spot results.

---

## Orphaned / dead code to reconcile

These exist but are unreachable or unused. Either wire them up or delete them:
- ~~`lib/screens/profile/profile_screen.dart`~~ — ✅ now a live 5th tab.
- ~~`user_profile_service.dart`~~ — ✅ now used by the Profile tab (+ new `updateProfile`).
- `lib/screens/cool_spots/cool_spots_screen.dart` — superseded by the Map "Cool Spots" mode.
- ~~`report_service.dart`~~ — ✅ now used (submit / read / verify).
- ~~Verify buttons + `CreateHotZoneReportScreen` submit~~ — ✅ now wired to Firestore.
- ~~`cool_spot_service.dart`~~ — ✅ now used (suggestions persist + show on the map).

---

## Prioritized roadmap to conform to the spec

Ordered by impact-to-spec vs. effort. Follow the existing **service + real-or-dummy fallback**
pattern; keep everything **web-safe** (no `dart:io`).

### P0 — close the "looks done but isn't" gaps ✅ DONE
1. ✅ **Persist hot-zone reports.** `ReportSpotSheet._submit()` (optimistic pin → write) and
   `CreateHotZoneReportScreen._submit()` (added field controllers) call
   `ReportService.submitHotZoneReport()` with the current `userId`.
2. ✅ **Read reports from Firestore.** Map + Home load via `ReportService.getHotZoneReports()`
   (dummy fallback intact).
3. ✅ **Wire community verification.** "Still hot" / "Problem fixed" → `ReportService.verifyReport(id)`,
   optimistic count bump, credit verifier's `verifiedReportCount`. *Follow-up:* per-user
   already-verified guard + richer option set.

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
7. ✅ **DONE (core)** — Profile is a live 5th tab backed by `UserProfileService` + Firestore
   `users/{uid}`, with edit + sign out. Still TODO: persist saved routes from the Route tab
   (`addSavedRoute`) and increment stat counters once reports/verification persist (P0).

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
Use `-d edge` instead of `-d chrome` if Chrome isn't installed (Edge is Chromium-based).
With an empty `.env`, the app runs on built-in fallbacks (painted map + dummy weather). Firebase
falls back to the dummy-data prototype path if not configured. `flutter analyze` is currently clean.

---

## History / Changelog

Newest first. Dates are absolute.

- **2026-06-03** — **P1: real heat-safe routing.** New `RoutingService` (OpenRouteService —
  CORS-friendly, needs `ORS_API_KEY`) does geocoding + walking directions (with alternatives).
  `RoutePlanner` scores each route by proximity to reported hot zones and labels Fastest / Cooler
  (Recommended). `route_screen.dart` rewritten: start = current location, destination via search
  **or** map tap; `route_map.dart` draws the chosen route as a polyline with start/destination +
  hot-zone markers. `RouteOption` extended with geometry/metrics. `flutter analyze` clean.
  *(Not yet committed. Requires `ORS_API_KEY` in `.env`.)*
- **2026-06-03** — **Cool-spot suggestions now persist.** The map's "Suggest a Cool Spot" form
  writes to Firestore via `CoolSpotService.submitCoolSpot` (stores real lat/lng + category, returns
  the doc id). The map merges community suggestions (those with real coordinates) with the live
  OSM results and reloads on a `coolSpotRevision` signal, so a suggestion appears immediately and
  survives refresh. No rules change needed (the `coolSpots` create rule was already open to
  authed users). *(Not yet committed.)*
- **2026-06-03** — **P0 fixes from testing.** (A) Report sheet's *Type* selector is now a
  scrollable modal picker (dropdown overlays leaked wheel-scroll to the Google Map). (B) New
  reports show live on Map + Home via a `hotZoneRevision` refresh signal (no restart). (D/E)
  Verification is now **one per user per report** — `verifyReport(id, uid)` runs a transaction
  against a `verifiedBy` list, the buttons disable once you've verified, and the counter only
  bumps on a genuinely new verification. **Requires deploying `backend/firestore.rules`** (now
  allows `verifications` + `verifiedBy`). *(Not yet committed.)*
- **2026-06-03** — **P0 community/data-write wired.** Hot-zone reports now persist to Firestore
  (`ReportService.submitHotZoneReport` returns the new doc id; `CreateHotZoneReportScreen` gained
  field controllers). Map + Home read reports via `getHotZoneReports()`. "Still hot" / "Problem
  fixed" call `verifyReport()` with an optimistic count bump. Author `reportCount` +
  `verifiedReportCount` increment (set+merge so they work pre-doc-creation); Profile gained a
  refresh button to pull updated counters. `flutter analyze` clean. *(Not yet committed.)*
- **2026-06-03** — Added Firestore-backed **Profile tab** (5th tab, mobile + web). Loads
  `users/{uid}` (auto-created), edits name/role/home-area/heat-sensitivity, stats, sign out.
  Fixed a false "could not save" error by driving the UI from local state (Firestore is
  offline-first) instead of the server-ack Future. Added `UserProfileService.updateProfile()`.
  Pushed in commit `e8439c5`.
- **2026-06-03** — **Live data milestone.** Added `WEATHER_API_KEY` + `GOOGLE_MAPS_API_KEY` to
  `.env`; enabled Firebase **Anonymous** auth. Verified Weather, Google Maps (web + Android),
  NASA GIBS, OSM cool spots, and guest sign-in all run on live data. Pushed in commit `0304834`.
  (Diagnosed: invalid first weather key → WeatherAPI code 2006; corrected. `admin-restricted-operation`
  on guest login → Anonymous provider was disabled; enabled in console.)
- **2026-06-03** — Initial **audit** of the codebase vs the spec PDF; created this
  `PROJECT_STATUS.md`.
- **2026-06-03** — Cloned repo, ran `flutter pub get` (first time — fixed the "Target of URI
  doesn't exist" analyzer errors), created `.env`, verified collaborator push access to `main`.
