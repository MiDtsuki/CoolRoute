import 'package:cloud_firestore/cloud_firestore.dart';
import '../dummy_data/dummy_data.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../models/nearby_report.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _expiry = Duration(hours: 48);

  Future<List<HotZoneReport>> getHotZoneReports() async {
    try {
      final snapshot = await _db
          .collection('hotZones')
          .orderBy('createdAt', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return DummyData.hotZones;

      final now = DateTime.now();
      final reports = <HotZoneReport>[];
      for (final doc in snapshot.docs) {
        final report = HotZoneReport.fromMap(doc.data(), doc.id);
        if (report.createdAt != null &&
            now.difference(report.createdAt!) > _expiry) {
          // Fire-and-forget: first reader cleans up expired docs.
          doc.reference.delete();
          continue;
        }
        reports.add(report);
      }
      return reports;
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

  /// Returns reports created by [uid], ordered newest first.
  Future<List<HotZoneReport>> getUserHotZoneReports(String uid) async {
    try {
      final snapshot = await _db
          .collection('hotZones')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => HotZoneReport.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return const [];
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
      'verifiedBy': <String>[],
      'resolvedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Records a "Still hot" verification by [userId]. One per user.
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

  /// Records a "Problem fixed" vote. If 3 distinct users resolve a report,
  /// the document is deleted. Returns true if this was a new resolution vote.
  Future<bool> resolveReport(String reportId, String userId) async {
    final ref = _db.collection('hotZones').doc(reportId);
    bool shouldDelete = false;

    final counted = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data() ?? const {};
      final resolvedBy =
          List<String>.from(data['resolvedBy'] as List? ?? const []);
      if (resolvedBy.contains(userId)) return false;
      resolvedBy.add(userId);
      tx.update(ref, {'resolvedBy': resolvedBy});
      if (resolvedBy.length >= 3) shouldDelete = true;
      return true;
    });

    if (shouldDelete) {
      await ref.delete();
    }
    return counted;
  }

  /// Deletes a report the current user owns.
  Future<void> deleteReport(String id) =>
      _db.collection('hotZones').doc(id).delete();

  /// Updates editable fields on a report the current user owns.
  Future<void> updateReport(
    String id, {
    required String title,
    required String description,
    required String category,
  }) =>
      _db.collection('hotZones').doc(id).update({
        'title': title,
        'description': description,
        'category': category,
      });
}
