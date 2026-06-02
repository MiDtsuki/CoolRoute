import 'package:flutter/material.dart';

import '../models/cool_spot.dart';
import '../theme/app_theme.dart';

class CoolSpotCard extends StatelessWidget {
  const CoolSpotCard({super.key, required this.spot, this.onView});

  final CoolSpot spot;
  final ValueChanged<CoolSpot>? onView;

  Color get _iconBg => switch (spot.type) {
        'Air-conditioned'        => AppTheme.spotBgBlue,
        'Water'                  => AppTheme.spotBgBlue,
        'Shade'                  => AppTheme.riskLowBg,
        _                        => AppTheme.primaryLight,
      };

  Color get _iconColor => switch (spot.type) {
        'Air-conditioned' || 'Water' => AppTheme.markerBlue,
        'Shade'                       => AppTheme.riskNone,
        _                             => AppTheme.primary,
      };

  IconData get _icon => switch (spot.type) {
        'Air-conditioned' => Icons.ac_unit,
        'Water'           => Icons.water_drop_outlined,
        'Shade'           => Icons.park_outlined,
        _                 => Icons.store_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSM + 4),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name, style: tt.bodyLarge),
                  const SizedBox(height: 2),
                  Text(spot.type, style: tt.bodySmall),
                  const SizedBox(height: AppTheme.spaceXS + 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${spot.distance} · ${spot.verifiedBy} verified',
                          style: tt.labelSmall!.copyWith(color: AppTheme.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceXS + 2),
                      _StatusBadge(spot.openStatus),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM + 2),
            OutlinedButton(
              onPressed: () => onView?.call(spot),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(52, 34),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM + 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  Color get _bg => switch (status) {
        'Open' || 'Working' => AppTheme.statusOpenBg,
        'Available'          => AppTheme.primaryLight,
        'Closed'             => AppTheme.statusClosedBg,
        'Pending'            => AppTheme.markerOrange.withValues(alpha: .14),
        _                    => AppTheme.statusOpenBg,
      };

  Color get _fg => switch (status) {
        'Open' || 'Working' => AppTheme.statusOpen,
        'Available'          => AppTheme.primaryDark,
        'Closed'             => AppTheme.statusClosed,
        'Pending'            => AppTheme.markerOrange,
        _                    => AppTheme.statusOpen,
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          status,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: _fg),
        ),
      ),
    );
  }
}
