import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// A geocoding match (place search result).
class GeoResult {
  const GeoResult({required this.label, required this.lat, required this.lng});

  final String label;
  final double lat;
  final double lng;

  LatLng get latLng => LatLng(lat, lng);
}

/// A raw walking route returned by the router (geometry + totals), before any
/// heat scoring is applied.
class RawRoute {
  const RawRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

/// OpenRouteService wrapper: geocoding (Pelias) + walking directions.
///
/// CORS-enabled, so it works from Flutter web and Android with a plain `http`
/// call. Needs a free API key in `.env` as `ORS_API_KEY`; every method degrades
/// gracefully (returns empty) when the key is missing or a request fails.
class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'api.openrouteservice.org';
  static const _timeout = Duration(seconds: 12);

  static String? get apiKey {
    if (!dotenv.isInitialized) return null;
    final key = dotenv.maybeGet('ORS_API_KEY')?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  static bool get isConfigured => apiKey != null;

  /// Forward-geocodes [query]. [focusLat]/[focusLng] bias results toward the
  /// user's area so "library" returns nearby matches first.
  Future<List<GeoResult>> geocode(
    String query, {
    double? focusLat,
    double? focusLng,
  }) async {
    final key = apiKey;
    if (key == null || query.trim().isEmpty) return const [];
    final params = <String, String>{
      'api_key': key,
      'text': query,
      'size': '8',
      'layers': 'venue,address,street,locality',
      if (focusLat != null && focusLng != null) ...{
        'focus.point.lat': '$focusLat',
        'focus.point.lon': '$focusLng',
      },
    };
    final uri = Uri.https(_host, '/geocode/search', params);
    try {
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('VERIFY: ORS geocode HTTP ${res.statusCode}');
        return const [];
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (body['features'] as List?) ?? const [];
      final results = <GeoResult>[];
      for (final f in features) {
        final m = f as Map<String, dynamic>;
        final coords = (m['geometry']?['coordinates'] as List?) ?? const [];
        if (coords.length < 2) continue;
        final props = (m['properties'] as Map?) ?? const {};
        results.add(GeoResult(
          label: (props['label'] as String?) ?? 'Unknown place',
          lat: (coords[1] as num).toDouble(),
          lng: (coords[0] as num).toDouble(),
        ));
      }
      return results;
    } catch (e) {
      debugPrint('VERIFY: ORS geocode error: $e');
      return const [];
    }
  }

  /// Walking routes from [start] to [end] — up to three alternatives when the
  /// router offers them, otherwise the single best route.
  Future<List<RawRoute>> walkingRoutes(LatLng start, LatLng end) async {
    final key = apiKey;
    if (key == null) return const [];
    final withAlternatives = {
      'coordinates': [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
      'alternative_routes': {
        'target_count': 3,
        'share_factor': 0.6,
        'weight_factor': 1.6,
      },
      'instructions': false,
    };
    final routes = await _directions(key, withAlternatives);
    if (routes.isNotEmpty) return routes;
    // Alternatives aren't available for every pair — retry for a single route.
    return _directions(key, {
      'coordinates': [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
      'instructions': false,
    });
  }

  Future<List<RawRoute>> _directions(
      String key, Map<String, dynamic> payload) async {
    final uri = Uri.https(_host, '/v2/directions/foot-walking/geojson');
    try {
      final res = await _client
          .post(
            uri,
            headers: {
              'Authorization': key,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('VERIFY: ORS directions HTTP ${res.statusCode}: ${res.body}');
        return const [];
      }
      return _parseRoutes(res.body);
    } catch (e) {
      debugPrint('VERIFY: ORS directions error: $e');
      return const [];
    }
  }

  List<RawRoute> _parseRoutes(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final features = (json['features'] as List?) ?? const [];
    final routes = <RawRoute>[];
    for (final f in features) {
      final m = f as Map<String, dynamic>;
      final coords = (m['geometry']?['coordinates'] as List?) ?? const [];
      if (coords.isEmpty) continue;
      final summary = (m['properties']?['summary'] as Map?) ?? const {};
      final points = <LatLng>[];
      for (final c in coords) {
        final p = c as List;
        points.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
      }
      routes.add(RawRoute(
        points: points,
        distanceMeters: (summary['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (summary['duration'] as num?)?.toDouble() ?? 0,
      ));
    }
    return routes;
  }
}
