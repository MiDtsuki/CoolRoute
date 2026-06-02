import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/dummy_tree_pins.dart';
import '../../dummy_data/dummy_data.dart';
import '../../models/cool_spot.dart';
import '../../models/heat_risk.dart';
import '../../models/hot_zone_report.dart';
import '../../models/nearby_report.dart';
import '../../models/tree_pin.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cool_spot_card.dart';
import '../../widgets/coolroute_map.dart';
import '../../widgets/hot_zone_bottom_sheet.dart';
import '../../widgets/hot_zone_side_panel.dart';
import '../../widgets/location_pin_picker.dart';
import '../../widgets/report_spot_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialTreesSelected = false});

  final bool initialTreesSelected;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _coolSpotsMode = false;
  HotZoneReport? _selectedZone;
  TreePin? _selectedTree;
  CoolSpot? _focusedSpot;
  LatLng? _userLocation;
  bool _locating = false;
  int _recenterTick = 0;
  late String _activeFilter;

  // Real, location-based cool spots. Seeded with local data so the screen has
  // content immediately; replaced with live OpenStreetMap results once the
  // user's location resolves.
  List<CoolSpot> _coolSpots = DummyData.coolSpots;
  bool _loadingSpots = false;

  // Hot zones shown on the map. Mutable so freshly reported (pending) zones can
  // be appended without a backend round-trip.
  final List<HotZoneReport> _hotZones = List.of(DummyData.hotZones);

  // Live search query (matches names/categories across the active dataset).
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Camera focus for a searched/selected point (hot zone). Bumping the tick
  // re-issues the move even to the same coordinate.
  LatLng? _focusLatLng;
  int _focusTick = 0;

  static const _treesFilter = 'Trees 🌱';
  static const _zoneFilters = [
    'All',
    'High heat',
    'No shade',
    'Broken water',
    'Verified',
    _treesFilter,
  ];
  static const _spotFilters = [
    'All',
    'Water',
    'Shade',
    'Air-conditioned',
    'Open Now',
  ];

  List<String> get _filters => _coolSpotsMode ? _spotFilters : _zoneFilters;
  List<NearbyReport> get _nearby => DummyData.nearbyReports.take(3).toList();
  bool get _showTrees => !_coolSpotsMode && _activeFilter == _treesFilter;

  // Cool spots after applying the active filter and the search query.
  List<CoolSpot> get _visibleSpots {
    return _coolSpots.where((s) {
      final passesFilter = switch (_activeFilter) {
        'Water' => s.type == 'Water',
        'Shade' => s.type == 'Shade',
        'Air-conditioned' => s.type == 'Air-conditioned',
        'Open Now' => s.openStatus == 'Open' ||
            s.openStatus == 'Working' ||
            s.openStatus == 'Available',
        _ => true,
      };
      return passesFilter &&
          _matchesQuery([s.name, s.displayCategory, s.type, s.amenity]);
    }).toList();
  }

  // Hot zones after applying the active filter and the search query. Empty when
  // the Trees filter is active (the map then shows tree pins instead).
  List<HotZoneReport> get _visibleZones {
    if (_showTrees) return const [];
    return _hotZones.where((z) {
      final cat = z.category.toLowerCase();
      final passesFilter = switch (_activeFilter) {
        'High heat' => z.risk == HeatRisk.extreme || z.risk == HeatRisk.high,
        'No shade' => cat.contains('shade') || cat.contains('exposed'),
        'Broken water' => cat.contains('water'),
        'Verified' => z.verifications >= 10,
        _ => true,
      };
      return passesFilter &&
          _matchesQuery([z.title, z.location, z.category]);
    }).toList();
  }

  // Tree pins filtered by the search query (shown when the Trees filter is on).
  List<TreePin> get _visibleTrees {
    if (!_showTrees) return const [];
    return DummyTreePins.pins
        .where((t) => _matchesQuery([t.title, t.locationName]))
        .toList();
  }

  bool _matchesQuery(List<String> fields) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return fields.any((f) => f.toLowerCase().contains(q));
  }

  // Unified search hits across both datasets, used by the results dropdown so a
  // user can jump to a cool spot or a hot zone regardless of the active tab.
  List<_SearchHit> get _searchResults {
    if (_query.trim().isEmpty) return const [];
    final hits = <_SearchHit>[];
    for (final s in _coolSpots) {
      if (_matchesQuery([s.name, s.displayCategory, s.type, s.amenity])) {
        hits.add(_SearchHit.spot(s));
      }
    }
    for (final z in _hotZones) {
      if (_matchesQuery([z.title, z.location, z.category])) {
        hits.add(_SearchHit.zone(z));
      }
    }
    return hits.take(8).toList();
  }

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialTreesSelected ? _treesFilter : 'All';
    _resolveLocation();
  }

  // Asks for the device location and centres the map on the user's 3km area.
  // Falls back to the default city when permission is denied/unavailable.
  Future<void> _resolveLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await LocationService().currentLocation();
    if (!mounted) return;
    setState(() {
      _userLocation = LatLng(result.latitude, result.longitude);
      _recenterTick++;
      _locating = false;
    });
    if (!result.isReal && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location unavailable — showing the default area.'),
        ),
      );
    }
    _loadCoolSpots(result.latitude, result.longitude);
  }

  // Pulls real, nearby cool spots from OpenStreetMap around the resolved
  // location. Falls back to the bundled local set if the request fails or
  // returns nothing, so the list/markers are never empty.
  Future<void> _loadCoolSpots(double lat, double lng) async {
    setState(() => _loadingSpots = true);
    List<CoolSpot> spots;
    try {
      spots = await PlacesService().nearbyCoolSpots(
        lat: lat,
        lng: lng,
        radiusMeters: CoolRouteMap.nearbyRadiusMeters,
      );
    } catch (_) {
      spots = const [];
    }
    if (!mounted) return;
    setState(() {
      _coolSpots = spots.isNotEmpty ? spots : DummyData.coolSpots;
      // Drop a stale focus that's no longer in the refreshed list.
      if (_focusedSpot != null && !_coolSpots.contains(_focusedSpot)) {
        _focusedSpot = null;
      }
      _loadingSpots = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _recenter() {
    if (_userLocation == null) {
      _resolveLocation();
    } else {
      setState(() => _recenterTick++);
    }
  }

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  // Jumps to a search result: switches to the matching tab, then zooms the map
  // and opens that place's popup/detail.
  void _onSearchHit(_SearchHit hit) {
    FocusScope.of(context).unfocus();
    _clearSearch();
    if (hit.spot != null) {
      if (!_coolSpotsMode) {
        setState(() {
          _coolSpotsMode = true;
          _selectedZone = null;
          _selectedTree = null;
        });
      }
      _showSpotDetail(hit.spot!);
    } else if (hit.zone != null) {
      setState(() {
        _coolSpotsMode = false;
        _selectedTree = null;
        _selectedZone = hit.zone;
      });
      _zoomTo(_zoneLatLngFrom(hit.zone!, _reportAnchor));
    }
  }

  void _zoomTo(LatLng point) => setState(() {
        _focusLatLng = point;
        _focusTick++;
      });

  void _onZoneView(HotZoneReport zone) {
    setState(() => _selectedZone = zone);
    _zoomTo(_zoneLatLngFrom(zone, _reportAnchor));
  }

  // Drops a freshly reported, still-unverified pin onto the map immediately.
  void _addPendingCoolSpot(CoolSpot spot) {
    setState(() {
      _coolSpots = [spot, ..._coolSpots];
      _coolSpotsMode = true;
      _activeFilter = 'All';
    });
    _showSpotDetail(spot);
  }

  void _addPendingHotZone(HotZoneReport zone) {
    setState(() {
      _hotZones.insert(0, zone);
      _coolSpotsMode = false;
      _activeFilter = 'All';
      _selectedZone = zone;
    });
    if (zone.hasLatLng) _zoomTo(LatLng(zone.lat!, zone.lng!));
  }

  LatLng get _reportAnchor =>
      _userLocation ?? const LatLng(13.7563, 100.5018);

  void _openReportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportTypeSheet(
        onReportCoolSpot: () => _openReportForm(ReportSpotMode.coolSpot),
        onReportHotZone: () => _openReportForm(ReportSpotMode.hotZone),
      ),
    );
  }

  void _openReportForm(ReportSpotMode mode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSpotSheet(
        mode: mode,
        anchor: _reportAnchor,
        onCoolSpot: _addPendingCoolSpot,
        onHotZone: _addPendingHotZone,
      ),
    );
  }

  void _onMarkerTap(HotZoneReport r) => setState(() => _selectedZone = r);
  void _onTreeTap(TreePin pin) => setState(() {
    _selectedTree = pin;
    _selectedZone = null;
  });
  void _onDismiss() => setState(() {
    _selectedZone = null;
    _selectedTree = null;
  });
  void _onFilterTap(String f) => setState(() {
    _activeFilter = f;
    if (f != _treesFilter) _selectedTree = null;
  });
  void _onModeToggle(bool coolSpots) => setState(() {
    _coolSpotsMode = coolSpots;
    _selectedZone = null;
    _selectedTree = null;
    _focusedSpot = null;
    _activeFilter = 'All';
  });

  void _showSpotDetail(CoolSpot spot) {
    // Center/highlight the spot on the map.
    setState(() => _focusedSpot = spot);
    // On mobile the map is full-bleed behind a bottom sheet, so also surface
    // the spot's details there. On web the side panel + map focus is enough.
    final isWide = MediaQuery.sizeOf(context).width > 800;
    if (!isWide) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SpotDetailSheet(spot: spot),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    final screenH = MediaQuery.sizeOf(context).height;
    final sheetH = screenH * 0.65;
    final spotPanelH = screenH * 0.48;
    final zonesListVisible =
        !_coolSpotsMode && _selectedZone == null && _selectedTree == null;

    final mapWidget = CoolRouteMap(
      hotZones: _coolSpotsMode ? const [] : _visibleZones,
      coolSpots: _coolSpotsMode ? _visibleSpots : const [],
      treePins: _visibleTrees,
      height: double.infinity,
      borderRadius: 0,
      onHotZoneTap: _coolSpotsMode ? null : _onMarkerTap,
      onTreePinTap: _showTrees ? _onTreeTap : null,
      onCoolSpotTap: _showSpotDetail,
      onMapTap: _onDismiss,
      focusedSpot: _coolSpotsMode ? _focusedSpot : null,
      focusLatLng: _focusLatLng,
      focusTick: _focusTick,
      userLocation: _userLocation,
      recenterTick: _recenterTick,
    );

    final mapStack = Stack(
      fit: StackFit.expand,
      children: [
        mapWidget,
        // Search + mode toggle column
        Positioned(
          top: AppTheme.spaceMD,
          left: AppTheme.spaceMD,
          right: AppTheme.spaceMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchField(
                controller: _searchCtrl,
                coolSpotsMode: _coolSpotsMode,
                onChanged: _onQueryChanged,
                onClear: _clearSearch,
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _ModeToggle(isCoolSpots: _coolSpotsMode, onToggle: _onModeToggle),
            ],
          ),
        ),
        // Context filter chips
        Positioned(
          top: AppTheme.spaceMD + 48 + AppTheme.spaceSM + 36 + AppTheme.spaceSM,
          left: 0,
          right: 0,
          child: _FloatingFilterBar(
            filters: _filters,
            active: _activeFilter,
            onSelect: _onFilterTap,
          ),
        ),
        if (isWide)
          Positioned(
            right: AppTheme.spaceMD,
            bottom: AppTheme.spaceMD,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _LocateFab(onPressed: _recenter, busy: _locating),
                const SizedBox(height: AppTheme.spaceSM),
                _MapActionButtons(onReport: _openReportSheet),
              ],
            ),
          ),
        // Live search results dropdown — last so it sits above chips/toggle.
        if (_query.trim().isNotEmpty)
          Positioned(
            top: AppTheme.spaceMD + 48 + 4,
            left: AppTheme.spaceMD,
            right: AppTheme.spaceMD,
            child: _SearchResults(hits: _searchResults, onSelect: _onSearchHit),
          ),
      ],
    );

    // ── Web layout ────────────────────────────────────────────────────────────
    if (isWide) {
      return Row(
        children: [
          Expanded(child: mapStack),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              child: child,
            ),
            child: _coolSpotsMode
                ? _CoolSpotsSidePanel(
                    key: const ValueKey('spots'),
                    spots: _visibleSpots,
                    loading: _loadingSpots,
                    onSpotView: _showSpotDetail,
                  )
                : _selectedZone != null
                ? HotZoneSidePanel(
                    key: ValueKey(_selectedZone!.title),
                    report: _selectedZone!,
                    nearbyReports: _nearby,
                    onClose: _onDismiss,
                  )
                : _selectedTree != null
                ? _TreePinSidePanel(
                    key: ValueKey(_selectedTree!.title),
                    pin: _selectedTree!,
                    onClose: _onDismiss,
                  )
                : _ZonesSidePanel(
                    key: const ValueKey('zones'),
                    zones: _visibleZones,
                    trees: _visibleTrees,
                    showTrees: _showTrees,
                    userLocation: _userLocation,
                    onZoneView: _onZoneView,
                    onTreeView: _onTreeTap,
                  ),
          ),
        ],
      );
    }

    // ── Mobile layout ─────────────────────────────────────────────────────────
    return Stack(
      fit: StackFit.expand,
      children: [
        mapStack,
        // Hot zone sheet
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: (!_coolSpotsMode && _selectedZone != null)
              ? 0
              : -(sheetH + 32),
          child: IgnorePointer(
            ignoring: _coolSpotsMode || _selectedZone == null,
            child: HotZoneBottomSheet(
              report: _selectedZone ?? DummyData.hotZones.first,
              nearbyReports: _nearby,
              onClose: _onDismiss,
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: (!_coolSpotsMode && _selectedTree != null)
              ? 0
              : -(sheetH + 32),
          child: IgnorePointer(
            ignoring: _coolSpotsMode || _selectedTree == null,
            child: _TreePinBottomSheet(
              pin: _selectedTree ?? DummyTreePins.pins.first,
              onClose: _onDismiss,
            ),
          ),
        ),
        // Cool spots list panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: _coolSpotsMode ? 0 : -(spotPanelH + 32),
          child: IgnorePointer(
            ignoring: !_coolSpotsMode,
            child: _CoolSpotsListPanel(
              maxHeight: spotPanelH,
              spots: _visibleSpots,
              loading: _loadingSpots,
              onSpotView: _showSpotDetail,
            ),
          ),
        ),
        // Hot zone / tree list panel (hot mode, nothing selected)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: zonesListVisible ? 0 : -(spotPanelH + 32),
          child: IgnorePointer(
            ignoring: !zonesListVisible,
            child: _ZonesListPanel(
              maxHeight: spotPanelH,
              zones: _visibleZones,
              trees: _visibleTrees,
              showTrees: _showTrees,
              userLocation: _userLocation,
              onZoneView: _onZoneView,
              onTreeView: _onTreeTap,
            ),
          ),
        ),
        // Report FAB — hidden in cool spots mode
        if (!_coolSpotsMode)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: AppTheme.spaceMD,
            bottom: (_selectedZone != null || _selectedTree != null)
                ? sheetH + AppTheme.spaceMD
                : zonesListVisible
                    ? spotPanelH + AppTheme.spaceMD
                    : AppTheme.spaceLG,
            child: _MapActionButtons(onReport: _openReportSheet),
          ),
        // Locate button — always available, on the opposite side of the FAB.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: AppTheme.spaceMD,
          bottom: _coolSpotsMode
              ? spotPanelH + AppTheme.spaceMD
              : (_selectedZone != null || _selectedTree != null)
                  ? sheetH + AppTheme.spaceMD
                  : zonesListVisible
                      ? spotPanelH + AppTheme.spaceMD
                      : AppTheme.spaceLG,
          child: _LocateFab(onPressed: _recenter, busy: _locating),
        ),
      ],
    );
  }
}

// ── Locate (my location) button ───────────────────────────────────────────────

class _LocateFab extends StatelessWidget {
  const _LocateFab({required this.onPressed, required this.busy});

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'map-locate-fab',
      backgroundColor: AppTheme.bgCard,
      foregroundColor: AppTheme.primary,
      elevation: 0,
      tooltip: 'My location',
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
    );
  }
}

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isCoolSpots, required this.onToggle});

  final bool isCoolSpots;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ToggleOption(
                icon: Icons.local_fire_department_outlined,
                label: 'Hot Zones',
                selected: !isCoolSpots,
                onTap: () => onToggle(false),
                selectedColor: AppTheme.riskExtreme,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 0.5,
              color: AppTheme.borderLight,
            ),
            Expanded(
              child: _ToggleOption(
                icon: Icons.ac_unit,
                label: 'Cool Spots',
                selected: isCoolSpots,
                onTap: () => onToggle(true),
                selectedColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : AppTheme.textHint;
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: selected
            ? selectedColor.withValues(alpha: .08)
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSM + 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppTheme.spaceXS + 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cool spots list panel (mobile bottom sheet) ───────────────────────────────

class _CoolSpotsListPanel extends StatelessWidget {
  const _CoolSpotsListPanel({
    required this.maxHeight,
    required this.spots,
    required this.loading,
    required this.onSpotView,
  });

  final double maxHeight;
  final List<CoolSpot> spots;
  final bool loading;
  final ValueChanged<CoolSpot> onSpotView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.borderMid,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: const SizedBox(width: 32, height: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceXS,
              ),
              child: Row(
                children: [
                  Text('Cool spots nearby', style: tt.labelLarge),
                  const Spacer(),
                  Text(
                    loading ? 'Finding…' : '${spots.length} found',
                    style: tt.bodySmall!.copyWith(color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _CoolSpotsList(
                spots: spots,
                loading: loading,
                onSpotView: onSpotView,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD,
                  AppTheme.spaceXS,
                  AppTheme.spaceMD,
                  AppTheme.spaceLG,
                ),
                shrinkWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cool spots side panel (web) ───────────────────────────────────────────────

class _CoolSpotsSidePanel extends StatelessWidget {
  const _CoolSpotsSidePanel({
    super.key,
    required this.spots,
    required this.loading,
    required this.onSpotView,
  });

  final List<CoolSpot> spots;
  final bool loading;
  final ValueChanged<CoolSpot> onSpotView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(
            left: BorderSide(color: AppTheme.borderLight, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                AppTheme.spaceMD,
                AppTheme.spaceMD,
                AppTheme.spaceSM,
              ),
              child: Row(
                children: [
                  Text('Cool spots nearby', style: tt.labelLarge),
                  const Spacer(),
                  Text(
                    loading ? 'Finding…' : '${spots.length} found',
                    style: tt.bodySmall!.copyWith(color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _CoolSpotsList(
                spots: spots,
                loading: loading,
                onSpotView: onSpotView,
                padding: const EdgeInsets.all(AppTheme.spaceMD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared list body: loading spinner, empty state, or the cool-spot cards.
class _CoolSpotsList extends StatelessWidget {
  const _CoolSpotsList({
    required this.spots,
    required this.loading,
    required this.onSpotView,
    required this.padding,
    this.shrinkWrap = false,
  });

  final List<CoolSpot> spots;
  final bool loading;
  final ValueChanged<CoolSpot> onSpotView;
  final EdgeInsets padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (loading && spots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spaceLG),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (spots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Text(
            'No cool spots match this filter nearby.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppTheme.textHint,
                ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: spots.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceSM),
      itemBuilder: (_, i) => CoolSpotCard(spot: spots[i], onView: onSpotView),
    );
  }
}

// ── Spot detail sheet ─────────────────────────────────────────────────────────

class _SpotDetailSheet extends StatelessWidget {
  const _SpotDetailSheet({required this.spot});

  final CoolSpot spot;

  Color get _iconColor => switch (spot.type) {
    'Air-conditioned' || 'Water' => AppTheme.markerBlue,
    'Shade' => AppTheme.riskNone,
    _ => AppTheme.primary,
  };

  Color get _iconBg => switch (spot.type) {
    'Air-conditioned' || 'Water' => AppTheme.spotBgBlue,
    'Shade' => AppTheme.riskLowBg,
    _ => AppTheme.primaryLight,
  };

  IconData get _icon => switch (spot.type) {
    'Air-conditioned' => Icons.ac_unit,
    'Water' => Icons.water_drop_outlined,
    'Shade' => Icons.park_outlined,
    _ => Icons.store_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        10,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.borderMid,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: const SizedBox(width: 32, height: 4),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    child: Icon(_icon, color: _iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spot.name, style: tt.headlineMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${spot.displayCategory} · ${spot.distance} away',
                        style: tt.bodySmall!.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(spot.amenity, style: tt.bodyMedium),
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                _StatusPill(spot.openStatus),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Text(
                    spot.verifiedBy > 0
                        ? 'Verified by ${spot.verifiedBy} users'
                        : 'Mapped on ${spot.source}',
                    style: tt.bodySmall!.copyWith(color: AppTheme.textHint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Use as cooling stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  Color get _bg => switch (status) {
        'Open' || 'Working' => AppTheme.statusOpenBg,
        'Available' => AppTheme.primaryLight,
        'Closed' => AppTheme.statusClosedBg,
        'Pending' => AppTheme.markerOrange.withValues(alpha: .14),
        _ => AppTheme.statusOpenBg,
      };

  Color get _fg => switch (status) {
        'Open' || 'Working' => AppTheme.statusOpen,
        'Available' => AppTheme.primaryDark,
        'Closed' => AppTheme.statusClosed,
        'Pending' => AppTheme.markerOrange,
        _ => AppTheme.statusOpen,
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          status,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: _fg),
        ),
      ),
    );
  }
}

// ── Hot zone / tree list panels ───────────────────────────────────────────────

String? _zoneDistanceText(HotZoneReport zone, LatLng? user) {
  if (user == null) return null;
  final eff = _zoneLatLngFrom(zone, user);
  final m = Geolocator.distanceBetween(
      user.latitude, user.longitude, eff.latitude, eff.longitude);
  return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}

// A hot zone's effective coordinate: its real lat/lng when set, otherwise the
// seeded layout offset projected around [anchor] so demo zones cluster near the
// user (matching how the map paints them). Spans mirror CoolRouteMap.
LatLng _zoneLatLngFrom(HotZoneReport zone, LatLng anchor) {
  if (zone.hasLatLng) return LatLng(zone.lat!, zone.lng!);
  return LatLng(
    anchor.latitude + (0.5 - zone.y) * 0.018,
    anchor.longitude + (zone.x - 0.5) * 0.022,
  );
}

// Mobile bottom panel.
class _ZonesListPanel extends StatelessWidget {
  const _ZonesListPanel({
    required this.maxHeight,
    required this.zones,
    required this.trees,
    required this.showTrees,
    required this.userLocation,
    required this.onZoneView,
    required this.onTreeView,
  });

  final double maxHeight;
  final List<HotZoneReport> zones;
  final List<TreePin> trees;
  final bool showTrees;
  final LatLng? userLocation;
  final ValueChanged<HotZoneReport> onZoneView;
  final ValueChanged<TreePin> onTreeView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final count = showTrees ? trees.length : zones.length;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.borderMid,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: const SizedBox(width: 32, height: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceXS,
              ),
              child: Row(
                children: [
                  Text(showTrees ? 'Trees nearby' : 'Hot zones nearby',
                      style: tt.labelLarge),
                  const Spacer(),
                  Text('$count found',
                      style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
                ],
              ),
            ),
            Flexible(
              child: _ZonesList(
                zones: zones,
                trees: trees,
                showTrees: showTrees,
                userLocation: userLocation,
                onZoneView: onZoneView,
                onTreeView: onTreeView,
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD,
                  AppTheme.spaceXS,
                  AppTheme.spaceMD,
                  AppTheme.spaceLG,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Web side panel.
class _ZonesSidePanel extends StatelessWidget {
  const _ZonesSidePanel({
    super.key,
    required this.zones,
    required this.trees,
    required this.showTrees,
    required this.userLocation,
    required this.onZoneView,
    required this.onTreeView,
  });

  final List<HotZoneReport> zones;
  final List<TreePin> trees;
  final bool showTrees;
  final LatLng? userLocation;
  final ValueChanged<HotZoneReport> onZoneView;
  final ValueChanged<TreePin> onTreeView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final count = showTrees ? trees.length : zones.length;
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(
            left: BorderSide(color: AppTheme.borderLight, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                AppTheme.spaceMD,
                AppTheme.spaceMD,
                AppTheme.spaceSM,
              ),
              child: Row(
                children: [
                  Text(showTrees ? 'Trees nearby' : 'Hot zones nearby',
                      style: tt.labelLarge),
                  const Spacer(),
                  Text('$count found',
                      style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _ZonesList(
                zones: zones,
                trees: trees,
                showTrees: showTrees,
                userLocation: userLocation,
                onZoneView: onZoneView,
                onTreeView: onTreeView,
                padding: const EdgeInsets.all(AppTheme.spaceMD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesList extends StatelessWidget {
  const _ZonesList({
    required this.zones,
    required this.trees,
    required this.showTrees,
    required this.userLocation,
    required this.onZoneView,
    required this.onTreeView,
    required this.padding,
    this.shrinkWrap = false,
  });

  final List<HotZoneReport> zones;
  final List<TreePin> trees;
  final bool showTrees;
  final LatLng? userLocation;
  final ValueChanged<HotZoneReport> onZoneView;
  final ValueChanged<TreePin> onTreeView;
  final EdgeInsets padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final empty = showTrees ? trees.isEmpty : zones.isEmpty;
    if (empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Text(
            'No results found.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: AppTheme.textHint),
          ),
        ),
      );
    }
    if (showTrees) {
      return ListView.separated(
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: trees.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceSM),
        itemBuilder: (_, i) =>
            _TreeRow(pin: trees[i], onView: () => onTreeView(trees[i])),
      );
    }
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: zones.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceSM),
      itemBuilder: (_, i) => _HotZoneRow(
        zone: zones[i],
        distance: _zoneDistanceText(zones[i], userLocation),
        onView: () => onZoneView(zones[i]),
      ),
    );
  }
}

class _HotZoneRow extends StatelessWidget {
  const _HotZoneRow({
    required this.zone,
    required this.distance,
    required this.onView,
  });

  final HotZoneReport zone;
  final String? distance;
  final VoidCallback onView;

  Color get _color => switch (zone.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtreme,
        HeatRisk.medium => AppTheme.markerOrange,
        HeatRisk.low => AppTheme.riskNone,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final meta = [
      ?distance,
      '${zone.verifications} verified',
    ].join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSM + 4),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.local_fire_department,
                    color: _color, size: 20),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.title,
                      style: tt.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(zone.category, style: tt.bodySmall),
                  const SizedBox(height: AppTheme.spaceXS + 2),
                  Text(meta,
                      style: tt.labelSmall!.copyWith(color: AppTheme.textHint)),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 2),
            OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(52, 34),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM + 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({required this.pin, required this.onView});

  final TreePin pin;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSM + 4),
        child: Row(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.markerTree,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.park_outlined,
                    color: AppTheme.textOnDark, size: 20),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pin.title,
                      style: tt.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(pin.locationName, style: tt.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 2),
            OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(52, 34),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM + 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Interactive search ────────────────────────────────────────────────────────

// A single search match — either a cool spot or a hot zone.
class _SearchHit {
  const _SearchHit._({this.spot, this.zone});
  factory _SearchHit.spot(CoolSpot spot) => _SearchHit._(spot: spot);
  factory _SearchHit.zone(HotZoneReport zone) => _SearchHit._(zone: zone);

  final CoolSpot? spot;
  final HotZoneReport? zone;

  String get title => spot?.name ?? zone!.title;
  String get subtitle =>
      spot != null ? '${spot!.displayCategory} · ${spot!.distance}' : zone!.location;
  IconData get icon => spot != null
      ? switch (spot!.type) {
          'Water' => Icons.water_drop_outlined,
          'Shade' => Icons.park_outlined,
          'Air-conditioned' => Icons.ac_unit,
          _ => Icons.store_outlined,
        }
      : Icons.local_fire_department_outlined;
  Color get color =>
      spot != null ? AppTheme.primary : AppTheme.riskExtreme;
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.coolSpotsMode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool coolSpotsMode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppTheme.textHint),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: coolSpotsMode
                      ? 'Search water, shade, air conditioning…'
                      : 'Search hot zones, places, stations…',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: AppTheme.textHint),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18, color: AppTheme.textHint),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.hits, required this.onSelect});

  final List<_SearchHit> hits;
  final ValueChanged<_SearchHit> onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      color: AppTheme.bgCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: hits.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Row(
                  children: [
                    const Icon(Icons.search_off,
                        size: 18, color: AppTheme.textHint),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text('No results found',
                        style: tt.bodyMedium!
                            .copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
                itemCount: hits.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 52),
                itemBuilder: (_, i) {
                  final hit = hits[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: hit.color.withValues(alpha: .12),
                      child: Icon(hit.icon, size: 16, color: hit.color),
                    ),
                    title: Text(hit.title,
                        style: tt.bodyLarge, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(hit.subtitle,
                        style: tt.bodySmall, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => onSelect(hit),
                  );
                },
              ),
      ),
    );
  }
}

// ── Floating filter chips ─────────────────────────────────────────────────────

class _FloatingFilterBar extends StatelessWidget {
  const _FloatingFilterBar({
    required this.filters,
    required this.active,
    required this.onSelect,
  });

  final List<String> filters;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.spaceSM),
        itemBuilder: (_, i) => _MapChip(
          label: filters[i],
          selected: filters[i] == active,
          onTap: () => onSelect(filters[i]),
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: selected
              ? null
              : Border.all(color: AppTheme.borderLight, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD - 2,
            vertical: AppTheme.spaceXS + 2,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: selected ? AppTheme.textOnDark : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Report FAB ────────────────────────────────────────────────────────────────

class _MapActionButtons extends StatelessWidget {
  const _MapActionButtons({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'map-report-fab',
      backgroundColor: AppTheme.bgCard,
      foregroundColor: AppTheme.primary,
      elevation: 0,
      onPressed: onReport,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Report'),
    );
  }
}

class _ReportTypeSheet extends StatelessWidget {
  const _ReportTypeSheet({
    required this.onReportCoolSpot,
    required this.onReportHotZone,
  });

  final VoidCallback onReportCoolSpot;
  final VoidCallback onReportHotZone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD,
            10,
            AppTheme.spaceMD,
            AppTheme.spaceLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.borderMid,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: const SizedBox(width: 32, height: 4),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Create a community report',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Choose what you want to add to the map.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              _ReportTypeTile(
                icon: Icons.local_fire_department_outlined,
                iconColor: AppTheme.riskExtreme,
                title: 'Report Hot Zone',
                subtitle: 'Mark unsafe heat, no shade, or broken water.',
                onTap: () {
                  Navigator.of(context).pop();
                  onReportHotZone();
                },
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _ReportTypeTile(
                icon: Icons.ac_unit,
                iconColor: AppTheme.primary,
                title: 'Suggest Cool Spot',
                subtitle: 'Add shade, water, or indoor cooling locations.',
                onTap: () {
                  Navigator.of(context).pop();
                  onReportCoolSpot();
                },
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _ReportTypeTile(
                icon: Icons.park_outlined,
                iconColor: AppTheme.markerTree,
                title: 'Plant a Tree',
                subtitle: 'Post a tree planting contribution pin.',
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _PlantTreeSheet(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTypeTile extends StatelessWidget {
  const _ReportTypeTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.borderLight, width: .5),
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceSM),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreePinBottomSheet extends StatelessWidget {
  const _TreePinBottomSheet({required this.pin, this.onClose});

  final TreePin pin;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.65;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                10,
                AppTheme.spaceXS,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.borderMid,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: const SizedBox(width: 32, height: 4),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.textHint,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD,
                  AppTheme.spaceXS,
                  AppTheme.spaceMD,
                  AppTheme.spaceLG,
                ),
                child: _TreePinPanelContent(pin: pin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreePinSidePanel extends StatelessWidget {
  const _TreePinSidePanel({super.key, required this.pin, this.onClose});

  final TreePin pin;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(
            left: BorderSide(color: AppTheme.borderLight, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                AppTheme.spaceSM,
                AppTheme.spaceXS,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tree details',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.textHint,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD,
                  AppTheme.spaceMD,
                  AppTheme.spaceMD,
                  AppTheme.spaceLG,
                ),
                child: _TreePinPanelContent(pin: pin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreePinPanelContent extends StatelessWidget {
  const _TreePinPanelContent({required this.pin});

  final TreePin pin;

  void _confirm(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppTheme.markerTree,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppTheme.spaceSM),
                child: Icon(
                  Icons.park_outlined,
                  color: AppTheme.textOnDark,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(child: Text(pin.title, style: tt.headlineMedium)),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(pin.locationName, style: tt.bodySmall)),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM + 4),
        Text(
          'Planted ${pin.datePlanted} by ${pin.plantedBy}',
          style: tt.bodySmall,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        Text(pin.description, style: tt.bodyMedium),
        const SizedBox(height: AppTheme.spaceMD),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _confirm(context, 'Thanks for watering this tree!'),
                child: const Text('I watered it 💧'),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _confirm(context, 'Growth status noted.'),
                child: const Text('Still growing 🌱'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _confirm(context, 'Tree pin centered on map.'),
            child: const Text('View on map'),
          ),
        ),
      ],
    );
  }
}

class _PlantTreeSheet extends StatefulWidget {
  const _PlantTreeSheet();

  @override
  State<_PlantTreeSheet> createState() => _PlantTreeSheetState();
}

class _PlantTreeSheetState extends State<_PlantTreeSheet> {
  final _formKey = GlobalKey<FormState>();
  Offset _pin = const Offset(.50, .44);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD,
            10,
            AppTheme.spaceMD,
            AppTheme.spaceLG,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.borderMid,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: const SizedBox(width: 32, height: 4),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  'Plant a Tree',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Tree type'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location note'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note or description',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                LocationPinPicker(
                  label: 'Pin exact tree location',
                  pinColor: AppTheme.markerTree,
                  pinIcon: Icons.park_outlined,
                  initialX: _pin.dx,
                  initialY: _pin.dy,
                  onChanged: (pin) => _pin = pin,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final placedPin = _pin;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Your tree pin has been added! 🌱 Pin saved near ${placedPin.dx.toStringAsFixed(2)}, ${placedPin.dy.toStringAsFixed(2)}.',
        ),
      ),
    );
  }
}
