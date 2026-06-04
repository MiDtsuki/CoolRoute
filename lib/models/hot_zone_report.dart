import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.resolvedBy = const [],
    this.createdAt,
    this.userId = '',
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

  /// User ids that pressed "Problem fixed" — 3 triggers auto-delete.
  final List<String> resolvedBy;

  /// When this report was created (used for 48-hour auto-expiry).
  final DateTime? createdAt;

  /// UID of the user who submitted this report.
  final String userId;

  /// Relative position (0–1) used only by the painted fallback map.
  final double x;
  final double y;

  /// Real-world coordinates. Null for legacy reports that only carry x/y.
  final double? lat;
  final double? lng;

  bool get hasLatLng => lat != null && lng != null;

  bool isVerifiedBy(String? uid) => uid != null && verifiedBy.contains(uid);
  bool isResolvedBy(String? uid) => uid != null && resolvedBy.contains(uid);

  /// Human-readable relative timestamp computed from [createdAt].
  /// Falls back to the stored [timeAgo] string for legacy docs without a timestamp.
  String get displayTimeAgo {
    final ts = createdAt;
    if (ts == null) return timeAgo;
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    // Older than a week — show the date.
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[ts.month - 1]} ${ts.day}';
  }

  bool get isExpired {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!) > const Duration(hours: 48);
  }

  HotZoneReport copyWith({
    int? verifications,
    String? timeAgo,
    List<String>? verifiedBy,
    List<String>? resolvedBy,
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
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt,
      userId: userId,
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
      resolvedBy: List<String>.from(map['resolvedBy'] as List? ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      userId: map['userId'] as String? ?? '',
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
        'userId': userId,
      };
}
