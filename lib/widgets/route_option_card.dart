import 'package:flutter/material.dart';

import '../models/route_option.dart';
import '../theme/app_theme.dart';
import 'heat_risk_badge.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({super.key, required this.route, this.onSelect});

  final RouteOption route;
  final ValueChanged<RouteOption>? onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD, AppTheme.spaceSM + 4,
            AppTheme.spaceMD, AppTheme.spaceSM + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row: name · recommended badge · risk badge
            Row(
              children: [
                Expanded(
                  child: Text(route.name, style: tt.headlineMedium),
                ),
                if (route.badge != null) ...[
                  _RecommendedBadge(route.badge!),
                  const SizedBox(width: AppTheme.spaceSM),
                ],
                HeatRiskBadge(route.risk),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),
            // Summary
            Text(route.summary, style: tt.bodyMedium),
            const SizedBox(height: AppTheme.spaceSM + 2),
            // Stat row
            Row(
              children: [
                _Stat(icon: Icons.schedule_outlined, text: route.duration),
                const SizedBox(width: AppTheme.spaceSM + 2),
                _Stat(icon: Icons.straighten_outlined, text: route.distance),
                const SizedBox(width: AppTheme.spaceSM + 2),
                _Stat(icon: Icons.park_outlined, text: '${route.shadeLevel} shade'),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM + 4),
            // Select button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => onSelect?.call(route),
                child: const Text('Select route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: AppTheme.primaryDark),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceXS),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
