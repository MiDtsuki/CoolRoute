import 'package:cloud_firestore/cloud_firestore.dart';
import '../dummy_data/dummy_data.dart';

// Populates Firestore with dummy data if the collections are empty.
// Call once after Firebase.initializeApp() to bootstrap a fresh project.
class FirestoreSeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedIfEmpty() async {
    await Future.wait([_seedHotZones(), _seedCoolSpots()]);
  }

  Future<void> _seedHotZones() async {
    final existing = await _db.collection('hotZones').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final zone in DummyData.hotZones) {
      final ref = _db.collection('hotZones').doc();
      batch.set(ref, {
        ...zone.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': 'seed',
      });
    }
    await batch.commit();
  }

  Future<void> _seedCoolSpots() async {
    final existing = await _db.collection('coolSpots').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final spot in DummyData.coolSpots) {
      final ref = _db.collection('coolSpots').doc();
      batch.set(ref, {
        ...spot.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': 'seed',
      });
    }
    await batch.commit();
  }
}
