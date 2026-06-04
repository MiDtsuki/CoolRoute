import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    this.points = const [],
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.hotZonesNearby = 0,
    this.heatScore = 0,
  });

  final String name;
  final String duration;
  final String distance;
  final String shadeLevel;
  final String summary;
  final HeatRisk risk;
  final String? badge;

  // Real routing data (empty for the legacy dummy routes).
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final int hotZonesNearby;
  final double heatScore;

  bool get hasGeometry => points.isNotEmpty;
}
