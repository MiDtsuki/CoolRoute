import 'package:flutter/material.dart';

import '../../models/heat_risk.dart';
import '../../models/route_option.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/heat_risk_badge.dart';

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key, required this.route});

  final RouteOption route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route details')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RouteMapPreview(route: route),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              route.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          HeatRiskBadge(route.risk),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(route.summary, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricPill(icon: Icons.schedule, label: 'Estimated time', value: route.duration),
                          _MetricPill(icon: Icons.route, label: 'Distance', value: route.distance),
                          _MetricPill(icon: Icons.park, label: 'Shade level', value: route.shadeLevel),
                          _MetricPill(icon: Icons.ac_unit, label: 'Cool spots', value: _coolSpotsAlongRoute(route)),
                          _MetricPill(icon: Icons.block, label: 'Hot zones avoided', value: _hotZonesAvoided(route)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _recommendationColor(route.risk).withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _recommendationColor(route.risk).withValues(alpha: .24)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.health_and_safety, color: _recommendationColor(route.risk)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _safetyRecommendation(route),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Route steps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const _RouteStep(index: 1, text: 'Walk through shaded walkway'),
                const _RouteStep(index: 2, text: 'Stop near water refill station if needed'),
                const _RouteStep(index: 3, text: 'Avoid main road hot zone'),
                const _RouteStep(index: 4, text: 'Enter library indoor path'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${route.name} started.')),
                          );
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Start Route'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${route.name} saved.')),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Save Route'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _coolSpotsAlongRoute(RouteOption route) {
    if (route.name.contains('Indoor')) return 'Library, mall';
    if (route.badge == 'Recommended') return 'Water station, shade';
    return 'Bus stop shade';
  }

  static String _hotZonesAvoided(RouteOption route) {
    if (route.risk == HeatRisk.low) return '3 zones';
    if (route.risk == HeatRisk.medium) return '2 zones';
    return '1 zone';
  }

  static String _safetyRecommendation(RouteOption route) {
    if (route.risk == HeatRisk.low) return 'Best choice for current heat conditions. Keep water available.';
    if (route.risk == HeatRisk.medium) return 'Recommended if you can spare a few extra minutes for shade and water access.';
    return 'Use only if urgent. Avoid stopping in exposed areas and take water before walking.';
  }

  static Color _recommendationColor(HeatRisk risk) {
    return switch (risk) {
      HeatRisk.low => AppColors.safe,
      HeatRisk.medium => AppColors.moderate,
      HeatRisk.high => AppColors.high,
      HeatRisk.extreme => AppColors.extreme,
    };
  }
}

class _RouteMapPreview extends StatelessWidget {
  const _RouteMapPreview({required this.route});

  final RouteOption route;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240,
        color: const Color(0xFFEAF7F5),
        child: CustomPaint(
          painter: _RouteDetailsPainter(route.risk),
          child: Stack(
            children: [
              const Positioned(left: 18, top: 18, child: _MapTag(icon: Icons.my_location, text: 'Start')),
              Positioned(
                right: 18,
                bottom: 18,
                child: _MapTag(icon: Icons.flag, text: route.name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteDetailsPainter extends CustomPainter {
  const _RouteDetailsPainter(this.risk);

  final HeatRisk risk;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final routeLine = Paint()
      ..color = switch (risk) {
        HeatRisk.low => AppColors.safe,
        HeatRisk.medium => AppColors.primary,
        HeatRisk.high || HeatRisk.extreme => AppColors.high,
      }
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width * .08, size.height * .70), Offset(size.width * .90, size.height * .30), road);
    canvas.drawLine(Offset(size.width * .20, size.height * .12), Offset(size.width * .76, size.height * .86), road);
    canvas.drawLine(Offset(size.width * .08, size.height * .48), Offset(size.width * .92, size.height * .54), road);

    final path = Path()
      ..moveTo(size.width * .18, size.height * .28)
      ..cubicTo(size.width * .34, size.height * .64, size.width * .62, size.height * .22, size.width * .82, size.height * .72);
    canvas.drawPath(path, routeLine);
  }

  @override
  bool shouldRepaint(covariant _RouteDetailsPainter oldDelegate) => oldDelegate.risk != risk;
}

class _MapTag extends StatelessWidget {
  const _MapTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySoft,
              child: Text('$index', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}
