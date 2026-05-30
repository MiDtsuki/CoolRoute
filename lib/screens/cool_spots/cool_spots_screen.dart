import 'package:flutter/material.dart';

import '../../dummy_data/dummy_data.dart';
import '../../models/cool_spot.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cool spots',
                style: Theme.of(context).textTheme.headlineLarge,
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
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
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CoolSpotFilter(label: 'Shade', selected: true),
                    _CoolSpotFilter(label: 'Water'),
                    _CoolSpotFilter(label: 'Air-conditioned'),
                    _CoolSpotFilter(label: 'Open Now'),
                    _CoolSpotFilter(label: 'Verified'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (showMap)
                CoolRouteMap(
                  hotZones: DummyData.hotZones,
                  coolSpots: DummyData.coolSpots,
                )
              else ...[
                const SectionHeader(title: 'Closest relief points'),
                const SizedBox(height: 10),
                if (isWide)
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
                    itemCount: DummyData.coolSpots.length,
                    itemBuilder: (_, i) => CoolSpotCard(
                      spot: DummyData.coolSpots[i],
                      onView: _showCoolSpotDetails,
                    ),
                  )
                else
                  for (final spot in DummyData.coolSpots) ...[
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
  const _CoolSpotFilter({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
      ),
    );
  }
}
