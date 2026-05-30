import 'package:flutter/material.dart';

import 'screens/welcome/welcome_screen.dart';
import 'theme/app_theme.dart';

class CoolRouteApp extends StatelessWidget {
  const CoolRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoolRoute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WelcomeScreen(),
    );
  }
}
