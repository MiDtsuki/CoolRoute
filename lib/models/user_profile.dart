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
}
