import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../theme/app_theme.dart';

/// Map for the Route tab: draws the selected walking route as a polyline with
/// start/destination markers and nearby hot zones, and lets the user tap to set
/// a destination. Falls back to a painted placeholder when live maps are off.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    this.start,
    this.destination,
    this.routePoints = const [],
    this.alternatePoints = const [],
    this.hotZones = const [],
    this.onTap,
    this.height = 300,
    this.borderRadius = AppTheme.radiusLG,
  });

  final LatLng? start;
  final LatLng? destination;
  final List<LatLng> routePoints;

  /// Other (non-selected) routes, drawn faintly beneath the selected one.
  final List<List<LatLng>> alternatePoints;
  final List<HotZoneReport> hotZones;
  final ValueChanged<LatLng>? onTap;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final apiKey =
        dotenv.isInitialized ? dotenv.maybeGet('GOOGLE_MAPS_API_KEY') : null;
    final hasApiKey =
        apiKey != null && apiKey.isNotEmpty && !apiKey.startsWith('YOUR_');
    final useLiveMap = hasApiKey && AppConfig.enableLiveGoogleMaps;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: useLiveMap
            ? _LiveRouteMap(
                start: start,
                destination: destination,
                routePoints: routePoints,
                alternatePoints: alternatePoints,
                hotZones: hotZones,
                onTap: onTap,
              )
            : const _FallbackRouteMap(),
      ),
    );
  }
}

class _LiveRouteMap extends StatefulWidget {
  const _LiveRouteMap({
    this.start,
    this.destination,
    required this.routePoints,
    required this.alternatePoints,
    required this.hotZones,
    this.onTap,
  });

  final LatLng? start;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final List<List<LatLng>> alternatePoints;
  final List<HotZoneReport> hotZones;
  final ValueChanged<LatLng>? onTap;

  @override
  State<_LiveRouteMap> createState() => _LiveRouteMapState();
}

class _LiveRouteMapState extends State<_LiveRouteMap> {
  static const _bangkok = LatLng(13.7563, 100.5018);
  GoogleMapController? _controller;

  LatLng get _anchor => widget.start ?? widget.destination ?? _bangkok;

  @override
  void didUpdateWidget(_LiveRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routePoints.length != oldWidget.routePoints.length ||
        widget.destination != oldWidget.destination ||
        widget.start != oldWidget.start) {
      _fit();
    }
  }

  void _fit() {
    final controller = _controller;
    if (controller == null) return;
    final pts = <LatLng>[
      if (widget.routePoints.isNotEmpty)
        ...widget.routePoints
      else ...[
        if (widget.start != null) widget.start!,
        if (widget.destination != null) widget.destination!,
      ],
    ];
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
      return;
    }
    controller.animateCamera(CameraUpdate.newLatLngBounds(_bounds(pts), 56));
  }

  static LatLngBounds _bounds(List<LatLng> pts) {
    var minLat = pts.first.latitude, maxLat = pts.first.latitude;
    var minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    if (widget.start != null) {
      markers.add(Marker(
        markerId: const MarkerId('route-start'),
        position: widget.start!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Start'),
      ));
    }
    if (widget.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('route-destination'),
        position: widget.destination!,
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
    }
    for (final zone in widget.hotZones) {
      if (!zone.hasLatLng) continue;
      markers.add(Marker(
        markerId: MarkerId('route-hz-${zone.id.isNotEmpty ? zone.id : zone.title}'),
        position: LatLng(zone.lat!, zone.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          zone.risk == HeatRisk.medium
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueRed,
        ),
        alpha: 0.85,
        infoWindow: InfoWindow(title: zone.title, snippet: zone.location),
      ));
    }

    final polylines = <Polyline>{};
    // Alternates first (drawn beneath), faint grey.
    for (var i = 0; i < widget.alternatePoints.length; i++) {
      polylines.add(Polyline(
        polylineId: PolylineId('route-alt-$i'),
        points: widget.alternatePoints[i],
        color: AppTheme.textHint,
        width: 5,
      ));
    }
    // Selected route on top, in the brand colour.
    if (widget.routePoints.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routePoints,
        color: AppTheme.primary,
        width: 7,
        zIndex: 2,
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _anchor, zoom: 14),
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        _controller = controller;
        _fit();
      },
      onTap: widget.onTap,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}

class _FallbackRouteMap extends StatelessWidget {
  const _FallbackRouteMap();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppTheme.mapBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, color: AppTheme.textHint, size: 28),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Live map needed for the route preview.\nUse the search box to set a destination.',
                textAlign: TextAlign.center,
                style: tt.bodySmall!.copyWith(color: AppTheme.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
