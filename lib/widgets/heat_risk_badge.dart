import 'package:flutter/material.dart';

import '../models/heat_risk.dart';
import '../theme/app_theme.dart';

class HeatRiskBadge extends StatelessWidget {
  const HeatRiskBadge(this.risk, {super.key});

  final HeatRisk risk;

  Color get _bg => switch (risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtremeBg,
        HeatRisk.medium                   => AppTheme.riskMediumBg,
        HeatRisk.low                      => AppTheme.riskLowBg,
      };

  Color get _text => switch (risk) {
        HeatRisk.extreme || HeatRisk.high => AppTheme.riskExtremeText,
        HeatRisk.medium                   => AppTheme.riskMediumText,
        HeatRisk.low                      => AppTheme.riskLowText,
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          risk.label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: _text),
        ),
      ),
    );
  }
}
