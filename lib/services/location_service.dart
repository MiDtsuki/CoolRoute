import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Best-effort device location. Falls back to Bangkok center when location
/// services or permissions are unavailable.
class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isReal,
  });

  final double latitude;
  final double longitude;

  /// True when this came from the device, false when it's the fallback.
  final bool isReal;

  static const fallback = LocationResult(
    latitude: 13.7563,
    longitude: 100.5018,
    isReal: false,
  );
}

class LocationService {
  Future<LocationResult> currentLocation() async {
    try {
      // On web, isLocationServiceEnabled() often returns false even when the
      // browser supports geolocation — skip it and attempt the position directly.
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          return LocationResult.fallback;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return LocationResult.fallback;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isReal: true,
      );
    } catch (_) {
      return LocationResult.fallback;
    }
  }
}
