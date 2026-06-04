import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../dummy_data/dummy_data.dart';
import '../../models/cool_spot.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/cool_spot_card.dart';
import '../../widgets/coolroute_map.dart';
import '../../widgets/section_header.dart';
import '../../widgets/suggest_cool_spot_sheet.dart';

class CoolSpotsScreen extends StatefulWidget {
  const CoolSpotsScreen({super.key});

  @override
  State<CoolSpotsScreen> createState() => _CoolSpotsScreenState();
}

class _CoolSpotsScreenState extends State<CoolSpotsScreen> {
  bool showMap = false;

  /// Type chips act as an OR group; "Open now" / "Verified" are AND constraints.
  static const _typeFilters = {'Shade', 'Water', 'Air-conditioned'};

  final TextEditingController _searchCtrl = TextEditingController();

  /// The nearby spots actually being shown — starts with the bundled set so the
  /// list is never empty, then gets replaced by real OpenStreetMap results.
  List<CoolSpot> _spots = DummyData.coolSpots;
  final Set<String> _activeFilters = {};
  String _query = '';

  LatLng? _userLocation;
  bool _locationIsReal = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _findNearby();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Resolves the device location, then pulls real nearby cool spots from
  // OpenStreetMap around it. Falls back to the bundled set (and the default
  // city) whenever location or the network request is unavailable.
  Future<void> _findNearby() async {
    if (_loading) return;
    setState(() => _loading = true);

    final location = await LocationService().currentLocation();
    if (!mounted) return;

    List<CoolSpot> spots;
    try {
      spots = await PlacesService().nearbyCoolSpots(
        lat: location.latitude,
        lng: location.longitude,
        radiusMeters: CoolRouteMap.nearbyRadiusMeters,
      );
    } catch (_) {
      spots = const [];
    }
    if (!mounted) return;

    setState(() {
      _userLocation = LatLng(location.latitude, location.longitude);
      _locationIsReal = location.isReal;
      _spots = spots.isNotEmpty ? spots : DummyData.coolSpots;
      _loading = false;
    });

    if (!location.isReal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location unavailable — showing the default area.'),
        ),
      );
    }
  }

  // Applies the search query and active filter chips to the loaded spots.
  List<CoolSpot> get _filteredSpots {
    final q = _query.trim().toLowerCase();
    final types = _activeFilters.intersection(_typeFilters);
    return _spots.where((s) {
      if (q.isNotEmpty) {
        final hay =
            '${s.name} ${s.displayCategory} ${s.type} ${s.amenity}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (types.isNotEmpty && !types.any((f) => _matchesType(s, f))) return false;
      if (_activeFilters.contains('Open Now') &&
          s.openStatus.toLowerCase().contains('closed')) {
        return false;
      }
      if (_activeFilters.contains('Verified') && s.verifiedBy <= 0) return false;
      return true;
    }).toList();
  }

  bool _matchesType(CoolSpot s, String filter) {
    if (filter == 'Air-conditioned') {
      return s.type == 'Air-conditioned' || s.type == 'Indoor cooling';
    }
    return s.type == filter;
  }

  void _toggleFilter(String label) {
    setState(() {
      if (!_activeFilters.add(label)) _activeFilters.remove(label);
    });
  }

  void _showCoolSpotDetails(CoolSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoolSpotDetailsSheet(spot: spot),
    );
  }

  void _showSuggestCoolSpotForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SuggestCoolSpotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    final spots = _filteredSpots;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cool spots',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _findNearby,
                    tooltip: 'Find cool spots near me',
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ],
              ),
              Text(
                _locationIsReal
                    ? 'Showing relief points near your location'
                    : 'Showing relief points in the default area',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showSuggestCoolSpotForm,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Suggest a Cool Spot'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  hintText: 'Search water, shade, air conditioning',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.borderMid),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.list),
                    label: Text('List'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.map),
                    label: Text('Map'),
                  ),
                ],
                selected: {showMap},
                onSelectionChanged: (value) =>
                    setState(() => showMap = value.first),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final label in const [
                      'Shade',
                      'Water',
                      'Air-conditioned',
                      'Open Now',
                      'Verified',
                    ])
                      _CoolSpotFilter(
                        label: label,
                        selected: _activeFilters.contains(label),
                        onTap: () => _toggleFilter(label),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (showMap)
                CoolRouteMap(
                  hotZones: DummyData.hotZones,
                  coolSpots: spots,
                  userLocation: _userLocation,
                  onCoolSpotTap: _showCoolSpotDetails,
                )
              else ...[
                SectionHeader(title: 'Closest relief points (${spots.length})'),
                const SizedBox(height: 10),
                if (_loading && _spots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (spots.isEmpty)
                  const _EmptyResults()
                else if (isWide)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 3.6,
                        ),
                    itemCount: spots.length,
                    itemBuilder: (_, i) => CoolSpotCard(
                      spot: spots[i],
                      onView: _showCoolSpotDetails,
                    ),
                  )
                else
                  for (final spot in spots) ...[
                    CoolSpotCard(spot: spot, onView: _showCoolSpotDetails),
                    const SizedBox(height: 10),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'No cool spots match your search or filters.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CoolSpotDetailsSheet extends StatelessWidget {
  const _CoolSpotDetailsSheet({required this.spot});

  final CoolSpot spot;

  @override
  Widget build(BuildContext context) {
    final color = switch (spot.type) {
      'Water' => AppColors.water,
      'Shade' => AppColors.safe,
      _ => AppColors.primary,
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: color.withValues(alpha: .12),
                    child: Icon(Icons.ac_unit, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${spot.type} • ${spot.distance}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.amenity,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${spot.openStatus} • Verified by ${spot.verifiedBy} users',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }
}

class _CoolSpotFilter extends StatelessWidget {
  const _CoolSpotFilter({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
