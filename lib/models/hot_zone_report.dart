import 'heat_risk.dart';

class HotZoneReport {
  const HotZoneReport({
    this.id = '',
    required this.title,
    required this.location,
    required this.category,
    required this.description,
    required this.timeAgo,
    required this.verifications,
    required this.risk,
    required this.x,
    required this.y,
    this.lat,
    this.lng,
    this.verifiedBy = const [],
  });

  final String id;
  final String title;
  final String location;
  final String category;
  final String description;
  final String timeAgo;
  final int verifications;
  final HeatRisk risk;

  /// User ids that have already verified this report (one verification each).
  final List<String> verifiedBy;

  /// Relative position (0–1) used only by the painted fallback map.
  final double x;
  final double y;

  /// Real-world coordinates. Null for legacy reports that only carry x/y.
  final double? lat;
  final double? lng;

  bool get hasLatLng => lat != null && lng != null;

  bool isVerifiedBy(String? uid) => uid != null && verifiedBy.contains(uid);

  HotZoneReport copyWith({
    int? verifications,
    String? timeAgo,
    List<String>? verifiedBy,
  }) {
    return HotZoneReport(
      id: id,
      title: title,
      location: location,
      category: category,
      description: description,
      timeAgo: timeAgo ?? this.timeAgo,
      verifications: verifications ?? this.verifications,
      risk: risk,
      x: x,
      y: y,
      lat: lat,
      lng: lng,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  factory HotZoneReport.fromMap(Map<String, dynamic> map, String docId) {
    return HotZoneReport(
      id: docId,
      title: map['title'] as String? ?? '',
      location: map['location'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      timeAgo: map['timeAgo'] as String? ?? 'recently',
      verifications: (map['verifications'] as num?)?.toInt() ?? 0,
      risk: HeatRisk.values.byName(map['risk'] as String? ?? 'medium'),
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      verifiedBy: List<String>.from(map['verifiedBy'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'location': location,
        'category': category,
        'description': description,
        'timeAgo': timeAgo,
        'verifications': verifications,
        'risk': risk.name,
        'x': x,
        'y': y,
        'lat': ?lat,
        'lng': ?lng,
      };
}
