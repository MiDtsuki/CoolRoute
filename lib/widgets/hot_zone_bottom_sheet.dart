import 'package:flutter/material.dart';

import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../models/nearby_report.dart';
import '../screens/reports/report_details_screen.dart';
import '../theme/app_theme.dart';

class HotZoneBottomSheet extends StatelessWidget {
  const HotZoneBottomSheet({
    super.key,
    required this.report,
    required this.nearbyReports,
    this.onClose,
    this.onVerify,
    this.alreadyVerified = false,
  });

  final HotZoneReport report;
  final List<NearbyReport> nearbyReports;
  final VoidCallback? onClose;
  final ValueChanged<HotZoneReport>? onVerify;
  final bool alreadyVerified;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.65;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spaceMD, 10, AppTheme.spaceXS, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.borderMid,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: const SizedBox(width: 32, height: 4),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.textHint,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMD, AppTheme.spaceXS, AppTheme.spaceMD, AppTheme.spaceLG),
                child: ReportPanelContent(
                    report: report,
                    nearbyReports: nearbyReports,
                    onVerify: onVerify,
                    alreadyVerified: alreadyVerified),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared content (used by both bottom sheet and side panel) ─────────────────

class ReportPanelContent extends StatelessWidget {
  const ReportPanelContent({
    super.key,
    required this.report,
    required this.nearbyReports,
    this.onVerify,
    this.alreadyVerified = false,
  });

  final HotZoneReport report;
  final List<NearbyReport> nearbyReports;
  final ValueChanged<HotZoneReport>? onVerify;
  final bool alreadyVerified;

  Color get _riskColor => switch (report.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtreme,
        HeatRisk.medium                   => AppTheme.riskMedium,
        HeatRisk.low                      => AppTheme.riskLow,
      };

  Color get _riskBg => switch (report.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtremeBg,
        HeatRisk.medium                   => AppTheme.riskMediumBg,
        HeatRisk.low                      => AppTheme.riskLowBg,
      };

  String get _riskLabel => switch (report.risk) {
        HeatRisk.extreme => 'Extreme heat',
        HeatRisk.high    => 'High heat',
        HeatRisk.medium  => 'Medium heat',
        HeatRisk.low     => 'Low heat',
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report.title, style: tt.headlineMedium),
        const SizedBox(height: AppTheme.spaceSM),
        Row(children: [
          const Icon(Icons.place_outlined, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Expanded(child: Text(report.location, style: tt.bodySmall)),
        ]),
        const SizedBox(height: AppTheme.spaceSM + 4),
        Row(children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: _riskBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Text(_riskLabel, style: tt.labelSmall!.copyWith(color: _riskColor)),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Flexible(child: Text(report.category, style: tt.bodySmall)),
        ]),
        const SizedBox(height: AppTheme.spaceMD),
        Text(report.description, style: tt.bodyMedium),
        const SizedBox(height: AppTheme.spaceMD),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgPage,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.borderLight, width: 0.5),
          ),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_outlined, size: 20, color: AppTheme.textHint),
              const SizedBox(height: 4),
              Text('No photo yet', style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
            ]),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        Row(children: [
          const Icon(Icons.schedule_outlined, size: 13, color: AppTheme.textHint),
          const SizedBox(width: 4),
          Text(report.timeAgo, style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
          const SizedBox(width: AppTheme.spaceMD),
          const Icon(Icons.verified_outlined, size: 13, color: AppTheme.textHint),
          const SizedBox(width: 4),
          Text('Verified by ${report.verifications} users',
              style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
        ]),
        const SizedBox(height: AppTheme.spaceMD),
        if (alreadyVerified) ...[
          Row(children: [
            const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text('You verified this report',
                style: tt.bodySmall!.copyWith(color: AppTheme.primary)),
          ]),
          const SizedBox(height: AppTheme.spaceSM),
        ],
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: (onVerify == null || alreadyVerified)
                  ? null
                  : () => onVerify!(report),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.riskExtreme,
                side: const BorderSide(color: AppTheme.riskExtreme),
              ),
              child: const Text('Still hot'),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: OutlinedButton(
              onPressed: (onVerify == null || alreadyVerified)
                  ? null
                  : () => onVerify!(report),
              child: const Text('Problem fixed'),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReportDetailsScreen()),
              ),
              child: const Text('View details'),
            ),
          ),
        ]),
        const SizedBox(height: AppTheme.spaceMD),
        const Divider(),
        const SizedBox(height: AppTheme.spaceSM),
        Text('Nearby reports', style: tt.labelLarge),
        const SizedBox(height: AppTheme.spaceSM),
        for (final r in nearbyReports) _NearbyReportRow(report: r),
      ],
    );
  }
}

// ── Nearby row ────────────────────────────────────────────────────────────────

class _NearbyReportRow extends StatelessWidget {
  const _NearbyReportRow({required this.report});

  final NearbyReport report;

  Color get _dot => switch (report.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtreme,
        HeatRisk.medium                   => AppTheme.riskMedium,
        HeatRisk.low                      => AppTheme.riskLow,
      };

  Color get _badgeBg => switch (report.risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtremeBg,
        HeatRisk.medium                   => AppTheme.riskMediumBg,
        HeatRisk.low                      => AppTheme.riskLowBg,
      };

  String get _label => switch (report.risk) {
        HeatRisk.extreme => 'Extreme',
        HeatRisk.high    => 'High',
        HeatRisk.medium  => 'Medium',
        HeatRisk.low     => 'Low',
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(children: [
        DecoratedBox(
          decoration: BoxDecoration(color: _dot, shape: BoxShape.circle),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(
          child: Text(report.title,
              style: tt.bodyMedium!.copyWith(color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Text(report.distance, style: tt.bodySmall),
        const SizedBox(width: AppTheme.spaceSM),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _badgeBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(_label, style: tt.labelSmall!.copyWith(color: _dot)),
          ),
        ),
      ]),
    );
  }
}
