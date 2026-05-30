# DESIGN.md — CoolRoute Visual Design System

Read this file fully before touching any UI file. All visual decisions — colors, spacing, typography, component style — are defined here. Do not deviate from this system.

---

## Design Direction

CoolRoute should feel like a **modern climate-tech navigation app**.

Reference feeling: Google Maps + heat-safety community reporting + NASA climate dashboard.

| Quality | Meaning |
|---------|---------|
| Clean | No clutter, no decorative noise |
| Trustworthy | Data is real-feeling and precise |
| Map-focused | The map is always the hero |
| Safety-oriented | Heat risk is always visible |
| Environmental | Climate context, not just navigation |

---

## Color Tokens

Define all of these in `lib/theme/app_theme.dart` as static constants.

### Core palette

```dart
// Backgrounds
static const Color bgPage        = Color(0xFFF4F6F4); // off-white, all non-dark screens
static const Color bgCard        = Color(0xFFFFFFFF); // white cards
static const Color bgHero        = Color(0xFF0D1F1A); // dark forest — Home hero
static const Color bgDark        = Color(0xFF0D1620); // dark navy — Data screen
static const Color bgDarkAlt     = Color(0xFF111E1A); // slightly lighter dark — Data info section

// Brand
static const Color primary       = Color(0xFF1D9E75); // teal — primary actions, active states
static const Color primaryLight  = Color(0xFFE1F5EE); // teal tint — icon backgrounds, badges
static const Color primaryDark   = Color(0xFF0F6E56); // dark teal — pressed states

// Heat risk
static const Color riskExtreme   = Color(0xFFE24B4A); // red — extreme/high hot zones
static const Color riskHigh      = Color(0xFFE24B4A);
static const Color riskMedium    = Color(0xFFEF9F27); // amber — medium hot zones
static const Color riskLow       = Color(0xFF1D9E75); // teal — low risk
static const Color riskNone      = Color(0xFF639922); // green — shade/cool spots

// Risk badge backgrounds (light fills)
static const Color riskExtremeBg = Color(0xFFFCEBEB);
static const Color riskMediumBg  = Color(0xFFFAEEDA);
static const Color riskLowBg     = Color(0xFFEAF3DE);

// Marker colors
static const Color markerRed     = Color(0xFFE24B4A); // extreme/high hot zone
static const Color markerOrange  = Color(0xFFEF9F27); // medium hot zone
static const Color markerGreen   = Color(0xFF1D9E75); // shade / cool outdoor
static const Color markerBlue    = Color(0xFF378ADD); // water point / indoor cooling

// Text
static const Color textPrimary   = Color(0xFF1A2E1F); // near-black with green tint
static const Color textSecondary = Color(0xFF5A7060); // muted green-gray
static const Color textHint      = Color(0xFF8FA896); // placeholder, hint text
static const Color textOnDark    = Color(0xFFFFFFFF);
static const Color textOnDarkMid = Color(0x99FFFFFF); // 60% white — subtext on dark
static const Color textOnDarkDim = Color(0x66FFFFFF); // 40% white — hints on dark

// Borders
static const Color borderLight   = Color(0xFFE0E8E2); // default card border
static const Color borderMid     = Color(0xFFC8D5CC); // emphasis border

// Map background
static const Color mapBg         = Color(0xFFE8F0EC); // fallback map canvas

// Status
static const Color statusOpen    = Color(0xFF1D9E75);
static const Color statusOpenBg  = Color(0xFFE1F5EE);
static const Color statusClosed  = Color(0xFFE24B4A);
static const Color statusClosedBg = Color(0xFFFCEBEB);
```

---

## Typography

Use `GoogleFonts.inter()` if available, otherwise system font. All sizes in logical pixels.

```dart
// Display — temperature, large numbers
displayLarge:  28px, weight 500, textPrimary
displayMedium: 22px, weight 500, textPrimary

// Headings
headlineLarge:  18px, weight 500, textPrimary
headlineMedium: 16px, weight 500, textPrimary

// Body
bodyLarge:  15px, weight 400, textPrimary,   height 1.5
bodyMedium: 14px, weight 400, textSecondary, height 1.5
bodySmall:  12px, weight 400, textSecondary, height 1.5

// Labels (badges, chips, stats)
labelLarge:  13px, weight 500, textPrimary
labelMedium: 12px, weight 500
labelSmall:  11px, weight 500, letterSpacing 0.3
```

Rules:
- Never hardcode font sizes inline. Always use `Theme.of(context).textTheme`.
- Never use font weight 700 or 800 — maximum is 500 (medium).
- Sentence case everywhere. No ALL CAPS except `labelSmall` category chips.

---

## Spacing

Use a consistent 8px base grid.

```dart
static const double spaceXS  = 4.0;
static const double spaceSM  = 8.0;
static const double spaceMD  = 16.0;
static const double spaceLG  = 24.0;
static const double spaceXL  = 32.0;

static const double radiusSM = 6.0;
static const double radiusMD = 10.0;
static const double radiusLG = 14.0;
static const double radiusPill = 20.0;
```

---

## Component Specs

### Cards (general)

```
background: bgCard (#FFFFFF)
border: 0.5px solid borderLight
border-radius: radiusLG (14px)
padding: 16px horizontal, 14px vertical
elevation: 0 (no shadow)
```

Never use Material elevation shadows on cards. Use the border instead.

### Risk / heat badges

Small pill-shaped labels. Always use colored background + matching dark text.

```
Extreme / High:  bg riskExtremeBg, text riskExtreme, border none
Medium:          bg riskMediumBg,  text Color(0xFF854F0B)
Low:             bg riskLowBg,     text Color(0xFF3B6D11)
Recommended:     bg primaryLight,  text primaryDark
```

Specs: `border-radius: radiusPill`, `padding: 3px 10px`, `font: labelSmall`

### Buttons

Primary action button:
```
background: primary (#1D9E75)
text: white, labelLarge
border-radius: radiusMD (10px)
height: 46px
width: full-width in cards, auto elsewhere
```

Outlined button (verification actions: Still Hot, Problem Fixed):
```
background: transparent
border: 1px solid primary
text: primary, labelMedium
border-radius: radiusMD
height: 38px
```

Destructive outlined (Still Hot only):
```
border: 1px solid riskExtreme
text: riskExtreme
```

### Filter chips

```
selected:   bg primary, text white, border none
unselected: bg bgCard, text textSecondary, border 0.5px borderLight
border-radius: radiusPill
padding: 6px 14px
font: labelMedium
```

### Bottom sheet (Map screen, mobile)

```
background: bgCard
border-radius: 16px top corners only
handle bar: 4px × 32px, color borderMid, centered, 8px from top
drag handle padding: 12px top
content padding: 0 16px 24px
max height: 70% of screen height
```

### Side panel (Map screen, web)

```
width: 320px
background: bgCard
border-left: 0.5px solid borderLight
height: 100% (fills screen height minus nav bar)
padding: 20px 16px
overflow-y: scroll
```

### Navigation bar (mobile)

```
background: bgCard
border-top: 0.5px solid borderLight
selected icon + label: primary color
unselected: textHint
indicator: primaryLight oval behind icon
elevation: 0
```

### Navigation bar (web, top)

```
background: bgCard
border-bottom: 0.5px solid borderLight
logo left, tabs center or right
tab selected: primary color underline (2px)
height: 56px
```

---

## Screen-by-Screen Rules

### Home screen

Structure (top to bottom):
1. **Hero card** — full width, `bgHero` (#0D1F1A), no border-radius on top (flush to screen edge or app bar)
   - City name + time: `labelSmall`, `textOnDarkDim`
   - Temperature: `displayLarge` (28px), `textOnDark`
   - Feels like / humidity / UV: one line, `bodySmall`, `textOnDarkMid`
   - Risk pill badge: red bg + white text, `riskExtreme`
   - Stat row: 4 boxes — Feels like, Humidity, Hot zones, Cool spots. Each: `rgba(255,255,255,0.07)` bg, value in white 500, label in `textOnDarkDim`, `radiusSM`
2. **Quick actions grid** — 2×2 on mobile, 4-column on web. Compact cards (not tall icon tiles). Each card: icon in tinted circle (24px icon), title `labelLarge`, subtitle `bodySmall textSecondary`. No large decorative icons.
3. **Recent hot zone alerts** — horizontal scroll row of 3 compact alert chips. Each chip shows: heat level color dot + location name + time ago. Tap goes to Map screen with that marker selected.
4. Safety tip bar — single line at bottom, dismissible.

Do not show a "Today's Safety Tips" bulleted list. Replace with the alert chips row.

### Route screen

Structure (web: side-by-side | mobile: stacked):
- **Left/top panel** — Start field, Destination field, Time picker, Find Route button
- **Right/bottom panel** — map preview (tall, ~50% screen height on web, ~35% on mobile) + route cards below

Route cards:
- Title + risk badge on same row (space-between)
- Subtitle line (passes X hot zones / passes Y cool spots)
- Stat row: clock icon + time, arrows icon + distance, tree icon + shade level. Font `labelMedium`, icon size 14px.
- Full-width primary button "Select route"
- `Recommended` badge only on Cooler Route — teal bg

Map preview in route screen:
- Uses `CustomMapFallback` or Google Maps
- Shows colored route lines: fastest = orange, cooler = teal, indoor = blue
- No padding — flush to card edge

### Map screen

This is the most important screen. It must look polished and feature-complete.

**Layout:**
- Map is always full-bleed (fills entire area between app bar / nav bar). Zero padding.
- Floating search bar: white pill, 16px from top, 16px side margins, elevation 0, `border: 0.5px solid borderLight`. Icon `ti-search` or Flutter search icon.
- Floating filter chips: horizontal scroll row, 8px below search bar, same side margins. Do not use a filter bar above the map — everything floats over the map.
- FAB "Report" button: bottom-right, `bgCard` background, primary icon, label "Report".

**Default state:**
- One marker must always be pre-selected. Default: "Engineering Building Walkway" (red marker, extreme heat).
- Bottom sheet (mobile) or side panel (web) must be visible on first render.

**Bottom sheet content (in order):**
1. Drag handle
2. Report title (`headlineMedium`)
3. Location name with pin icon (`bodySmall`, `textSecondary`)
4. Heat level badge + category label on same row
5. Description paragraph (`bodyMedium`)
6. Image placeholder — rounded rect, `bgPage` fill, camera icon centered, `bodySmall` "No photo yet"
7. Meta row: time reported + verification count (e.g. "Verified by 8 users")
8. Verification buttons row: "Still hot" (destructive outlined) + "Problem fixed" (primary outlined) + "View details" (primary filled). Equal spacing.
9. Divider
10. "Nearby reports" section header (`labelLarge`)
11. 2–3 compact nearby report rows: colored dot + title + distance + heat badge

**Marker specs:**
```
All markers: circle, 28px diameter, white ring (2px), shadow-free
Red:    markerRed    (#E24B4A) — extreme / high heat
Orange: markerOrange (#EF9F27) — medium heat
Green:  markerGreen  (#1D9E75) — shade / cool outdoor
Blue:   markerBlue   (#378ADD) — water / indoor cooling
Icon inside marker: white, 14px
Selected marker: 36px diameter, ring becomes 3px
```

### Environmental Data screen

**The entire screen uses a dark theme.** There is no white anywhere on this screen.

```
Scaffold background: bgDark (#0D1620)
```

Structure (top to bottom):
1. **Screen title area** — "Environmental data" in white, subtitle "NASA GIBS · Weather API" in `textOnDarkDim`. Padding 16px.
2. **Viz panel** — fills ~45% of screen height. Dark bg (`bgDark`). Shows the animated ellipse/heatmap visualization. No card border or border-radius. Full width.
   - Floating layer chip bar at bottom of viz panel: horizontal scroll, chips inside viz. Active chip: `primary` bg + white text. Inactive: `rgba(255,255,255,0.08)` bg + `textOnDarkMid`.
   - "NASA GIBS + Weather API dummy layer" label: bottom-right corner, `labelSmall`, `textOnDarkDim`.
3. **Info panel** — `bgDarkAlt` (#111E1A) background, full width, no border.
   - Layer name: `headlineMedium`, `primary` color (teal)
   - "What it means" heading: `labelLarge`, `textOnDark`
   - Description: `bodyMedium`, `textOnDarkMid`
   - "Why it matters for heat safety" heading: `labelLarge`, `textOnDark`
   - Body: `bodyMedium`, `textOnDarkMid`
   - Color scale legend bar: full-width rounded bar, gradient cool blue → teal → amber → red. Label "Cool → Hot" right-aligned in `labelSmall` `textOnDarkDim`.

Do not use white cards on this screen. Do not use the standard `bgPage` scaffold on this screen.

### Cool Spots screen

Cool Spots is a mode within the Map tab on web. On mobile it can remain as a separate view accessible from the Map screen filter bar.

List item specs:
- Icon circle: 40px, colored by type (air-cond = blue tint `Color(0xFFE6F1FB)`, water = blue, shade = green tint `Color(0xFFEAF3DE)`, indoor = `primaryLight`)
- Name: `bodyLarge`, `textPrimary`
- Type label: `bodySmall`, `textSecondary`
- Distance + verified count: `labelSmall`, `textHint`
- Status badge: pill, colored (Open = `statusOpenBg`/`statusOpen`, Working = same, Available = `primaryLight`/`primaryDark`)
- View button: outlined, `primary` color, `radiusMD`, text "View", no full-width

---

## Fallback Map Visual Spec

`CustomMapFallback` must look like a stylized campus/city map:

```
Canvas background: mapBg (#E8F0EC)
Road lines: Color(0xFFFFFFFF), strokeWidth 6, StrokeCap.round
Minor roads: Color(0xFFFFFFFF), strokeWidth 3
Building blocks: two styles —
  - Light gray block: Color(0xFFCDD5D0), rounded rect
  - Green block (park/field): Color(0xFFD4E8D8), rounded rect
Markers: as per marker spec above, positioned by relative canvas fractions
"Prototype map" label: bottom-left, labelSmall, textSecondary, bgCard bg pill
```

---

## What Not To Do (Anti-Pattern Checklist)

Before finishing any screen, check that none of these exist:

- [ ] Pure white `#FFFFFF` scaffold background (use `bgPage` #F4F6F4 instead, except dark screens)
- [ ] Large decorative icons (> 32px) used as action tile icons
- [ ] Inline color hardcoding (`Color(0xFF...)` in screen/widget files — use AppTheme tokens)
- [ ] Inline text style hardcoding (`TextStyle(fontSize: 14)` — use textTheme)
- [ ] Material elevation shadows on cards
- [ ] Bottom sheet overlapping the bottom nav bar
- [ ] "Example 1", "Lorem ipsum", "Test data" in visible UI text
- [ ] Stretched single-column layout on desktop web (> 800px)
- [ ] Environmental Data screen with any white or light-colored section
- [ ] Map screen without a pre-selected marker and visible panel on first load
- [ ] Font weight 600, 700, or 800 anywhere
- [ ] ALL CAPS text outside of chip labels
- [ ] 5-tab navigation (Cool Spots is not a separate tab)
