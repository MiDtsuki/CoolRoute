import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email / password — these rethrow FirebaseAuthException so the UI can show
  // a meaningful message.
  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<User?> registerWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  // Google — uses the native firebase_auth flow (no extra package). On web this
  // opens a popup; on mobile it runs the generic provider flow.
  Future<User?> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    return credential.user;
  }

  // Guest sign-in. Swallows errors and returns null on failure.
  Future<User?> signInAnonymously() async {
    try {
      if (_auth.currentUser != null) return _auth.currentUser;
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      debugPrint('VERIFY: auth error: $e');
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
