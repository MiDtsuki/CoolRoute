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
  final List<String> savedRoutes;
  final int reportCount;
  final int verifiedReportCount;

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfile(
      id: docId,
      name: map['name'] as String? ?? 'Anonymous',
      role: map['role'] as String? ?? 'Student',
      location: map['location'] as String? ?? 'Bangkok, Thailand',
      riskProfile: map['riskProfile'] as String? ?? 'Normal',
      savedRoutes: List<String>.from(map['savedRoutes'] as List? ?? []),
      reportCount: (map['reportCount'] as num?)?.toInt() ?? 0,
      verifiedReportCount: (map['verifiedReportCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'location': location,
        'riskProfile': riskProfile,
        'savedRoutes': savedRoutes,
        'reportCount': reportCount,
        'verifiedReportCount': verifiedReportCount,
      };
}
