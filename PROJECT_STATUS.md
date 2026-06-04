# CoolRoute — Implementation Status

> Group 10, Integrated Project 2. Last reviewed: **2026-06-05**.

**Legend:** ✅ Done · 🟡 Partial · ❌ Missing

---

## Current state — submission-ready

CoolRoute is a **fully wired, live-data app**. Every core feature is implemented end-to-end against real APIs and Firestore. The app is not a prototype.

---

## Feature checklist

### Authentication
- [x] Email / Password sign-in (Firebase Auth)
- [x] Google Sign-in (native `GoogleAuthProvider`, no extra package)
- [x] Anonymous / guest sign-in
- [x] Sign-out from Profile tab (web + mobile)
- [ ] Enable Email/Password + Google providers in Firebase console ← **manual**

### APIs & integrations
- [x] **Google Maps** — live (`GOOGLE_MAPS_API_KEY` in `.env`)
- [x] **WeatherAPI.com** — live (`WEATHER_API_KEY` in `.env`)
- [x] **OpenRouteService** — live routing + geocoding (`ORS_API_KEY` in `.env`)
- [x] **NASA GIBS** — live WMTS tiled map (keyless)
- [x] **OpenStreetMap Overpass** — live cool-spot discovery (keyless)
- [x] **Firebase Auth + Firestore** — fully configured (`first-project-e258e`)

### Core CRUD — Hot Zone Reports
- [x] **Create** — from Map (tap-to-report) and Home (form screen); persists to Firestore `hotZones`
- [x] **Read** — Map + Home load live from Firestore; real-time refresh on new report
- [x] **Update** — community "Still hot" verification (per-user, transaction-enforced); "Problem fixed" vote tracked separately
- [x] **Delete** — three paths: (1) 48-hour auto-expiry on read, (2) 3× "Problem fixed" community takedown removes doc from Firestore + map immediately, (3) owner delete from Profile → My Contributions
- [x] **Edit** — owner can edit title / description / category from Profile → My Contributions

### Cool Spots
- [x] OSM Overpass real-data discovery (nearby libraries, malls, water, parks, cafés)
- [x] Community suggestion form persists to Firestore `coolSpots`
- [x] Map filter (Water / Shade / Air-conditioned / Open Now)
- [x] 48-hour auto-expiry on community-submitted spots
- [x] Owner delete + **edit** from Profile → My Contributions

### Tree-Planting Events
- [x] Create event via Map → Report → "Start a Tree-Planting Event"; real Google-map location picker
- [x] RSVP / Water / Donate / Attend — one per user per action, transaction-enforced
- [x] Live refresh on create; live count updates on contribution
- [x] Owner delete + **edit** from Profile → My Contributions

### Heat-Safe Routing (headline feature)
- [x] Browser / device location via `geolocator` (web-safe; falls back to Bangkok center with amber warning label)
- [x] Destination by geocoding search (ORS Pelias — venues, addresses, streets, landmarks) or map tap
- [x] Real walking routes via OpenRouteService (up to 3 alternatives)
- [x] Heat scoring: routes ranked by proximity to reported hot zones; coolest = "Recommended"
- [x] Route drawn as polyline on the map; alternate routes in grey
- [x] Route cards: route name label, duration, distance, Recommended / Fastest badge, hot-zone count pill
- [x] Save route to profile (stores destination coordinates); reopening replans automatically
- [x] Start button (navigation intent placeholder)

### NASA Environmental Data Viewer
- [x] 7 layers as a live WMTS tiled map (pannable/zoomable via `flutter_map`)
- [x] Layers: Land Surface Temp, Sea Surface Temp, Cloud Cover, Aerosol/Air Quality, UV/Ozone, Weather Heat Index, Vegetation (NDVI)
- [x] Date presets (Today / 1d / 3d / 1w / 1mo) + custom date picker
- [x] Per-layer plain-language blurb in the info panel
- [x] NDVI snapped to last completed monthly composite

### Profile & Saved Routes
- [x] Firestore-backed user profile (`users/{uid}`, auto-created on first load)
- [x] Edit name / role / home area / heat sensitivity
- [x] Contribution stats: reports / verifications / saved routes
- [x] Saved routes list with delete; reopening replans the route
- [x] **My Contributions** section — expandable lists of user's own reports, cool spots, tree events; each with delete (confirmation dialog) + edit (reports only)
- [x] Auto-refresh via `profileRevision` signal; manual refresh button

### Map
- [x] Custom teardrop pins rendered via `dart:ui` — colored by risk / type, icon per category (fire 🔥, water 💧, shade 🌳, AC ❄️, tree 🌳)
- [x] Hot zones, cool spots, and tree events each have distinct pin styles
- [x] Falls back to standard hued pins while custom bitmaps are loading
- [x] Draggable "nearby" sheet bounded to the screen (can't be dragged off-top); Locate + Report FABs track the sheet, not the tab bar
- [x] Home "Recent alerts" chips open the Map focused on that hot zone

### Timestamps
- [x] `createdAt` stored as Firestore `serverTimestamp()` on every new report, cool spot, tree event
- [x] `displayTimeAgo` computed from `createdAt` at read time: "just now" / "N min ago" / "N hrs ago" / "yesterday" / "N days ago" / "Jan 5" — shown in zone details, home alert chips, Profile → My Contributions

### Housekeeping / polish
- [x] "Continue as prototype user" button removed from welcome screen
- [x] Image placeholder removed from zone details panel
- [x] Photo attachment removed from report forms
- [x] NASA info bar and legend removed from Data screen
- [x] Dummy data removed as primary data source from all screens (service-layer graceful fallbacks kept)
- [x] `flutter analyze` clean

---

## Outstanding manual steps before submission

| Step | Command / Where |
|---|---|
| **Deploy Firestore rules** (re-deploy — added cool-spot/tree-event owner-edit) | `cd backend && firebase deploy --only "firestore:rules"` |
| **Enable Email/Password auth** | Firebase console → Authentication → Sign-in method → Email/Password → Enable |
| **Enable Google auth** | Firebase console → Authentication → Sign-in method → Google → Enable |
| **Firestore composite indexes** | Already building — confirm all 3 show "Enabled" in console (hotZones / coolSpots / treeEvents on `userId` + `createdAt`) |

---

## Firestore collections & current rules summary

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| `hotZones` | public | authed, requires `title`+`location`+`risk`+`createdAt` | authed: `verifications`/`verifiedBy`/`resolvedBy` OR owner edits `title`/`description`/`category` | owner OR `resolvedBy.size() >= 3` |
| `coolSpots` | public | authed, requires `name`+`type`+`createdAt` | authed: `verifiedBy` OR owner edits `name`/`category`/`amenity` | owner |
| `treeEvents` | public | authed, requires `title`+`createdAt` | authed: `rsvpBy`/`waterBy`/`donateBy`/`attendBy` OR owner edits `title`/`locationName`/`datePlanted`/`description`/`goalTrees` | owner |
| `users/{uid}` | owner | owner | owner | owner |

---

## Known non-critical items (not blocking submission)

- GIBS sparse-tile 404 console spam — benign (NASA returns 404 for ocean/empty tiles); map renders correctly
- `lib/screens/cool_spots/cool_spots_screen.dart` — orphaned file, not wired into navigation; safe to ignore or delete
- `lib/services/route_service.dart` — returns dummy routes, never used; safe to delete
- Route heat-scoring uses hot-zone proximity only (cool spots / shade not yet factored in)

---

## How to run

```powershell
flutter pub get
flutter run -d chrome    # web (use -d edge if Chrome unavailable)
flutter run              # Android device / emulator
flutter analyze          # must be clean — currently clean
```

`.env` must contain valid keys for full functionality. Without keys the app degrades gracefully (painted fallback map, dummy Bangkok weather, routing disabled with inline warning).
