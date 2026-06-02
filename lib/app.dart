import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

class CoolRouteApp extends StatelessWidget {
  const CoolRouteApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoolRoute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AuthGate(firebaseReady: firebaseReady),
    );
  }
}
