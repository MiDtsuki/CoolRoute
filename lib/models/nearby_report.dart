import 'heat_risk.dart';

class NearbyReport {
  const NearbyReport({
    required this.id,
    required this.title,
    required this.location,
    required this.distance,
    required this.risk,
    required this.timeAgo,
    required this.verifications,
  });

  final String id;
  final String title;
  final String location;
  final String distance;
  final HeatRisk risk;
  final String timeAgo;
  final int verifications;
}
