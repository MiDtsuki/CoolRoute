import 'heat_risk.dart';

class RouteOption {
  const RouteOption({
    required this.name,
    required this.duration,
    required this.distance,
    required this.shadeLevel,
    required this.summary,
    required this.risk,
    this.badge,
  });

  final String name;
  final String duration;
  final String distance;
  final String shadeLevel;
  final String summary;
  final HeatRisk risk;
  final String? badge;
}
