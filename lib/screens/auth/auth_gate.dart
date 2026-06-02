import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firestore_seed_service.dart';
import '../shell/app_shell.dart';
import '../welcome/welcome_screen.dart';

/// Decides the first screen based on auth state:
/// signed in -> [AppShell] (and seeds Firestore once), otherwise the
/// [WelcomeScreen] -> login flow. Falls back to the prototype when Firebase
/// failed to initialise.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Stream<User?>? _authStream;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // Only touch FirebaseAuth.instance when Firebase actually initialised,
    // otherwise it throws (e.g. in tests / unconfigured runs).
    if (widget.firebaseReady) {
      _authStream = FirebaseAuthService().authStateChanges;
    }
  }

  void _seedOnce() {
    if (_seeded) return;
    _seeded = true;
    // Fire-and-forget: writes only run once, when collections are empty, and
    // require the now-authenticated user (per Firestore rules).
    FirestoreSeedService().seedIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    if (_authStream == null) {
      // Firebase unavailable — run the prototype with dummy data.
      return const WelcomeScreen();
    }
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          _seedOnce();
          return const AppShell();
        }
        return const WelcomeScreen();
      },
    );
  }
}
