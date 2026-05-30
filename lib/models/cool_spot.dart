class CoolSpot {
  const CoolSpot({
    required this.name,
    required this.type,
    required this.distance,
    required this.amenity,
    required this.openStatus,
    required this.verifiedBy,
    required this.x,
    required this.y,
  });

  final String name;
  final String type;
  final String distance;
  final String amenity;
  final String openStatus;
  final int verifiedBy;
  final double x;
  final double y;
}
