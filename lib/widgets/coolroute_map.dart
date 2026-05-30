import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    this.onMapTap,
    this.height = 360,
    this.borderRadius = 24.0,
  });

  final List<HotZoneReport> hotZones;
  final List<CoolSpot> coolSpots;
  final List<TreePin> treePins;
  final ValueChanged<HotZoneReport>? onHotZoneTap;
  final ValueChanged<TreePin>? onTreePinTap;
  final VoidCallback? onMapTap;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.isInitialized ? dotenv.maybeGet('GOOGLE_MAPS_API_KEY') : null;
    final hasApiKey = apiKey != null && apiKey.isNotEmpty && !apiKey.startsWith('YOUR_');

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        color: const Color(0xFFF1F5F9),
        child: hasApiKey
            ? _GoogleMapView(
                hotZones: hotZones,
                coolSpots: coolSpots,
                treePins: treePins,
                onHotZoneTap: onHotZoneTap,
                onTreePinTap: onTreePinTap,
                onMapTap: onMapTap,
              )
            : _PlaceholderMapView(
                hotZones: hotZones,
                coolSpots: coolSpots,
                treePins: treePins,
                onHotZoneTap: onHotZoneTap,
                onTreePinTap: onTreePinTap,
                onMapTap: onMapTap,
              ),
      ),
    );
  }
}

class _GoogleMapView extends StatelessWidget {
  const _GoogleMapView({
    required this.hotZones,
    required this.coolSpots,
    required this.treePins,
    this.onHotZoneTap,
    this.onTreePinTap,
    this.onMapTap,
  });

  static const _center = LatLng(13.7563, 100.5018);

  final List<HotZoneReport> hotZones;
  final List<CoolSpot> coolSpots;
  final List<TreePin> treePins;
  final ValueChanged<HotZoneReport>? onHotZoneTap;
  final ValueChanged<TreePin>? onTreePinTap;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};

    for (final report in hotZones) {
      markers.add(
        Marker(
          markerId: MarkerId('hot-zone-${report.title}'),
          position: _positionFromOffset(report.x, report.y),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            report.risk == HeatRisk.medium ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(title: report.title, snippet: report.location),
          onTap: () => onHotZoneTap?.call(report),
        ),
      );
    }

    for (final spot in coolSpots) {
      markers.add(
        Marker(
          markerId: MarkerId('cool-spot-${spot.name}'),
          position: _positionFromOffset(spot.x, spot.y),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            spot.type == 'Water' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: spot.name, snippet: spot.amenity),
        ),
      );
    }

    for (final tree in treePins) {
      markers.add(
        Marker(
          markerId: MarkerId('tree-pin-${tree.title}'),
          position: _positionFromOffset(tree.x, tree.y),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: tree.title, snippet: tree.locationName),
          onTap: () => onTreePinTap?.call(tree),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: _center, zoom: 15.2),
      markers: markers,
      onTap: (_) => onMapTap?.call(),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  static LatLng _positionFromOffset(double x, double y) {
    const latSpan = .018;
    const lngSpan = .022;
    return LatLng(
      _center.latitude + (.5 - y) * latSpan,
      _center.longitude + (x - .5) * lngSpan,
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
    this.onMapTap,
  });

  final List<HotZoneReport> hotZones;
  final List<CoolSpot> coolSpots;
  final List<TreePin> treePins;
  final ValueChanged<HotZoneReport>? onHotZoneTap;
  final ValueChanged<TreePin>? onTreePinTap;
  final VoidCallback? onMapTap;

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
                for (final spot in coolSpots)
                  Positioned(
                    left: spot.x * constraints.maxWidth,
                    top: spot.y * constraints.maxHeight,
                    child: _Marker(
                      color: spot.type == 'Water' ? AppTheme.markerBlue : AppTheme.markerGreen,
                      icon: Icons.ac_unit,
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
  const _Marker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-18, -18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x330F172A), blurRadius: 10)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
