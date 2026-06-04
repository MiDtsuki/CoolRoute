/// Ways a community member can contribute to a tree-planting event.
enum TreeAction { rsvp, water, donate, attend }

extension TreeActionInfo on TreeAction {
  String get field => switch (this) {
        TreeAction.rsvp => 'rsvpBy',
        TreeAction.water => 'waterBy',
        TreeAction.donate => 'donateBy',
        TreeAction.attend => 'attendBy',
      };
  String get label => switch (this) {
        TreeAction.rsvp => 'RSVP',
        TreeAction.water => 'Water',
        TreeAction.donate => 'Donate',
        TreeAction.attend => 'Attend',
      };
}

/// A community tree-planting event. (Historically a "planted tree pin"; now it
/// models a planned planting others can contribute to.) Backed by the Firestore
/// `treeEvents` collection.
class TreePin {
  const TreePin({
    this.id = '',
    required this.title,
    required this.locationName,
    required this.datePlanted,
    required this.description,
    required this.plantedBy,
    required this.x,
    required this.y,
    this.lat,
    this.lng,
    this.goalTrees = 0,
    this.rsvpBy = const [],
    this.waterBy = const [],
    this.donateBy = const [],
    this.attendBy = const [],
  });

  final String id;
  final String title;
  final String locationName;

  /// When the planting happens (event date/time label).
  final String datePlanted;
  final String description;

  /// Organizer handle.
  final String plantedBy;
  final double x;
  final double y;
  final double? lat;
  final double? lng;
  final int goalTrees;

  // User ids per contribution type (one contribution per user per type).
  final List<String> rsvpBy;
  final List<String> waterBy;
  final List<String> donateBy;
  final List<String> attendBy;

  bool get hasLatLng => lat != null && lng != null;

  List<String> _listFor(TreeAction action) => switch (action) {
        TreeAction.rsvp => rsvpBy,
        TreeAction.water => waterBy,
        TreeAction.donate => donateBy,
        TreeAction.attend => attendBy,
      };

  int countFor(TreeAction action) => _listFor(action).length;

  bool hasJoined(TreeAction action, String? uid) =>
      uid != null && _listFor(action).contains(uid);

  /// A copy with [uid] added to [action]'s contributor list (optimistic update).
  TreePin withJoined(TreeAction action, String uid) => copyWith(
        rsvpBy: action == TreeAction.rsvp ? [...rsvpBy, uid] : null,
        waterBy: action == TreeAction.water ? [...waterBy, uid] : null,
        donateBy: action == TreeAction.donate ? [...donateBy, uid] : null,
        attendBy: action == TreeAction.attend ? [...attendBy, uid] : null,
      );

  TreePin copyWith({
    List<String>? rsvpBy,
    List<String>? waterBy,
    List<String>? donateBy,
    List<String>? attendBy,
  }) {
    return TreePin(
      id: id,
      title: title,
      locationName: locationName,
      datePlanted: datePlanted,
      description: description,
      plantedBy: plantedBy,
      x: x,
      y: y,
      lat: lat,
      lng: lng,
      goalTrees: goalTrees,
      rsvpBy: rsvpBy ?? this.rsvpBy,
      waterBy: waterBy ?? this.waterBy,
      donateBy: donateBy ?? this.donateBy,
      attendBy: attendBy ?? this.attendBy,
    );
  }

  factory TreePin.fromMap(Map<String, dynamic> map, String docId) {
    List<String> list(String key) =>
        List<String>.from(map[key] as List? ?? const []);
    return TreePin(
      id: docId,
      title: map['title'] as String? ?? '',
      locationName: map['locationName'] as String? ?? '',
      datePlanted: map['datePlanted'] as String? ?? map['when'] as String? ?? '',
      description: map['description'] as String? ?? '',
      plantedBy: map['plantedBy'] as String? ?? map['organizer'] as String? ?? 'community',
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      goalTrees: (map['goalTrees'] as num?)?.toInt() ?? 0,
      rsvpBy: list('rsvpBy'),
      waterBy: list('waterBy'),
      donateBy: list('donateBy'),
      attendBy: list('attendBy'),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'locationName': locationName,
        'datePlanted': datePlanted,
        'description': description,
        'plantedBy': plantedBy,
        'x': x,
        'y': y,
        'lat': ?lat,
        'lng': ?lng,
        'goalTrees': goalTrees,
        'rsvpBy': rsvpBy,
        'waterBy': waterBy,
        'donateBy': donateBy,
        'attendBy': attendBy,
      };
}
