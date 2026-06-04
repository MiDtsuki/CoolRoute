import 'package:flutter/material.dart';

import '../../models/heat_risk.dart';
import '../../models/hot_zone_report.dart';
import '../../models/weather_info.dart';
import '../../services/report_refresh.dart';
import '../../services/report_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_theme.dart';
import '../reports/create_hot_zone_report_screen.dart';
import '../route/route_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onFindCoolSpot, this.onPlantTree});

  final VoidCallback? onFindCoolSpot;
  final VoidCallback? onPlantTree;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<WeatherInfo> _weatherFuture =
      WeatherService().getCurrentWeather();

  List<HotZoneReport> _hotZones = const [];

  @override
  void initState() {
    super.initState();
    _loadHotZones();
    hotZoneRevision.addListener(_loadHotZones);
  }

  @override
  void dispose() {
    hotZoneRevision.removeListener(_loadHotZones);
    super.dispose();
  }

  Future<void> _loadHotZones() async {
    final zones = await ReportService().getHotZoneReports();
    if (!mounted) return;
    setState(() => _hotZones = zones);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<WeatherInfo>(
                future: _weatherFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ColoredBox(
                      color: AppTheme.bgHero,
                      child: SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      ),
                    );
                  }
                  return _HeroCard(
                    weather: snapshot.data!,
                    hotZoneCount: _hotZones.length,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD, AppTheme.spaceLG,
                  AppTheme.spaceMD, AppTheme.spaceSM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick actions', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppTheme.spaceSM),
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppTheme.spaceSM,
                      crossAxisSpacing: AppTheme.spaceSM,
                      childAspectRatio: 1.6,
                      children: [
                        _ActionCard(
                          icon: Icons.route_rounded,
                          iconBg: AppTheme.primaryLight,
                          iconColor: AppTheme.primary,
                          title: 'Find Heat-Safe Route',
                          subtitle: 'Avoid heat zones',
                          onTap: () => _push(context, 'Route', const RouteScreen()),
                        ),
                        _ActionCard(
                          icon: Icons.local_fire_department_rounded,
                          iconBg: AppTheme.riskExtremeBg,
                          iconColor: AppTheme.riskExtreme,
                          title: 'Report Hot Zone',
                          subtitle: 'Help the community',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const CreateHotZoneReportScreen()),
                          ),
                        ),
                        _ActionCard(
                          icon: Icons.ac_unit_rounded,
                          iconBg: AppTheme.riskLowBg,
                          iconColor: AppTheme.riskNone,
                          title: 'Find Cool Spot',
                          subtitle: '6 spots nearby',
                          onTap: widget.onFindCoolSpot ?? () {},
                        ),
                        _ActionCard(
                          icon: Icons.park_outlined,
                          iconBg: AppTheme.riskLowBg,
                          iconColor: AppTheme.markerTree,
                          title: 'Plant a Tree 🌱',
                          subtitle: 'View community trees',
                          onTap: widget.onPlantTree ?? () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    Text('Recent alerts', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppTheme.spaceSM),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                  itemCount: _hotZones.length < 3 ? _hotZones.length : 3,
                  separatorBuilder: (_, _) => const SizedBox(width: AppTheme.spaceSM),
                  itemBuilder: (_, i) => _AlertChip(report: _hotZones[i]),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.weather,
    required this.hotZoneCount,
  });

  final WeatherInfo weather;
  final int hotZoneCount;

  static String _time() {
    final t = DateTime.now();
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppTheme.bgHero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD, AppTheme.spaceLG, AppTheme.spaceMD, AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(weather.location,
                    style: tt.labelSmall!.copyWith(color: AppTheme.textOnDarkDim)),
                Text(_time(),
                    style: tt.labelSmall!.copyWith(color: AppTheme.textOnDarkDim)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${weather.temperatureC}°C',
                    style: tt.displayLarge!.copyWith(color: AppTheme.textOnDark)),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.riskExtreme,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceSM + 2, vertical: 3),
                    child: Text('Extreme risk',
                        style: tt.labelSmall!.copyWith(color: AppTheme.textOnDark)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Text(
              'Feels like ${weather.feelsLikeC}°C  ·  '
              'Humidity ${weather.humidity}%  ·  UV ${weather.uvIndex}',
              style: tt.bodySmall!.copyWith(color: AppTheme.textOnDarkMid),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Row(
              children: [
                _StatBox(value: '${weather.feelsLikeC}°C', label: 'Feels like'),
                const SizedBox(width: AppTheme.spaceSM),
                _StatBox(value: '${weather.humidity}%', label: 'Humidity'),
                const SizedBox(width: AppTheme.spaceSM),
                _StatBox(value: '$hotZoneCount', label: 'Hot zones'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.statBoxOnDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSM + 2),
          child: Column(
            children: [
              Text(value, style: tt.labelLarge!.copyWith(color: AppTheme.textOnDark)),
              const SizedBox(height: 2),
              Text(label, style: tt.labelSmall!.copyWith(color: AppTheme.textOnDarkDim)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action card ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderLight, width: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceSM),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(title, style: tt.labelLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: tt.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert chip ───────────────────────────────────────────────────────────────

class _AlertChip extends StatelessWidget {
  const _AlertChip({required this.report});

  final HotZoneReport report;

  Color get _dotColor => switch (report.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtreme,
        HeatRisk.medium                   => AppTheme.riskMedium,
        HeatRisk.low                      => AppTheme.riskLow,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceXS + 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
              child: const SizedBox(width: 8, height: 8),
            ),
            const SizedBox(width: 6),
            Text(report.location, style: tt.labelMedium),
            const SizedBox(width: 6),
            Text(report.displayTimeAgo,
                style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _push(BuildContext context, String title, Widget screen) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(child: screen),
      ),
    ),
  );
}
