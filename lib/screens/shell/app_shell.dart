import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../data/environmental_data_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../route/route_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _mapVersion = 0;
  bool _openTreesFilter = false;

  void _goToMapCoolSpots() => setState(() => _index = 2);
  void _goToMapTrees() => setState(() {
        _index = 2;
        _openTreesFilter = true;
        _mapVersion++;
      });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;

    // IndexedStack keeps all screens alive, preserving map camera etc.
    final body = IndexedStack(
      index: _index,
      children: [
        HomeScreen(onFindCoolSpot: _goToMapCoolSpots, onPlantTree: _goToMapTrees),
        const RouteScreen(),
        MapScreen(
          key: ValueKey('map-$_mapVersion-$_openTreesFilter'),
          initialTreesSelected: _openTreesFilter,
        ),
        const EnvironmentalDataScreen(),
      ],
    );

    if (isWide) {
      return Scaffold(
        appBar: _WebNavBar(
          selectedIndex: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
        body: body,
      );
    }

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Color(0x140F172A), blurRadius: 18, offset: Offset(0, -6))
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.alt_route_outlined),
                selectedIcon: Icon(Icons.alt_route),
                label: 'Route'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map'),
            NavigationDestination(
                icon: Icon(Icons.satellite_alt_outlined),
                selectedIcon: Icon(Icons.satellite_alt),
                label: 'Data'),
          ],
        ),
      ),
    );
  }
}

// ── Web top navigation bar ────────────────────────────────────────────────────

class _WebNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _WebNavBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.alt_route_outlined, Icons.alt_route, 'Route'),
    (Icons.map_outlined, Icons.map, 'Map'),
    (Icons.satellite_alt_outlined, Icons.satellite_alt, 'Data'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 0.5)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: AppTheme.spaceMD),
            Text(
              'CoolRoute',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: AppTheme.spaceXL),
            for (var i = 0; i < _tabs.length; i++)
              _WebNavTab(
                icon: selectedIndex == i ? _tabs[i].$2 : _tabs[i].$1,
                label: _tabs[i].$3,
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _WebNavTab extends StatelessWidget {
  const _WebNavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : AppTheme.textHint;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppTheme.spaceXS + 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
