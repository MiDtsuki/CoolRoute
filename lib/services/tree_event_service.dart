import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/dummy_tree_pins.dart';
import '../models/tree_pin.dart';

/// Community tree-planting events in the Firestore `treeEvents` collection.
/// Falls back to the bundled dummy events when Firestore is empty/unavailable.
class TreeEventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<TreePin>> getEvents() async {
    try {
      final snapshot = await _db
          .collection('treeEvents')
          .orderBy('createdAt', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return DummyTreePins.pins;
      return snapshot.docs
          .map((doc) => TreePin.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return DummyTreePins.pins;
    }
  }

  /// Creates a new tree-planting event and returns its document id.
  Future<String> createEvent({
    required String title,
    required String locationName,
    required String when,
    required String description,
    required String organizer,
    int goalTrees = 0,
    double? lat,
    double? lng,
    double x = 0.5,
    double y = 0.5,
    String? userId,
  }) async {
    final ref = await _db.collection('treeEvents').add({
      'title': title,
      'locationName': locationName,
      'datePlanted': when,
      'description': description,
      'plantedBy': organizer,
      'goalTrees': goalTrees,
      'x': x,
      'y': y,
      'lat': ?lat,
      'lng': ?lng,
      'rsvpBy': <String>[],
      'waterBy': <String>[],
      'donateBy': <String>[],
      'attendBy': <String>[],
      'userId': userId ?? 'anonymous',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Records a contribution by [userId] to [eventId], enforcing **one per user
  /// per action** via a transaction. Returns `true` if newly added, `false` if
  /// the user already contributed that way (or the event no longer exists).
  Future<bool> contribute(String eventId, String userId, TreeAction action) async {
    final field = action.field;
    final ref = _db.collection('treeEvents').doc(eventId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final list = List<String>.from((snap.data()?[field] as List?) ?? const []);
      if (list.contains(userId)) return false;
      list.add(userId);
      tx.update(ref, {field: list});
      return true;
    });
  }
}
