import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/environmental_layer.dart';
import '../services/nasa_gibs_service.dart';
import '../theme/app_theme.dart';

/// Live, pannable NASA GIBS map for one [EnvironmentalLayer].
///
/// Streams WMTS tiles (EPSG:3857) instead of a single static snapshot:
/// a static Blue Marble basemap underneath, the selected science layer on
/// top, and coastline outlines above that. All endpoints are free and need
/// no API key. Web-safe — flutter_map is pure Dart over Flutter canvas.
class GibsTileMap extends StatefulWidget {
  const GibsTileMap({
    super.key,
    required this.layer,
    required this.date,
    required this.gibs,
    required this.fallback,
  });

  /// The layer to render. Must have a non-null [EnvironmentalLayer.gibsLayerId].
  final EnvironmentalLayer layer;
  final DateTime date;
  final NasaGibsService gibs;

  /// Shown beneath the map as the loading/offline backdrop.
  final Widget fallback;

  @override
  State<GibsTileMap> createState() => _GibsTileMapState();
}

class _GibsTileMapState extends State<GibsTileMap> {
  // Bangkok — the app's anchor location (see CLAUDE.md dummy-data rules).
  static const _bangkok = LatLng(13.7563, 100.5018);

  static const _minZoom = 1.0;
  static const _maxZoom = 9.0;

  // Web-Mercator world extent. Constraining the camera to this keeps the view
  // pinned to a single Earth — no horizontal world-copy duplication when
  // zoomed out, on either web or mobile.
  static final _worldBounds = LatLngBounds(
    const LatLng(-85.05112878, -180),
    const LatLng(85.05112878, 180),
  );

  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    final next = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    if (next == camera.zoom) return;
    _controller.move(camera.center, next);
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final date = widget.date;
    final gibs = widget.gibs;
    final layerId = layer.gibsLayerId!;
    final dataTemplate = gibs.wmtsTemplate(
      layerId: layerId,
      tileMatrixSet: layer.gibsTileMatrixSet,
      format: layer.gibsFormat,
      date: date,
      monthly: layer.gibsMonthly,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.fallback,
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _bangkok,
            initialZoom: 5,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            backgroundColor: AppTheme.bgDark,
            // Single-world view: block panning past the date line and stop the
            // camera ever showing the void above/below the poles.
            cameraConstraint: CameraConstraint.contain(bounds: _worldBounds),
          ),
          children: [
            // Static reference basemap (no time dimension).
            TileLayer(
              urlTemplate: gibs.basemapTemplate,
              maxNativeZoom: 8,
              userAgentPackageName: 'com.coolroute.app',
            ),
            // The selected science layer, keyed on date so a date change
            // forces fresh tiles rather than reusing the cached layer.
            Opacity(
              opacity: 0.85,
              child: TileLayer(
                key: ValueKey('$layerId-${date.toIso8601String()}'),
                urlTemplate: dataTemplate,
                maxNativeZoom: layer.gibsMaxZoom,
                userAgentPackageName: 'com.coolroute.app',
              ),
            ),
            // Coastline + border outlines on top for orientation.
            TileLayer(
              urlTemplate: gibs.coastlinesTemplate,
              maxNativeZoom: 13,
              userAgentPackageName: 'com.coolroute.app',
            ),
            const _Attribution(),
          ],
        ),
        _ZoomControls(
          onZoomIn: () => _zoomBy(1),
          onZoomOut: () => _zoomBy(-1),
        ),
      ],
    );
  }
}

/// Compact zoom in/out stack pinned to the bottom-left of the GIBS map.
class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.textOnDarkDim),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onTap: onZoomIn,
              ),
              const SizedBox(
                width: 28,
                child: Divider(height: 1, color: AppTheme.textOnDarkDim),
              ),
              _ZoomButton(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onTap: onZoomOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppTheme.textOnDark),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXS),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              'NASA GIBS · EOSDIS',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: AppTheme.textOnDarkDim),
            ),
          ),
        ),
      ),
    );
  }
}
