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

  Future<void> submitHotZoneReport({
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
    await _db.collection('hotZones').add({
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
  }

  Future<void> verifyReport(String reportId) async {
    await _db.collection('hotZones').doc(reportId).update({
      'verifications': FieldValue.increment(1),
    });
  }
}
