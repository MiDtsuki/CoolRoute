import 'package:cloud_firestore/cloud_firestore.dart';

class CoolSpot {
  const CoolSpot({
    this.id = '',
    required this.name,
    required this.type,
    required this.distance,
    required this.amenity,
    required this.openStatus,
    required this.verifiedBy,
    required this.x,
    required this.y,
    this.lat,
    this.lng,
    this.category = '',
    this.source = 'community',
    this.distanceMeters,
    this.createdAt,
    this.userId = '',
  });

  final String id;
  final String name;

  /// Theme/marker bucket: 'Water', 'Shade', 'Air-conditioned', or 'Indoor cooling'.
  final String type;

  /// Human-readable distance, e.g. "180 m" / "1.2 km".
  final String distance;
  final String amenity;
  final String openStatus;
  final int verifiedBy;

  /// Relative position (0–1) used only by the painted fallback map.
  final double x;
  final double y;

  /// Real-world coordinates. Null for legacy dummy spots that only carry x/y.
  final double? lat;
  final double? lng;

  /// Specific place category for display, e.g. "Library", "Water refill station".
  final String category;

  /// Where this spot came from: 'community' (user reports) or 'OpenStreetMap'.
  final String source;

  /// Raw metres from the user when known (used for sorting).
  final double? distanceMeters;

  /// When this spot was submitted (used for 48-hour auto-expiry on community spots).
  final DateTime? createdAt;

  /// UID of the user who submitted this spot.
  final String userId;

  bool get hasLatLng => lat != null && lng != null;

  /// The label to show as the spot's category — falls back to the marker type.
  String get displayCategory => category.isEmpty ? type : category;

  factory CoolSpot.fromMap(Map<String, dynamic> map, String docId) {
    return CoolSpot(
      id: docId,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      distance: map['distance'] as String? ?? '',
      amenity: map['amenity'] as String? ?? '',
      openStatus: map['openStatus'] as String? ?? 'Unknown',
      verifiedBy: (map['verifiedBy'] as num?)?.toInt() ?? 0,
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      category: map['category'] as String? ?? '',
      source: map['source'] as String? ?? 'community',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      userId: map['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'distance': distance,
        'amenity': amenity,
        'openStatus': openStatus,
        'verifiedBy': verifiedBy,
        'x': x,
        'y': y,
        'lat': ?lat,
        'lng': ?lng,
        'category': category,
        'source': source,
      };

  CoolSpot copyWith({
    String? distance,
    double? distanceMeters,
    double? x,
    double? y,
  }) {
    return CoolSpot(
      id: id,
      name: name,
      type: type,
      distance: distance ?? this.distance,
      amenity: amenity,
      openStatus: openStatus,
      verifiedBy: verifiedBy,
      x: x ?? this.x,
      y: y ?? this.y,
      lat: lat,
      lng: lng,
      category: category,
      source: source,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
