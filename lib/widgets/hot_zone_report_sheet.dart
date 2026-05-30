import 'package:flutter/material.dart';

import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../screens/reports/report_details_screen.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'heat_risk_badge.dart';

class HotZoneReportSheet extends StatelessWidget {
  const HotZoneReportSheet({
    super.key,
    required this.report,
    required this.nearbyReports,
  });

  final HotZoneReport report;
  final List<HotZoneReport> nearbyReports;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .76,
      minChildSize: .44,
      maxChildSize: .94,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 34),
                  SizedBox(height: 8),
                  Text(
                    'Report image placeholder',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                HeatRiskBadge(report.risk),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(report.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(icon: Icons.category_outlined, label: 'Category', value: report.category),
                _InfoPill(icon: Icons.schedule, label: 'Reported', value: report.timeAgo),
                _InfoPill(icon: Icons.verified, label: 'Verified', value: '${report.verifications}'),
                _InfoPill(icon: Icons.groups_outlined, label: 'Status', value: _communityStatus),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Still hot'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Problem fixed'),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportDetailsScreen(),
                    ),
                  );
                },
                child: const Text('View details'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Other reports nearby',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < nearbyReports.length; i++)
              _NearbyReportItem(report: nearbyReports[i], distance: _dummyDistance(i)),
          ],
        ),
      ),
    );
  }

  String get _communityStatus {
    if (report.verifications >= 10) return 'Community confirmed';
    if (report.verifications >= 5) return 'Needs monitoring';
    return 'New report';
  }

  static String _dummyDistance(int index) {
    const distances = ['120 m', '240 m', '390 m'];
    return distances[index % distances.length];
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyReportItem extends StatelessWidget {
  const _NearbyReportItem({required this.report, required this.distance});

  final HotZoneReport report;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _riskColor.withValues(alpha: .12),
              child: Icon(Icons.local_fire_department, color: _riskColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(distance, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            HeatRiskBadge(report.risk),
          ],
        ),
      ),
    );
  }

  Color get _riskColor => switch (report.risk) {
        HeatRisk.low => AppColors.safe,
        HeatRisk.medium => AppColors.high,
        HeatRisk.high || HeatRisk.extreme => AppColors.extreme,
      };
}
