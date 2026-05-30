import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'utils/google_maps_web_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (AppConfig.enableLiveGoogleMaps) {
    await loadGoogleMapsWebApi(dotenv.maybeGet('GOOGLE_MAPS_API_KEY'));
  }
  runApp(const CoolRouteApp());
}
