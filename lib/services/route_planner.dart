import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../models/route_option.dart';
import 'routing_service.dart';

/// Turns raw walking routes into scored [RouteOption]s by measuring each
/// route's exposure to reported hot zones. The route with the lowest exposure
/// is flagged "Recommended"; the quickest is labelled "Fastest".
class RoutePlanner {
  const RoutePlanner._();

  /// A hot zone counts as "on the route" within this many metres of it.
  static const double _proximityMeters = 120;

  static List<RouteOption> score(
    List<RawRoute> raw,
    List<HotZoneReport> hotZones,
  ) {
    if (raw.isEmpty) return const [];

    final scored = [
      for (final route in raw) _scoreOne(route, hotZones),
    ];

    final fastestIdx = _minIndexBy(scored, (s) => s.route.durationSeconds);
    final coolestIdx = _minIndexBy(scored, (s) => s.weight);

    final options = <RouteOption>[];
    for (var i = 0; i < scored.length; i++) {
      final s = scored[i];
      String name;
      String? badge;
      if (i == coolestIdx && i == fastestIdx) {
        name = 'Best route';
        badge = 'Recommended';
      } else if (i == coolestIdx) {
        name = 'Cooler route';
        badge = 'Recommended';
      } else if (i == fastestIdx) {
        name = 'Fastest route';
      } else {
        name = 'Alternative';
      }
      options.add(RouteOption(
        name: name,
        duration: _formatDuration(s.route.durationSeconds),
        distance: _formatDistance(s.route.distanceMeters),
        shadeLevel: s.count == 0 ? 'Good' : (s.count <= 2 ? 'Mixed' : 'Low'),
        summary: s.count == 0
            ? 'Avoids all reported hot zones.'
            : 'Passes ${s.count} reported hot zone${s.count == 1 ? '' : 's'}.',
        risk: _riskFor(s.weight),
        badge: badge,
        points: s.route.points,
        distanceMeters: s.route.distanceMeters,
        durationSeconds: s.route.durationSeconds.round(),
        hotZonesNearby: s.count,
        heatScore: s.weight,
      ));
    }

    // Recommended first, then fastest, then alternatives.
    int rank(RouteOption o) => o.badge == 'Recommended'
        ? 0
        : (o.name.startsWith('Fastest') ? 1 : 2);
    options.sort((a, b) => rank(a).compareTo(rank(b)));
    return options;
  }

  static _Scored _scoreOne(RawRoute route, List<HotZoneReport> hotZones) {
    var weight = 0.0;
    var count = 0;
    for (final zone in hotZones) {
      if (!zone.hasLatLng) continue;
      final distance = _minDistanceToRoute(route.points, zone.lat!, zone.lng!);
      if (distance <= _proximityMeters) {
        count++;
        weight += switch (zone.risk) {
          HeatRisk.extreme || HeatRisk.high => 3,
          HeatRisk.medium => 2,
          HeatRisk.low => 1,
        };
      }
    }
    return _Scored(route: route, weight: weight, count: count);
  }

  // Approximate distance from a point to the route by taking the nearest
  // vertex. Routing geometry is dense, so this is close to true segment
  // distance and far cheaper.
  static double _minDistanceToRoute(List<LatLng> points, double lat, double lng) {
    var min = double.infinity;
    for (final p in points) {
      final d = Geolocator.distanceBetween(lat, lng, p.latitude, p.longitude);
      if (d < min) min = d;
    }
    return min;
  }

  static int _minIndexBy(List<_Scored> items, double Function(_Scored) by) {
    var best = 0;
    var bestVal = by(items[0]);
    for (var i = 1; i < items.length; i++) {
      final v = by(items[i]);
      if (v < bestVal) {
        bestVal = v;
        best = i;
      }
    }
    return best;
  }

  static HeatRisk _riskFor(double weight) {
    if (weight == 0) return HeatRisk.low;
    if (weight <= 2) return HeatRisk.medium;
    if (weight <= 5) return HeatRisk.high;
    return HeatRisk.extreme;
  }

  static String _formatDistance(double meters) =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';

  static String _formatDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}

class _Scored {
  const _Scored({required this.route, required this.weight, required this.count});
  final RawRoute route;
  final double weight;
  final int count;
}
