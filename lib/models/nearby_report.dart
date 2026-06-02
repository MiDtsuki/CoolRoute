import 'heat_risk.dart';

class NearbyReport {
  const NearbyReport({
    required this.id,
    required this.title,
    required this.location,
    required this.distance,
    required this.risk,
    required this.timeAgo,
    required this.verifications,
  });

  final String id;
  final String title;
  final String location;
  final String distance;
  final HeatRisk risk;
  final String timeAgo;
  final int verifications;

  factory NearbyReport.fromMap(Map<String, dynamic> map, String docId) {
    return NearbyReport(
      id: docId,
      title: map['title'] as String? ?? '',
      location: map['location'] as String? ?? '',
      distance: map['distance'] as String? ?? 'Nearby',
      risk: HeatRisk.values.byName(map['risk'] as String? ?? 'medium'),
      timeAgo: map['timeAgo'] as String? ?? 'recently',
      verifications: (map['verifications'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'location': location,
        'distance': distance,
        'risk': risk.name,
        'timeAgo': timeAgo,
        'verifications': verifications,
      };
}
