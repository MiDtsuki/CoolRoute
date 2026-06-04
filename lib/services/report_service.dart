import 'package:cloud_firestore/cloud_firestore.dart';
import '../dummy_data/dummy_data.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../models/nearby_report.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<HotZoneReport>> getHotZoneReports() async {
    try {
      final snapshot = await _db
          .collection('hotZones')
          .orderBy('createdAt', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return DummyData.hotZones;
      return snapshot.docs
          .map((doc) => HotZoneReport.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return DummyData.hotZones;
    }
  }

  Future<List<NearbyReport>> getNearbyReports() async {
    try {
      final snapshot = await _db
          .collection('hotZones')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      if (snapshot.docs.isEmpty) return DummyData.nearbyReports;
      return snapshot.docs
          .map((doc) => NearbyReport.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return DummyData.nearbyReports;
    }
  }

  /// Persists a new hot-zone report and returns the new Firestore document id.
  Future<String> submitHotZoneReport({
    required String title,
    required String location,
    required String category,
    required String description,
    required HeatRisk risk,
    required double x,
    required double y,
    double? lat,
    double? lng,
    String? userId,
  }) async {
    final ref = await _db.collection('hotZones').add({
      'title': title,
      'location': location,
      'category': category,
      'description': description,
      'risk': risk.name,
      'verifications': 1,
      'x': x,
      'y': y,
      'lat': ?lat,
      'lng': ?lng,
      'timeAgo': 'just now',
      'userId': userId ?? 'anonymous',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Records a verification by [userId] for [reportId], enforcing **one per
  /// user** via a transaction. Returns `true` if this was a new verification,
  /// `false` if the user already verified it (or the report no longer exists).
  Future<bool> verifyReport(String reportId, String userId) async {
    final ref = _db.collection('hotZones').doc(reportId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data() ?? const {};
      final verifiedBy = List<String>.from(data['verifiedBy'] as List? ?? const []);
      if (verifiedBy.contains(userId)) return false;
      verifiedBy.add(userId);
      tx.update(ref, {
        'verifications': FieldValue.increment(1),
        'verifiedBy': verifiedBy,
      });
      return true;
    });
  }
}
