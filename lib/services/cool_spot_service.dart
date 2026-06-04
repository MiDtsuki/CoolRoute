import 'package:cloud_firestore/cloud_firestore.dart';
import '../dummy_data/dummy_data.dart';
import '../models/cool_spot.dart';

class CoolSpotService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CoolSpot>> getCoolSpots() async {
    try {
      final snapshot = await _db
          .collection('coolSpots')
          .orderBy('verifiedBy', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return DummyData.coolSpots;
      return snapshot.docs
          .map((doc) => CoolSpot.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return DummyData.coolSpots;
    }
  }

  /// Persists a community-suggested cool spot and returns its new document id.
  Future<String> submitCoolSpot({
    required String name,
    required String type,
    required String amenity,
    required String openStatus,
    required double x,
    required double y,
    String category = '',
    double? lat,
    double? lng,
    String distance = 'Nearby',
    String? userId,
  }) async {
    final ref = await _db.collection('coolSpots').add({
      'name': name,
      'type': type,
      'category': category,
      'distance': distance,
      'amenity': amenity,
      'openStatus': openStatus,
      'verifiedBy': 1,
      'x': x,
      'y': y,
      'lat': ?lat,
      'lng': ?lng,
      'source': 'community',
      'userId': userId ?? 'anonymous',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> verifyCoolSpot(String spotId) async {
    await _db.collection('coolSpots').doc(spotId).update({
      'verifiedBy': FieldValue.increment(1),
    });
  }
}
