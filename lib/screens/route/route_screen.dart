import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../models/heat_risk.dart';
import '../../models/hot_zone_report.dart';
import '../../models/route_option.dart';
import '../../models/user_profile.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/location_service.dart';
import '../../services/report_refresh.dart';
import '../../services/report_service.dart';
import '../../services/route_planner.dart';
import '../../services/routing_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/route_map.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    this.initialSelectedRouteName,
    this.initialDestination,
  });

  final String? initialSelectedRouteName;

  /// When set (e.g. reopening a saved route), the screen plans to this
  /// destination as soon as the start location resolves.
  final LatLng? initialDestination;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final RoutingService _routing = RoutingService();

  LatLng? _start;
  bool _startIsReal = false;
  bool _startIsCustom = false; // true when overridden from GPS
  LatLng? _destination;

  List<HotZoneReport> _hotZones = const [];
  List<GeoResult> _startResults = const [];
  List<GeoResult> _searchResults = const [];
  List<RouteOption> _routes = const [];
  RouteOption? _selected;

  bool _locating = true;
  bool _startSearching = false;
  bool _searching = false;
  bool _loadingRoutes = false;

  // Which field the next map tap will apply to.
  bool _editingStart = false;

  @override
  void initState() {
    super.initState();
    _destination = widget.initialDestination;
    final name = widget.initialSelectedRouteName;
    if (name != null) _searchCtrl.text = name;
    _resolveStart();
    _loadHotZones();
    // A saved route with no stored coordinates (legacy) can't be re-planned.
    if (name != null && widget.initialDestination == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set a destination to plan "$name".')),
        );
      });
    }
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveStart() async {
    final result = await LocationService().currentLocation();
    if (!mounted) return;
    setState(() {
      _start = LatLng(result.latitude, result.longitude);
      _startIsReal = result.isReal;
      _locating = false;
    });
    // Reopened a saved route → plan it now that we have a start point.
    if (_destination != null && _routes.isEmpty) _findRoutes();
  }

  Future<void> _runStartSearch() async {
    final query = _startCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _startResults = const []);
      return;
    }
    if (!RoutingService.isConfigured) {
      _showKeyNeeded();
      return;
    }
    setState(() => _startSearching = true);
    final results = await _routing.geocode(
      query,
      focusLat: _start?.latitude,
      focusLng: _start?.longitude,
    );
    if (!mounted) return;
    setState(() {
      _startResults = results;
      _startSearching = false;
    });
  }

  void _pickStartResult(GeoResult result) {
    FocusScope.of(context).unfocus();
    _startCtrl.text = result.label;
    setState(() {
      _start = result.latLng;
      _startIsReal = false;
      _startIsCustom = true;
      _startResults = const [];
      _editingStart = false;
    });
    _findRoutes();
  }

  Future<void> _resetStartToLocation() async {
    FocusScope.of(context).unfocus();
    _startCtrl.clear();
    setState(() {
      _start = null;
      _startIsReal = false;
      _startIsCustom = false;
      _locating = true;
      _routes = const [];
      _selected = null;
      _editingStart = false;
    });
    await _resolveStart();
  }

  void _swapStartDestination() {
    final swappedStart = _destination;
    final swappedStartText = _searchCtrl.text;
    final swappedDest = _start;
    final swappedDestText = _startCtrl.text;
    _startCtrl.text = swappedStartText;
    _searchCtrl.text = swappedDestText;
    setState(() {
      _start = swappedStart;
      _startIsReal = false;
      _startIsCustom = swappedStart != null;
      _destination = swappedDest;
      _routes = const [];
      _selected = null;
    });
    if (_start != null && _destination != null) _findRoutes();
  }

  Future<void> _loadHotZones() async {
    final zones = await ReportService().getHotZoneReports();
    if (!mounted) return;
    setState(() => _hotZones = zones);
  }

  Future<void> _runSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    if (!RoutingService.isConfigured) {
      _showKeyNeeded();
      return;
    }
    setState(() => _searching = true);
    final results = await _routing.geocode(
      query,
      focusLat: _start?.latitude,
      focusLng: _start?.longitude,
    );
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching places found.')),
      );
    }
  }

  void _pickResult(GeoResult result) {
    FocusScope.of(context).unfocus();
    _searchCtrl.text = result.label;
    setState(() {
      _destination = result.latLng;
      _searchResults = const [];
    });
    _findRoutes();
  }

  void _onMapTap(LatLng point) {
    FocusScope.of(context).unfocus();
    if (_editingStart) {
      _startCtrl.text = 'Dropped pin';
      setState(() {
        _start = point;
        _startIsReal = false;
        _startIsCustom = true;
        _startResults = const [];
        _editingStart = false;
      });
    } else {
      _searchCtrl.text = 'Dropped pin';
      setState(() {
        _destination = point;
        _searchResults = const [];
      });
    }
    _findRoutes();
  }

  void _clearDestination() {
    _searchCtrl.clear();
    setState(() {
      _destination = null;
      _routes = const [];
      _selected = null;
      _searchResults = const [];
    });
  }

  Future<void> _findRoutes() async {
    final start = _start;
    final destination = _destination;
    if (start == null || destination == null) return;
    if (!RoutingService.isConfigured) {
      _showKeyNeeded();
      return;
    }
    setState(() {
      _loadingRoutes = true;
      _routes = const [];
      _selected = null;
    });
    final raw = await _routing.walkingRoutes(start, destination);
    final options = RoutePlanner.score(raw, _hotZones);
    if (!mounted) return;
    setState(() {
      _routes = options;
      _selected = options.isNotEmpty ? options.first : null;
      _loadingRoutes = false;
    });
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a walking route there.')),
      );
    }
  }

  void _selectRoute(RouteOption route) => setState(() => _selected = route);

  void _startRoute() {
    final route = _selected;
    if (route == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation started on the ${route.name.toLowerCase()}.')),
    );
  }

  String? _currentUid() {
    try {
      return FirebaseAuthService().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // Saves the selected route to the user's profile (Profile → Saved routes),
  // including the destination so it can be re-planned when reopened.
  Future<void> _saveRoute() async {
    final route = _selected;
    final destination = _destination;
    if (route == null || destination == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final uid = _currentUid();
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to save routes.')),
      );
      return;
    }
    final dest = _searchCtrl.text.trim();
    final name =
        '${route.name} to ${dest.isEmpty ? 'destination' : dest} · ${route.duration}';
    messenger.showSnackBar(
      const SnackBar(content: Text('Saved to your profile.')),
    );
    try {
      await UserProfileService().addSavedRoute(
        uid,
        SavedRoute(
          name: name,
          destLat: destination.latitude,
          destLng: destination.longitude,
        ),
      );
      notifyProfileChanged();
    } catch (e) {
      debugPrint('VERIFY: save route error: $e');
    }
  }

  void _focusStart() => setState(() {
        _editingStart = true;
        _searchResults = const [];
      });

  void _focusDestination() => setState(() {
        _editingStart = false;
        _startResults = const [];
      });

  void _showKeyNeeded() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add ORS_API_KEY to .env to enable routing.')),
    );
  }

  List<List<LatLng>> get _alternatePoints => [
        for (final r in _routes)
          if (r != _selected) r.points,
      ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 850;

    final map = RouteMap(
      height: double.infinity,
      borderRadius: 0,
      start: _start,
      destination: _destination,
      routePoints: _selected?.points ?? const [],
      alternatePoints: _alternatePoints,
      hotZones: _hotZones,
      onTap: _onMapTap,
    );

    if (wide) {
      return Row(
        children: [
          SizedBox(width: 392, child: _Sidebar(state: this)),
          Expanded(child: map),
        ],
      );
    }

    // Mobile: map hero with a floating directions bar and a bottom route sheet.
    return Stack(
      fit: StackFit.expand,
      children: [
        map,
        Positioned(
          top: AppTheme.spaceSM,
          left: AppTheme.spaceSM,
          right: AppTheme.spaceSM,
          child: PointerInterceptor(
            child: _DirectionsBar(state: this, elevated: true),
          ),
        ),
        if (_destination != null)
          Positioned(
            left: AppTheme.spaceSM,
            right: AppTheme.spaceSM,
            bottom: AppTheme.spaceSM,
            child: PointerInterceptor(
              child: _RoutePanel(state: this, asSheet: true),
            ),
          ),
      ],
    );
  }
}

// ── Web sidebar ───────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});

  final _RouteScreenState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(right: BorderSide(color: AppTheme.borderLight, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceSM),
            child: _DirectionsBar(state: state, elevated: false),
          ),
          const Divider(height: 1),
          Expanded(child: _RoutePanel(state: state, asSheet: false)),
        ],
      ),
    );
  }
}

// ── Directions input bar (start + destination + results) ──────────────────────

class _DirectionsBar extends StatelessWidget {
  const _DirectionsBar({required this.state, required this.elevated});

  final _RouteScreenState state;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final s = state;

    // The active results list — start results when start field is focused,
    // destination results otherwise.
    final activeResults =
        s._editingStart ? s._startResults : s._searchResults;
    final activeSearching = s._editingStart ? s._startSearching : s._searching;

    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Start row ──────────────────────────────────────────────────────
        Row(
          children: [
            const _Dot(color: AppTheme.markerBlue),
            const SizedBox(width: AppTheme.spaceSM + 2),
            Expanded(
              child: TextField(
                controller: s._startCtrl,
                textInputAction: TextInputAction.search,
                onTap: s._focusStart,
                onChanged: (_) => s._runStartSearch(),
                onSubmitted: (_) => s._runStartSearch(),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: s._locating
                      ? 'Locating…'
                      : s._startIsReal
                          ? 'Your location'
                          : 'Starting point',
                  hintStyle: tt.bodyMedium!.copyWith(
                    color: !s._startIsCustom && !s._startIsReal
                        ? AppTheme.riskMedium
                        : AppTheme.textHint,
                  ),
                ),
              ),
            ),
            // GPS reset — appears only when start is overridden
            if (s._startIsCustom)
              IconButton(
                icon: const Icon(Icons.my_location, size: 18),
                color: AppTheme.primary,
                tooltip: 'Use my location',
                onPressed: s._resetStartToLocation,
                visualDensity: VisualDensity.compact,
              )
            else if (!s._locating)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.gps_fixed, size: 16, color: AppTheme.primary),
              ),
          ],
        ),
        // ── Swap button + dotted connector ─────────────────────────────────
        Row(
          children: [
            const SizedBox(width: 5),
            const _DottedConnector(),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              onTap: s._swapStartDestination,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.swap_vert, size: 18, color: AppTheme.textHint),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        // ── Destination row ────────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.place, size: 18, color: AppTheme.riskExtreme),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: TextField(
                controller: s._searchCtrl,
                textInputAction: TextInputAction.search,
                onTap: s._focusDestination,
                onSubmitted: (_) => s._runSearch(),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'Choose destination — search or tap map',
                ),
              ),
            ),
            if (activeSearching && !s._editingStart)
              const Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (s._destination != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.textHint,
                onPressed: s._clearDestination,
                visualDensity: VisualDensity.compact,
              )
            else
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                color: AppTheme.primary,
                onPressed: s._runSearch,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        // ── Search results (start or destination) ──────────────────────────
        if (activeResults.isNotEmpty) ...[
          const Divider(height: AppTheme.spaceMD),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final r in activeResults)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined,
                        size: 18, color: AppTheme.primary),
                    title: Text(r.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium),
                    onTap: () => s._editingStart
                        ? s._pickStartResult(r)
                        : s._pickResult(r),
                  ),
              ],
            ),
          ),
        ],
        // ── Tap-map hint when a field is active ────────────────────────────
        if (activeResults.isEmpty &&
            (s._editingStart
                ? s._startCtrl.text.isEmpty
                : s._searchCtrl.text.isEmpty)) ...[
          const SizedBox(height: AppTheme.spaceXS),
          Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 13, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                s._editingStart
                    ? 'Or tap the map to set your start point'
                    : 'Or tap the map to drop a destination pin',
                style:
                    tt.bodySmall!.copyWith(color: AppTheme.textHint),
              ),
            ],
          ),
        ],
        if (!RoutingService.isConfigured) ...[
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppTheme.riskMedium),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Add ORS_API_KEY to .env to enable routing.',
                    style:
                        tt.bodySmall!.copyWith(color: AppTheme.riskMedium)),
              ),
            ],
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM + 2),
      child: inner,
    );

    if (!elevated) return padded;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      shadowColor: const Color(0x22000000),
      color: AppTheme.bgCard,
      child: padded,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.bgCard, width: 2),
        ),
      );
}

class _DottedConnector extends StatelessWidget {
  const _DottedConnector();
  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          3,
          (_) => Container(
            width: 2,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 1),
            color: AppTheme.borderMid,
          ),
        ),
      );
}

// ── Route options panel (sidebar list / mobile bottom sheet) ──────────────────

class _RoutePanel extends StatelessWidget {
  const _RoutePanel({required this.state, required this.asSheet});

  final _RouteScreenState state;
  final bool asSheet;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final routes = state._routes;

    Widget body;
    if (state._loadingRoutes) {
      body = const Padding(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (routes.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: AppTheme.textHint),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: Text(
                state._destination != null
                    ? 'No routes found — try another destination.'
                    : 'Search a destination or tap the map to plan a heat-safe walk.',
                style: tt.bodySmall,
              ),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD, AppTheme.spaceSM + 2, AppTheme.spaceMD, AppTheme.spaceXS),
            child: Text('Heat-safe routes', style: tt.labelLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final r in routes)
                  _RouteRow(
                    route: r,
                    selected: r == state._selected,
                    onTap: () => state._selectRoute(r),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: state._selected == null ? null : state._saveRoute,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Save'),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: state._selected == null ? null : state._startRoute,
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Start'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!asSheet) {
      return SingleChildScrollView(child: body);
    }
    // Mobile bottom sheet styling.
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      shadowColor: const Color(0x33000000),
      color: AppTheme.bgCard,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 2),
              child: SizedBox(
                width: 32,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.borderMid,
                    borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusPill)),
                  ),
                ),
              ),
            ),
            Flexible(child: SingleChildScrollView(child: body)),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.route, required this.selected, required this.onTap});

  final RouteOption route;
  final bool selected;
  final VoidCallback onTap;

  Color get _accent => switch (route.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtreme,
        HeatRisk.medium => AppTheme.riskMedium,
        HeatRisk.low => AppTheme.riskNone,
      };

  bool get _isFastest => route.name == 'Fastest route';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hotCount = route.hotZonesNearby;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM + 2),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight.withValues(alpha: .5) : null,
          border: Border(
            left: BorderSide(
              color: selected ? AppTheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.alt_route, size: 18, color: _accent),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route name label
                  Text(route.name,
                      style: tt.labelSmall!.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 1),
                  // Duration + distance + badges row
                  Row(
                    children: [
                      Text(route.duration,
                          style: tt.headlineMedium!.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text(route.distance, style: tt.bodySmall),
                      const SizedBox(width: AppTheme.spaceSM),
                      if (route.badge != null) _Badge(label: route.badge!, color: AppTheme.primaryLight, textColor: AppTheme.primaryDark),
                      if (_isFastest) _Badge(label: 'Fastest', color: AppTheme.riskMediumBg, textColor: const Color(0xFF854F0B)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Hot-zone count pill
                  Row(
                    children: [
                      _HotZonePill(count: hotCount),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall!
                .copyWith(color: textColor)),
      ),
    );
  }
}

class _HotZonePill extends StatelessWidget {
  const _HotZonePill({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final isClean = count == 0;
    final bg = isClean ? AppTheme.riskLowBg : AppTheme.riskExtremeBg;
    final fg = isClean ? AppTheme.riskNone : AppTheme.riskExtreme;
    final label = isClean ? 'No hot zones' : '$count hot zone${count == 1 ? '' : 's'}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isClean ? Icons.check_circle_outline : Icons.local_fire_department,
                size: 11, color: fg),
            const SizedBox(width: 3),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
