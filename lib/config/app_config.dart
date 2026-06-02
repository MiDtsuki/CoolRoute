class AppConfig {
  const AppConfig._();

  // Live Google Maps are on by default; pass
  // --dart-define=ENABLE_LIVE_GOOGLE_MAPS=false to force the painted fallback.
  // The map still falls back automatically when no valid API key is present.
  static const enableLiveGoogleMaps =
      bool.fromEnvironment('ENABLE_LIVE_GOOGLE_MAPS', defaultValue: true);
}
