/// A route the user saved to their profile. Stores the destination coordinates
/// so it can be re-planned when reopened (older entries may be name-only).
class SavedRoute {
  const SavedRoute({required this.name, this.destLat, this.destLng});

  final String name;
  final double? destLat;
  final double? destLng;

  bool get hasDestination => destLat != null && destLng != null;

  /// Accepts either a legacy plain-string entry or a `{name, destLat, destLng}`
  /// map (how routes are stored now).
  factory SavedRoute.fromDynamic(dynamic value) {
    if (value is String) return SavedRoute(name: value);
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      return SavedRoute(
        name: map['name'] as String? ?? 'Saved route',
        destLat: (map['destLat'] as num?)?.toDouble(),
        destLng: (map['destLng'] as num?)?.toDouble(),
      );
    }
    return const SavedRoute(name: 'Saved route');
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'destLat': ?destLat,
        'destLng': ?destLng,
      };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.riskProfile,
    required this.savedRoutes,
    required this.reportCount,
    required this.verifiedReportCount,
  });

  final String id;
  final String name;
  final String role;
  final String location;
  final String riskProfile;
  final List<SavedRoute> savedRoutes;
  final int reportCount;
  final int verifiedReportCount;

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfile(
      id: docId,
      name: map['name'] as String? ?? 'Anonymous',
      role: map['role'] as String? ?? 'Student',
      location: map['location'] as String? ?? 'Bangkok, Thailand',
      riskProfile: map['riskProfile'] as String? ?? 'Normal',
      savedRoutes: ((map['savedRoutes'] as List?) ?? const [])
          .map(SavedRoute.fromDynamic)
          .toList(),
      reportCount: (map['reportCount'] as num?)?.toInt() ?? 0,
      verifiedReportCount: (map['verifiedReportCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'location': location,
        'riskProfile': riskProfile,
        'savedRoutes': savedRoutes.map((r) => r.toMap()).toList(),
        'reportCount': reportCount,
        'verifiedReportCount': verifiedReportCount,
      };
}
