import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import '../models/cool_spot.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../models/tree_pin.dart';
import '../theme/app_theme.dart';

class CoolRouteMap extends StatelessWidget {
  const CoolRouteMap({
    super.key,
    required this.hotZones,
    required this.coolSpots,
    this.treePins = const [],
    this.onHotZoneTap,
    this.onTreePinTap,
    this.onCoolSpotTap,
    this.onMapTap,
    this.focusedSpot,
    this.focusLatLng,
    this.focusTick = 0,
    this.userLocation,
    this.recenterTick = 0,
    this.height = 360,
    this.borderRadius = 24.0,
  });

  // Radius (metres) of the "around me" area drawn on the live map.
  static const double nearbyRadiusMeters = 3000;

  final List<HotZoneReport> hotZones;
  final List<CoolSpot> coolSpots;
  final List<TreePin> treePins;
  final ValueChanged<HotZoneReport>? onHotZoneTap;
  final ValueChanged<TreePin>? onTreePinTap;
  final ValueChanged<CoolSpot>? onCoolSpotTap;
  final VoidCallback? onMapTap;
  // When set, the map centers on this cool spot (live map) or highlights it
  // (fallback).
  final CoolSpot? focusedSpot;
  // An arbitrary point to animate/zoom to (e.g. a searched or selected hot
  // zone). Bumping [focusTick] re-triggers the move even to the same point.
  final LatLng? focusLatLng;
  final int focusTick;
  // The user's location; markers are anchored around it and a 3km radius is
  // drawn. Null until resolved.
  final LatLng? userLocation;
  // Bumping this re-fits the camera to the user's 3km area (recenter button).
  final int recenterTick;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.isInitialized ? dotenv.maybeGet('GOOGLE_MAPS_API_KEY') : null;
    final hasApiKey = apiKey != null && apiKey.isNotEmpty && !apiKey.startsWith('YOUR_');
    // The real GoogleMap widget only works once the Maps JS API has been
    // injected (gated behind enableLiveGoogleMaps); otherwise fall back to the
    // painted placeholder instead of crashing.
    final useLiveMap = hasApiKey && AppConfig.enableLiveGoogleMaps;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        color: const Color(0xFFF1F5F9),
        child: useLiveMap
            ? _GoogleMapView(
                hotZones: hotZones,
                coolSpots: coolSpots,
                treePins: treePins,
                onHotZoneTap: onHotZoneTap,
                onTreePinTap: onTreePinTap,
                onCoolSpotTap: onCoolSpotTap,
                onMapTap: onMapTap,
                focusedSpot: focusedSpot,
                focusLatLng: focusLatLng,
                focusTick: focusTick,
                userLocation: userLocation,
                radiusMeters: nearbyRadiusMeters,
                recenterTick: recenterTick,
              )
            : _PlaceholderMapView(
                hotZones: hotZones,
                coolSpots: coolSpots,
                treePins: treePins,
                onHotZoneTap: onHotZoneTap,
                onTreePinTap: onTreePinTap,
                onCoolSpotTap: onCoolSpotTap,
                onMapTap: onMapTap,
                focusedSpot: focusedSpot,
                hasUserLocation: userLocation != null,
              ),
      ),
    );
  }
}

class _GoogleMapView extends StatefulWidget {
  const _GoogleMapView({
    required this.hotZones,
    required this.coolSpots,
    required this.treePins,
    this.onHotZoneTap,
    this.onTreePinTap,
    this.onCoolSpotTap,
    this.onMapTap,
    this.focusedSpot,
    this.focusLatLng,
    this.focusTick = 0,
    this.userLocation,
    this.radiusMeters = 3000,
    this.recenterTick = 0,
  });

  final List<HotZoneReport> hotZones;
  final List<CoolSpot> coolSpots;
  final List<TreePin> treePins;
  final ValueChanged<HotZoneReport>? onHotZoneTap;
  final ValueChanged<TreePin>? onTreePinTap;
  final ValueChanged<CoolSpot>? onCoolSpotTap;
  final VoidCallback? onMapTap;
  final CoolSpot? focusedSpot;
  final LatLng? focusLatLng;
  final int focusTick;
  final LatLng? userLocation;
  final double radiusMeters;
  final int recenterTick;

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  static const _bangkok = LatLng(13.7563, 100.5018);

  GoogleMapController? _controller;

  // Markers and the radius circle are anchored to the user's location when
  // known, otherwise the default city centre.
  LatLng get _anchor => widget.userLocation ?? _bangkok;

  static MarkerId _spotMarkerId(CoolSpot spot) =>
      MarkerId('cool-spot-${spot.id.isNotEmpty ? spot.id : spot.name}');

  // A cool spot's real coordinate when it has one, else the legacy relative
  // offset anchored on the user (dummy/community fallback data only).
  LatLng _spotPosition(CoolSpot spot) => spot.hasLatLng
      ? LatLng(spot.lat!, spot.lng!)
      : _positionFromOffset(spot.x, spot.y);

  // Same rule for hot zones — real lat/lng when present, offset otherwise.
  LatLng _zonePosition(HotZoneReport zone) => zone.hasLatLng
      ? LatLng(zone.lat!, zone.lng!)
      : _positionFromOffset(zone.x, zone.y);

  @override
  void didUpdateWidget(_GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTick != oldWidget.focusTick && widget.focusLatLng != null) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.focusLatLng!, 16.5),
      );
      return;
    }
    final spot = widget.focusedSpot;
    if (spot != null && spot != oldWidget.focusedSpot) {
      _focusSpot(spot);
      return;
    }
    final loc = widget.userLocation;
    if (loc != null &&
        (loc != oldWidget.userLocation ||
            widget.recenterTick != oldWidget.recenterTick)) {
      _fitToUser(loc);
    }
  }

  Future<void> _focusSpot(CoolSpot spot) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(_spotPosition(spot), 17),
    );
    await controller.showMarkerInfoWindow(_spotMarkerId(spot));
  }

  Future<void> _fitToUser(LatLng center) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_radiusBounds(center, widget.radiusMeters), 40),
    );
  }

  // Approximate lat/lng bounds of a circle of [radiusMeters] around [center].
  static LatLngBounds _radiusBounds(LatLng center, double radiusMeters) {
    final dLat = radiusMeters / 111320.0;
    final dLng =
        radiusMeters / (111320.0 * math.cos(center.latitude * math.pi / 180.0));
    return LatLngBounds(
      southwest: LatLng(center.latitude - dLat, center.longitude - dLng),
      northeast: LatLng(center.latitude + dLat, center.longitude + dLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};

    for (final report in widget.hotZones) {
      markers.add(
        Marker(
          markerId: MarkerId('hot-zone-${report.title}'),
          position: _zonePosition(report),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            report.risk == HeatRisk.medium ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(title: report.title, snippet: report.location),
          onTap: () => widget.onHotZoneTap?.call(report),
        ),
      );
    }

    for (final spot in widget.coolSpots) {
      markers.add(
        Marker(
          markerId: _spotMarkerId(spot),
          position: _spotPosition(spot),
          icon: BitmapDescriptor.defaultMarkerWithHue(_spotHue(spot.type)),
          infoWindow: InfoWindow(
            title: spot.name,
            snippet: '${spot.displayCategory} · ${spot.distance}',
            onTap: () => widget.onCoolSpotTap?.call(spot),
          ),
          onTap: () => widget.onCoolSpotTap?.call(spot),
        ),
      );
    }

    for (final tree in widget.treePins) {
      markers.add(
        Marker(
          markerId: MarkerId('tree-pin-${tree.title}'),
          position: _positionFromOffset(tree.x, tree.y),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: tree.title, snippet: tree.locationName),
          onTap: () => widget.onTreePinTap?.call(tree),
        ),
      );
    }

    final circles = <Circle>{};
    if (widget.userLocation != null) {
      circles.add(
        Circle(
          circleId: const CircleId('user-radius'),
          center: widget.userLocation!,
          radius: widget.radiusMeters,
          fillColor: AppTheme.primary.withValues(alpha: 0.10),
          strokeColor: AppTheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _anchor, zoom: 15.2),
      markers: markers,
      circles: circles,
      onMapCreated: (controller) {
        _controller = controller;
        if (widget.focusedSpot != null) {
          _focusSpot(widget.focusedSpot!);
        } else if (widget.userLocation != null) {
          _fitToUser(widget.userLocation!);
        }
      },
      onTap: (_) => widget.onMapTap?.call(),
      // Native "blue dot" for the user's real position; our own FAB recenters.
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  // Cool-spot marker colour, on-theme: water = blue, shade/park = green,
  // air-conditioned/indoor = cyan.
  static double _spotHue(String type) => switch (type) {
        'Water' => BitmapDescriptor.hueAzure,
        'Shade' => BitmapDescriptor.hueGreen,
        _ => BitmapDescriptor.hueCyan,
      };

  LatLng _positionFromOffset(double x, double y) {
    const latSpan = .018;
    const lngSpan = .022;
    return LatLng(
      _anchor.latitude + (.5 - y) * latSpan,
      _anchor.longitude + (x - .5) * lngSpan,
    );
  }
}

class _PlaceholderMapView extends StatelessWidget {
  const _PlaceholderMapView({
    required this.hotZones,
    required this.coolSpots,
    required this.treePins,
    this.onHotZoneTap,
    this.onTreePinTap,
    this.onCoolSpotTap,
    this.onMapTap,
    this.focusedSpot,
    this.hasUserLocation = false,
  });

  final List<HotZoneReport> hotZones;
  final List<CoolSpot> coolSpots;
  final List<TreePin> treePins;
  final ValueChanged<HotZoneReport>? onHotZoneTap;
  final ValueChanged<TreePin>? onTreePinTap;
  final ValueChanged<CoolSpot>? onCoolSpotTap;
  final VoidCallback? onMapTap;
  final CoolSpot? focusedSpot;
  final bool hasUserLocation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: onMapTap,
                  child: const _MapBackground(),
                ),
                // The fallback can't geolocate, so the user is shown at centre.
                if (hasUserLocation)
                  Positioned(
                    left: 0.5 * constraints.maxWidth,
                    top: 0.5 * constraints.maxHeight,
                    child: const _Marker(
                      color: AppTheme.markerBlue,
                      icon: Icons.my_location,
                    ),
                  ),
                for (final spot in coolSpots)
                  Positioned(
                    left: spot.x * constraints.maxWidth,
                    top: spot.y * constraints.maxHeight,
                    child: GestureDetector(
                      onTap: () => onCoolSpotTap?.call(spot),
                      child: _Marker(
                        color: switch (spot.type) {
                          'Water' => AppTheme.markerBlue,
                          'Shade' => AppTheme.markerGreen,
                          _ => AppTheme.primary,
                        },
                        icon: switch (spot.type) {
                          'Water' => Icons.water_drop,
                          'Shade' => Icons.park,
                          _ => Icons.ac_unit,
                        },
                        highlighted: spot == focusedSpot,
                      ),
                    ),
                  ),
                for (final report in hotZones)
                  Positioned(
                    left: report.x * constraints.maxWidth,
                    top: report.y * constraints.maxHeight,
                    child: GestureDetector(
                      onTap: () => onHotZoneTap?.call(report),
                      child: _Marker(
                        color: switch (report.risk) {
                          HeatRisk.extreme || HeatRisk.high => AppColors.extreme,
                          HeatRisk.medium => AppColors.high,
                          HeatRisk.low => AppColors.safe,
                        },
                        icon: Icons.local_fire_department,
                      ),
                    ),
                  ),
                for (final tree in treePins)
                  Positioned(
                    left: tree.x * constraints.maxWidth,
                    top: tree.y * constraints.maxHeight,
                    child: GestureDetector(
                      onTap: () => onTreePinTap?.call(tree),
                      child: const _Marker(
                        color: AppTheme.markerTree,
                        icon: Icons.park_outlined,
                      ),
                    ),
                  ),
                const _FallbackNotice(),
              ],
            );
          },
        );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Prototype map - live maps disabled', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _MapPainter());
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final park = Paint()..color = const Color(0xFFDCFCE7);
    final block = Paint()..color = const Color(0xFFE2E8F0);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    final roadLine = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .06, size.height * .08, size.width * .28, size.height * .20), const Radius.circular(18)),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .58, size.height * .64, size.width * .30, size.height * .20), const Radius.circular(18)),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .52, size.height * .10, size.width * .20, size.height * .18), const Radius.circular(12)),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .16, size.height * .62, size.width * .22, size.height * .18), const Radius.circular(12)),
      block,
    );
    canvas.drawLine(Offset(size.width * .05, size.height * .72), Offset(size.width * .95, size.height * .25), road);
    canvas.drawLine(Offset(size.width * .18, size.height * .12), Offset(size.width * .82, size.height * .88), road);
    canvas.drawLine(Offset(size.width * .10, size.height * .50), Offset(size.width * .90, size.height * .55), road);
    canvas.drawLine(Offset(size.width * .42, size.height * .05), Offset(size.width * .48, size.height * .95), road);
    canvas.drawLine(Offset(size.width * .05, size.height * .72), Offset(size.width * .95, size.height * .25), roadLine);
    canvas.drawLine(Offset(size.width * .18, size.height * .12), Offset(size.width * .82, size.height * .88), roadLine);
    canvas.drawLine(Offset(size.width * .10, size.height * .50), Offset(size.width * .90, size.height * .55), roadLine);
    canvas.drawLine(Offset(size.width * .42, size.height * .05), Offset(size.width * .48, size.height * .95), roadLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Marker extends StatelessWidget {
  const _Marker({required this.color, required this.icon, this.highlighted = false});

  final Color color;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-18, -18),
      child: AnimatedScale(
        scale: highlighted ? 1.35 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlighted ? AppTheme.primaryDark : Colors.white,
              width: highlighted ? 4 : 3,
            ),
            boxShadow: const [BoxShadow(color: Color(0x330F172A), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
