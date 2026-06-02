import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserProfile> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return DummyData.userProfile;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final newProfile = UserProfile(
          id: user.uid,
          name: 'Anonymous User',
          role: 'Student',
          location: 'Bangkok, Thailand',
          riskProfile: 'Normal',
          savedRoutes: const [],
          reportCount: 0,
          verifiedReportCount: 0,
        );
        await _db
            .collection('users')
            .doc(user.uid)
            .set({...newProfile.toMap(), 'createdAt': FieldValue.serverTimestamp()});
        return newProfile;
      }

      return UserProfile.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return DummyData.userProfile;
    }
  }

  Future<void> incrementReportCount(String userId) async {
    await _db.collection('users').doc(userId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  Future<void> addSavedRoute(String userId, String routeName) async {
    await _db.collection('users').doc(userId).update({
      'savedRoutes': FieldValue.arrayUnion([routeName]),
    });
  }

  Future<void> removeSavedRoute(String userId, String routeName) async {
    await _db.collection('users').doc(userId).update({
      'savedRoutes': FieldValue.arrayRemove([routeName]),
    });
  }
}
