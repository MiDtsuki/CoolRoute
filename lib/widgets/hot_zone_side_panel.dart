import 'package:flutter/material.dart';

import '../models/hot_zone_report.dart';
import '../models/nearby_report.dart';
import '../theme/app_theme.dart';
import 'hot_zone_bottom_sheet.dart';

class HotZoneSidePanel extends StatelessWidget {
  const HotZoneSidePanel({
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
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(left: BorderSide(color: AppTheme.borderLight, width: 0.5)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD, AppTheme.spaceSM, AppTheme.spaceXS, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Zone details',
                      style: Theme.of(context).textTheme.labelLarge,
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
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceLG),
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
