import 'package:flutter/material.dart';

import '../../data/dummy_tree_pins.dart';
import '../../dummy_data/dummy_data.dart';
import '../../models/cool_spot.dart';
import '../../models/hot_zone_report.dart';
import '../../models/nearby_report.dart';
import '../../models/tree_pin.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cool_spot_card.dart';
import '../../widgets/coolroute_map.dart';
import '../../widgets/hot_zone_bottom_sheet.dart';
import '../../widgets/hot_zone_side_panel.dart';
import '../../widgets/location_pin_picker.dart';
import '../../widgets/suggest_cool_spot_sheet.dart';
import '../reports/create_hot_zone_report_screen.dart';

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
  late String _activeFilter;

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

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialTreesSelected ? _treesFilter : 'All';
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
    _activeFilter = 'All';
  });

  void _showSpotDetail(CoolSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpotDetailSheet(spot: spot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    final screenH = MediaQuery.sizeOf(context).height;
    final sheetH = screenH * 0.65;
    final spotPanelH = screenH * 0.48;

    final mapWidget = CoolRouteMap(
      hotZones: DummyData.hotZones,
      coolSpots: DummyData.coolSpots,
      treePins: _showTrees ? DummyTreePins.pins : const [],
      height: double.infinity,
      borderRadius: 0,
      onHotZoneTap: _coolSpotsMode ? null : _onMarkerTap,
      onTreePinTap: _showTrees ? _onTreeTap : null,
      onMapTap: _onDismiss,
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
              _FloatingSearchBar(coolSpotsMode: _coolSpotsMode),
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
            child: const _MapActionButtons(),
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
                : const SizedBox.shrink(key: ValueKey('empty')),
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
              onSpotView: _showSpotDetail,
            ),
          ),
        ),
        // FAB — hidden in cool spots mode
        if (!_coolSpotsMode)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: AppTheme.spaceMD,
            bottom: (_selectedZone != null || _selectedTree != null)
                ? sheetH + AppTheme.spaceMD
                : AppTheme.spaceLG,
            child: const _MapActionButtons(),
          ),
      ],
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
    required this.onSpotView,
  });

  final double maxHeight;
  final ValueChanged<CoolSpot> onSpotView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final spots = DummyData.coolSpots;
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
                    '${spots.length} found',
                    style: tt.bodySmall!.copyWith(color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD,
                  AppTheme.spaceXS,
                  AppTheme.spaceMD,
                  AppTheme.spaceLG,
                ),
                itemCount: spots.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTheme.spaceSM),
                itemBuilder: (_, i) =>
                    CoolSpotCard(spot: spots[i], onView: onSpotView),
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
  const _CoolSpotsSidePanel({super.key, required this.onSpotView});

  final ValueChanged<CoolSpot> onSpotView;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final spots = DummyData.coolSpots;
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
              child: Text('Cool spots nearby', style: tt.labelLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                itemCount: spots.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTheme.spaceSM),
                itemBuilder: (_, i) =>
                    CoolSpotCard(spot: spots[i], onView: onSpotView),
              ),
            ),
          ],
        ),
      ),
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
                        '${spot.type} · ${spot.distance}',
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
            Text(
              '${spot.openStatus} · Verified by ${spot.verifiedBy} users',
              style: tt.bodySmall!.copyWith(color: AppTheme.textHint),
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

// ── Floating search bar ───────────────────────────────────────────────────────

class _FloatingSearchBar extends StatelessWidget {
  const _FloatingSearchBar({required this.coolSpotsMode});

  final bool coolSpotsMode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: AppTheme.spaceSM + 2,
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppTheme.textHint),
            const SizedBox(width: AppTheme.spaceSM),
            Text(
              coolSpotsMode
                  ? 'Search water, shade, air conditioning…'
                  : 'Search campus, station, or cool spot…',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: AppTheme.textHint),
            ),
          ],
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
  const _MapActionButtons();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'map-report-fab',
      backgroundColor: AppTheme.bgCard,
      foregroundColor: AppTheme.primary,
      elevation: 0,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ReportTypeSheet(),
      ),
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Report'),
    );
  }
}

class _ReportTypeSheet extends StatelessWidget {
  const _ReportTypeSheet();

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
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateHotZoneReportScreen(),
                    ),
                  );
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
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SuggestCoolSpotSheet(),
                  );
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
