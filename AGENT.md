# CLAUDE.md — CoolRoute Project Instructions

Read this file completely before making any changes. Also read `DESIGN.md` in the project root before touching any UI file.

---

## Project Overview

CoolRoute is a heat-safe navigation and community reporting Flutter app. It helps users reduce outdoor heat exposure by suggesting cooler routes, showing community-reported hot zones on a map, finding cool spots, and displaying NASA GIBS-style environmental data.

**Theme:** Fighting the impact of increased Earth temperature.
**Stage:** Frontend UI prototype. No real backend, API, or database yet. All data is dummy/hardcoded.

---

## Platforms

Target platforms: **Android** and **Flutter Web**.

### Hard platform rules
- Never use `dart:io` — it breaks on web. Use `dart:typed_data` or `kIsWeb` checks instead.
- Never use `path_provider` for anything that runs on web.
- Never use `File` from `dart:io` — use `Uint8List` or conditional imports.
- All packages must be web-safe. Check pub.dev web compatibility before adding.
- Google Maps: use `google_maps_flutter` with a web API key. If the key is missing or maps fail to load, show the custom fallback map widget (`CustomMapFallback`) — never crash or show a blank screen.
- Use `kIsWeb` from `flutter/foundation.dart` for platform branching.

---

## Navigation Structure

4 tabs only. Bottom navigation bar on mobile/tablet. Top app bar navigation on web (width > 800px).

| Tab | Screen file | Route |
|-----|-------------|-------|
| Home | `home_screen.dart` | `/` |
| Route | `route_screen.dart` | `/route` |
| Map | `map_screen.dart` | `/map` |
| Data | `data_screen.dart` | `/data` |

Cool Spots is a filter mode inside the Map tab — not a separate tab. The old 5-tab layout with a separate Cool Spots tab has been removed.

---

## Folder Structure

```
lib/
  main.dart
  app.dart                  # MaterialApp, theme, routing
  theme/
    app_theme.dart          # All color tokens, TextTheme, ThemeData
  screens/
    home_screen.dart
    route_screen.dart
    map_screen.dart
    data_screen.dart
  widgets/
    custom_map_fallback.dart   # Fallback when Google Maps unavailable
    hot_zone_bottom_sheet.dart # Map marker detail panel
    hot_zone_side_panel.dart   # Web version of the above
    route_card.dart
    cool_spot_card.dart
    heat_stat_row.dart
    layer_chip_bar.dart        # Environmental data layer selector
  models/
    hot_zone.dart
    cool_spot.dart
    route_option.dart
    env_layer.dart
  data/
    dummy_hot_zones.dart
    dummy_cool_spots.dart
    dummy_routes.dart
    dummy_env_layers.dart
  services/
    location_service.dart     # Stub only — returns dummy Bangkok coords
    map_service.dart          # Stub only
```

If files don't exist yet, create them in the correct location. Never put business logic inside screen files — keep screens as layout + state only.

---

## Dummy Data Rules

- All data is hardcoded in `lib/data/`. Never fetch from a real API.
- Location is always Bangkok, Thailand (13.7563° N, 100.5018° E).
- Current weather is always: 36°C, feels like 41°C, humidity 70%, UV High, heat risk Extreme.
- Hot zones: minimum 6 entries with a mix of red (extreme/high), orange (medium), and green (shade/cool) markers.
- Cool spots: minimum 5 entries — university library, water refill station, tree walkway, 7-Eleven, shopping mall.
- Routes: 3 options — Fastest (high risk), Cooler (medium risk, recommended), Indoor Cut-through (low risk).
- Environmental layers: 6 entries — Land Surface Temp, Sea Surface Temp, Cloud Cover, Aerosol/Air Quality, UV/Ozone, Weather Heat Index.
- One hot zone must always be set as `isSelected: true` by default for the Map screen. Use "Engineering Building Walkway" as the default selected marker.

---

## Dummy Data Content Quality

Use realistic content. No "Example 1", no "Lorem ipsum", no "Test location".

Hot zone report examples:
- "Engineering Building Walkway — exposed concrete, no shade, 8 users verified"
- "Main Gate Bus Stop — no shelter, direct sunlight 11AM–3PM, 14 users"
- "Science Faculty Open Plaza — heat radiates from paving, 6 users"

Cool spot examples:
- "University Library — air-conditioned, open 8AM–8PM, 250m away"
- "Water Refill Station (Near Gate 3) — working, free, 180m away"
- "Tree Covered Walkway (Engineering Path) — natural shade, always available"

---

## Web Layout Rules

Apply these breakpoints consistently:

| Width | Layout mode |
|-------|-------------|
| < 600px | Mobile: bottom nav, single column, bottom sheets |
| 600–800px | Tablet: bottom nav, slightly wider cards |
| > 800px | Web: top nav bar, side panels, max-width containers |

On web (> 800px):
- Non-map screens: max content width 900px, centered with `Center` + `ConstrainedBox`.
- Home: action grid becomes 4 columns instead of 2×2.
- Route: left panel (form + route cards, ~380px) + right map panel (remaining width).
- Map: full-bleed map + right side panel (320px) instead of bottom sheet.
- Data: left sidebar (layer list, 280px) + right viz panel fills remaining width.
- Never stretch card content to full browser width on large screens.

---

## State Management

Use `StatefulWidget` or `provider` — whichever is already in use. Do not introduce a new state management library without asking.

Map screen selected marker state must be held at the screen level (not inside the map widget) so the bottom sheet / side panel can read it.

---

## Google Maps Fallback

The `CustomMapFallback` widget is a custom-painted Flutter canvas map showing:
- Styled background (muted green-gray, `#E8F0EC`)
- Road lines (white, `StrokeCap.round`)
- Building block rectangles (light gray and light green)
- All hot zone and cool spot markers positioned by relative coordinates
- "Prototype map — live maps disabled" label bottom-left

This widget must be fully functional and visually clean. It is the primary map shown in screenshots if Google Maps is unavailable.

---

## Code Quality Rules

- Run `flutter analyze` after every change. Fix all errors before proceeding.
- Never leave `// TODO` comments in production UI code.
- Never hardcode colors inline — always use `AppTheme.colorName` or the theme.
- Never hardcode text styles inline — always use `Theme.of(context).textTheme`.
- Widget files must not exceed ~200 lines. Split into sub-widgets if needed.
- Use `const` constructors wherever possible.
- All screen widgets must handle both narrow (mobile) and wide (web) layouts.

---

## What Not To Do

- Do not rebuild the entire project from scratch unless explicitly told to.
- Do not add new packages without checking web compatibility.
- Do not change dummy data values without being asked.
- Do not use `showModalBottomSheet` for the map panel — use a custom positioned bottom sheet so it can coexist with the map without obscuring markers.
- Do not put the bottom nav bar inside the map's Scaffold — it must be in the root Scaffold.
- Do not use lorem ipsum or placeholder titles anywhere visible in the UI.

---

## Conflict Resolution

1. User's latest instruction takes priority.
2. `DESIGN.md` controls all visual decisions.
3. This file (`CLAUDE.md`) controls architecture and structure.
4. Do not break existing working screens while changing another screen.
