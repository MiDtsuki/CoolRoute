import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/hot_zone_report.dart';
import '../../models/route_option.dart';
import '../../services/location_service.dart';
import '../../services/report_service.dart';
import '../../services/route_planner.dart';
import '../../services/routing_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/route_map.dart';
import '../../widgets/route_option_card.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, this.initialSelectedRouteName});

  final String? initialSelectedRouteName;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final RoutingService _routing = RoutingService();

  LatLng? _start;
  LatLng? _destination;
  String _destinationLabel = '';

  List<HotZoneReport> _hotZones = const [];
  List<GeoResult> _searchResults = const [];
  List<RouteOption> _routes = const [];
  RouteOption? _selected;

  bool _locating = true;
  bool _searching = false;
  bool _loadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _resolveStart();
    _loadHotZones();
    final name = widget.initialSelectedRouteName;
    if (name != null) {
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
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveStart() async {
    final result = await LocationService().currentLocation();
    if (!mounted) return;
    setState(() {
      _start = LatLng(result.latitude, result.longitude);
      _locating = false;
    });
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
      _destinationLabel = result.label;
      _searchResults = const [];
    });
    _findRoutes();
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _destination = point;
      _destinationLabel = 'Dropped pin';
      _searchResults = const [];
      _searchCtrl.text = 'Dropped pin';
    });
    _findRoutes();
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

  void _showKeyNeeded() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add ORS_API_KEY to .env to enable routing.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 850;
    final mapHeight =
        MediaQuery.sizeOf(context).height * (wide ? 0.55 : 0.36);

    final form = _FormPanel(
      controller: _searchCtrl,
      locating: _locating,
      searching: _searching,
      loadingRoutes: _loadingRoutes,
      results: _searchResults,
      destinationLabel: _destinationLabel,
      canFind: _start != null && _destination != null,
      onSearch: _runSearch,
      onPick: _pickResult,
      onFind: _findRoutes,
    );

    final map = RouteMap(
      height: mapHeight,
      start: _start,
      destination: _destination,
      routePoints: _selected?.points ?? const [],
      hotZones: _hotZones,
      onTap: _onMapTap,
    );

    final cards = _RouteCards(
      routes: _routes,
      selected: _selected,
      loading: _loadingRoutes,
      hasDestination: _destination != null,
      onSelect: _selectRoute,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 380,
                      child: Column(children: [form, const SizedBox(height: AppTheme.spaceMD), cards]),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(child: map),
                  ],
                )
              : Column(
                  children: [
                    form,
                    const SizedBox(height: AppTheme.spaceMD),
                    map,
                    const SizedBox(height: AppTheme.spaceMD),
                    cards,
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Form panel ──────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.controller,
    required this.locating,
    required this.searching,
    required this.loadingRoutes,
    required this.results,
    required this.destinationLabel,
    required this.canFind,
    required this.onSearch,
    required this.onPick,
    required this.onFind,
  });

  final TextEditingController controller;
  final bool locating;
  final bool searching;
  final bool loadingRoutes;
  final List<GeoResult> results;
  final String destinationLabel;
  final bool canFind;
  final VoidCallback onSearch;
  final ValueChanged<GeoResult> onPick;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Heat-safe route', style: tt.headlineMedium),
            const SizedBox(height: AppTheme.spaceMD - 2),
            // Start (current location)
            InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.my_location_outlined),
                labelText: 'Start',
              ),
              child: Text(
                locating ? 'Locating…' : 'Current location',
                style: tt.bodyMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM + 4),
            // Destination search
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.flag_outlined),
                labelText: 'Destination',
                hintText: 'Search a place, or tap the map',
                suffixIcon: searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: onSearch,
                      ),
              ),
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceXS),
              _SearchResults(results: results, onPick: onPick),
            ],
            const SizedBox(height: AppTheme.spaceMD),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: (canFind && !loadingRoutes) ? onFind : null,
                icon: loadingRoutes
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.textOnDark),
                      )
                    : const Icon(Icons.alt_route, size: 18),
                label: Text(loadingRoutes ? 'Finding…' : 'Find safer route'),
              ),
            ),
            if (!RoutingService.isConfigured) ...[
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Routing is off — add ORS_API_KEY to .env to enable it.',
                style: tt.bodySmall!.copyWith(color: AppTheme.riskMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onPick});

  final List<GeoResult> results;
  final ValueChanged<GeoResult> onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          for (final r in results)
            ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined,
                  size: 18, color: AppTheme.primary),
              title: Text(r.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
              onTap: () => onPick(r),
            ),
        ],
      ),
    );
  }
}

// ── Route cards ───────────────────────────────────────────────────────────────

class _RouteCards extends StatelessWidget {
  const _RouteCards({
    required this.routes,
    required this.selected,
    required this.loading,
    required this.hasDestination,
    required this.onSelect,
  });

  final List<RouteOption> routes;
  final RouteOption? selected;
  final bool loading;
  final bool hasDestination;
  final ValueChanged<RouteOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (routes.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppTheme.borderLight, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, color: AppTheme.textHint),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  hasDestination
                      ? 'No routes yet — tap "Find safer route".'
                      : 'Search a destination or tap the map to plan a heat-safe route.',
                  style: tt.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggested routes', style: tt.labelLarge),
        const SizedBox(height: AppTheme.spaceSM + 2),
        for (final route in routes) ...[
          _SelectableRouteCard(
            route: route,
            isSelected: identical(route, selected) || route == selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: AppTheme.spaceSM + 2),
        ],
      ],
    );
  }
}

class _SelectableRouteCard extends StatelessWidget {
  const _SelectableRouteCard({
    required this.route,
    required this.isSelected,
    required this.onSelect,
  });

  final RouteOption route;
  final bool isSelected;
  final ValueChanged<RouteOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RouteOptionCard(route: route, onSelect: onSelect),
    );
  }
}
