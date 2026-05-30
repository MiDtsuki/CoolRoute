import 'heat_risk.dart';

class HotZoneReport {
  const HotZoneReport({
    required this.title,
    required this.location,
    required this.category,
    required this.description,
    required this.timeAgo,
    required this.verifications,
    required this.risk,
    required this.x,
    required this.y,
  });

  final String title;
  final String location;
  final String category;
  final String description;
  final String timeAgo;
  final int verifications;
  final HeatRisk risk;
  final double x;
  final double y;
}
