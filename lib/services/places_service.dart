import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/cool_spot.dart';

/// Fetches real, nearby cool spots from OpenStreetMap via the Overpass API.
///
/// No API key or billing is required and the endpoint is CORS-enabled, so it
/// works on both Android and Flutter Web. Every returned [CoolSpot] carries the
/// real latitude/longitude of an actual mapped place — nothing is randomly
/// positioned.
class PlacesService {
  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Returns cool spots within [radiusMeters] of ([lat], [lng]), sorted by
  /// distance from that point. Throws on network/parse failure so callers can
  /// fall back to local data.
  Future<List<CoolSpot>> nearbyCoolSpots({
    required double lat,
    required double lng,
    double radiusMeters = 3000,
    int limit = 40,
    int maxPerCategory = 8,
  }) async {
    final r = radiusMeters.round();
    // `nwr` matches nodes, ways AND relations, so places mapped as building
    // polygons (e.g. a 7-Eleven drawn as a footprint) are included too, not
    // just point nodes.
    final query =
        '''
[out:json][timeout:25];
(
  nwr["amenity"="drinking_water"](around:$r,$lat,$lng);
  nwr["amenity"="library"](around:$r,$lat,$lng);
  nwr["shop"="mall"](around:$r,$lat,$lng);
  nwr["shop"="convenience"](around:$r,$lat,$lng);
  nwr["shop"="supermarket"](around:$r,$lat,$lng);
  nwr["leisure"="park"](around:$r,$lat,$lng);
  nwr["amenity"="cafe"](around:$r,$lat,$lng);
);
out center 200;
''';

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: const {'Content-Type': 'text/plain; charset=utf-8'},
      body: query,
    );
    if (response.statusCode != 200) {
      throw http.ClientException('Overpass returned ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List?) ?? const [];

    final byCategory = <String, List<CoolSpot>>{};
    for (final raw in elements) {
      final el = raw as Map<String, dynamic>;
      final spot = _toCoolSpot(el, originLat: lat, originLng: lng, radius: radiusMeters);
      if (spot != null) (byCategory[spot.category] ??= []).add(spot);
    }

    int byDistance(CoolSpot a, CoolSpot b) =>
        (a.distanceMeters ?? double.infinity)
            .compareTo(b.distanceMeters ?? double.infinity);

    // Keep the nearest [maxPerCategory] of each category so a dense category
    // (e.g. drinking water in a park) can't crowd out 7-Elevens, libraries, etc.
    final spots = <CoolSpot>[];
    for (final list in byCategory.values) {
      list.sort(byDistance);
      spots.addAll(list.take(maxPerCategory));
    }
    spots.sort(byDistance);
    return spots.take(limit).toList();
  }

  CoolSpot? _toCoolSpot(
    Map<String, dynamic> el, {
    required double originLat,
    required double originLng,
    required double radius,
  }) {
    // Nodes carry lat/lon directly; ways/relations carry a `center`.
    final double? spotLat =
        (el['lat'] as num?)?.toDouble() ?? (el['center']?['lat'] as num?)?.toDouble();
    final double? spotLng =
        (el['lon'] as num?)?.toDouble() ?? (el['center']?['lon'] as num?)?.toDouble();
    if (spotLat == null || spotLng == null) return null;

    final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final kind = _classify(tags);
    if (kind == null) return null;

    final name = (tags['name'] as String?)?.trim();
    final meters = Geolocator.distanceBetween(originLat, originLng, spotLat, spotLng);
    final offset = _offsetFromLatLng(
      spotLat,
      spotLng,
      originLat: originLat,
      originLng: originLng,
      radius: radius,
    );

    return CoolSpot(
      id: 'osm-${el['type']}-${el['id']}',
      name: (name == null || name.isEmpty) ? kind.fallbackName : name,
      type: kind.type,
      category: kind.category,
      distance: _formatDistance(meters),
      distanceMeters: meters,
      amenity: kind.amenity,
      openStatus: kind.status,
      verifiedBy: 0,
      source: 'OpenStreetMap',
      lat: spotLat,
      lng: spotLng,
      x: offset.dx,
      y: offset.dy,
    );
  }

  // Maps OSM tags onto the app's cool-spot categories. Returns null for places
  // we don't surface.
  _SpotKind? _classify(Map<String, dynamic> tags) {
    switch (tags['amenity']) {
      case 'drinking_water':
        return const _SpotKind(
          type: 'Water',
          category: 'Water refill station',
          amenity: 'Free drinking water refill point',
          status: 'Working',
          fallbackName: 'Water refill point',
        );
      case 'library':
        return const _SpotKind(
          type: 'Air-conditioned',
          category: 'Library',
          amenity: 'Air-conditioned reading and study space',
          status: 'Open',
          fallbackName: 'Public library',
        );
      case 'cafe':
        return const _SpotKind(
          type: 'Air-conditioned',
          category: 'Café',
          amenity: 'Air-conditioned café with seating',
          status: 'Open',
          fallbackName: 'Café',
        );
    }
    switch (tags['shop']) {
      case 'mall':
        return const _SpotKind(
          type: 'Air-conditioned',
          category: 'Shopping mall',
          amenity: 'Air-conditioned mall with seating and restrooms',
          status: 'Open',
          fallbackName: 'Shopping mall',
        );
      case 'supermarket':
        return const _SpotKind(
          type: 'Air-conditioned',
          category: 'Supermarket',
          amenity: 'Air-conditioned store with cold drinks',
          status: 'Open',
          fallbackName: 'Supermarket',
        );
      case 'convenience':
        return const _SpotKind(
          type: 'Air-conditioned',
          category: 'Convenience store',
          amenity: 'Air-conditioned store with cold drinks',
          status: 'Open',
          fallbackName: 'Convenience store',
        );
    }
    if (tags['leisure'] == 'park') {
      return const _SpotKind(
        type: 'Shade',
        category: 'Park',
        amenity: 'Green space with tree shade and seating',
        status: 'Available',
        fallbackName: 'Public park',
      );
    }
    return null;
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // Projects a coordinate into the painted fallback map's 0–1 space, mapping the
  // search radius box onto the view and clamping to keep markers on-screen.
  static ({double dx, double dy}) _offsetFromLatLng(
    double spotLat,
    double spotLng, {
    required double originLat,
    required double originLng,
    required double radius,
  }) {
    final dLat = radius / 111320.0;
    final dLng = radius / (111320.0 * math.cos(originLat * math.pi / 180.0));
    final x = (0.5 + (spotLng - originLng) / (2 * dLng)).clamp(0.08, 0.92);
    final y = (0.5 - (spotLat - originLat) / (2 * dLat)).clamp(0.08, 0.92);
    return (dx: x, dy: y);
  }
}

class _SpotKind {
  const _SpotKind({
    required this.type,
    required this.category,
    required this.amenity,
    required this.status,
    required this.fallbackName,
  });

  final String type;
  final String category;
  final String amenity;
  final String status;
  final String fallbackName;
}
