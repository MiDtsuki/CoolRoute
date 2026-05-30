enum HeatRisk { low, medium, high, extreme }

extension HeatRiskLabel on HeatRisk {
  String get label => switch (this) {
    HeatRisk.low => 'Low Risk',
    HeatRisk.medium => 'Medium Risk',
    HeatRisk.high => 'High Risk',
    HeatRisk.extreme => 'Extreme Risk',
  };
}
