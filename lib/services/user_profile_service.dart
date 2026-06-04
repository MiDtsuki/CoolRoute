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
          name: _defaultName(user),
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

  // Picks a friendly default display name from the auth account: the Google/
  // email display name first, then the email's local part, then a guest label.
  static String _defaultName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return user.isAnonymous ? 'Guest Explorer' : 'CoolRoute User';
  }

  // Persists user-editable profile fields. Uses merge so it works whether or not
  // the document already exists, and never clobbers counters / savedRoutes.
  Future<void> updateProfile(
    String userId, {
    String? name,
    String? role,
    String? location,
    String? riskProfile,
  }) async {
    final data = <String, dynamic>{
      'name': ?name,
      'role': ?role,
      'location': ?location,
      'riskProfile': ?riskProfile,
    };
    if (data.isEmpty) return;
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  // Counter bumps use set+merge (not update) so they succeed even if the user's
  // profile document hasn't been created yet — FieldValue.increment seeds the
  // field from 0 in that case.
  Future<void> incrementReportCount(String userId) async {
    await _db.collection('users').doc(userId).set(
      {'reportCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Future<void> incrementVerifiedReportCount(String userId) async {
    await _db.collection('users').doc(userId).set(
      {'verifiedReportCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Future<void> addSavedRoute(String userId, SavedRoute route) async {
    await _db.collection('users').doc(userId).set(
      {'savedRoutes': FieldValue.arrayUnion([route.toMap()])},
      SetOptions(merge: true),
    );
  }

  Future<void> removeSavedRoute(String userId, SavedRoute route) async {
    await _db.collection('users').doc(userId).set(
      {'savedRoutes': FieldValue.arrayRemove([route.toMap()])},
      SetOptions(merge: true),
    );
  }
}
