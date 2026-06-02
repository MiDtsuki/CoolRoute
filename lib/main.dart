import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'utils/google_maps_web_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing or empty — continue with defaults
  }

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('VERIFY: Firebase initialized');
  } catch (e, st) {
    debugPrint('VERIFY: Firebase error: $e');
    debugPrint('$st');
    // Firebase not configured yet — app runs with dummy data
  }

  if (AppConfig.enableLiveGoogleMaps) {
    await loadGoogleMapsWebApi(dotenv.maybeGet('GOOGLE_MAPS_API_KEY'));
  }
  runApp(CoolRouteApp(firebaseReady: firebaseReady));
}
