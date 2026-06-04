import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// A real map location picker: the user pans a live Google map under a fixed
/// centre pin; the picked point is the map centre (reported on camera idle).
/// Falls back to a note that the current location will be used when live maps
/// are unavailable.
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    super.key,
    required this.initialLocation,
    required this.onChanged,
    this.label,
    this.pinColor = AppTheme.markerTree,
    this.pinIcon = Icons.place,
    this.height = 200,
  });

  final LatLng initialLocation;
  final ValueChanged<LatLng> onChanged;
  final String? label;
  final Color pinColor;
  final IconData pinIcon;
  final double height;

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _center = widget.initialLocation;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final apiKey =
        dotenv.isInitialized ? dotenv.maybeGet('GOOGLE_MAPS_API_KEY') : null;
    final hasApiKey =
        apiKey != null && apiKey.isNotEmpty && !apiKey.startsWith('YOUR_');
    final useLiveMap = hasApiKey && AppConfig.enableLiveGoogleMaps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: tt.labelLarge),
          const SizedBox(height: AppTheme.spaceSM),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: useLiveMap ? _liveMap() : _fallback(tt),
          ),
        ),
      ],
    );
  }

  Widget _liveMap() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: widget.initialLocation, zoom: 16),
          onCameraMove: (pos) => _center = pos.target,
          onCameraIdle: () => widget.onChanged(_center),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),
        // Fixed centre pin — its tip marks the chosen point.
        Transform.translate(
          offset: const Offset(0, -14),
          child: Icon(widget.pinIcon, color: widget.pinColor, size: 34),
        ),
        Positioned(
          left: AppTheme.spaceSM,
          bottom: AppTheme.spaceSM,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(color: AppTheme.borderLight, width: .5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS),
              child: Text('Drag map to place pin',
                  style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(TextTheme tt) {
    return ColoredBox(
      color: AppTheme.mapBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.pinIcon, color: widget.pinColor, size: 26),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Live map unavailable — your current location will be used.',
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
