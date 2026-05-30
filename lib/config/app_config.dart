class AppConfig {
  const AppConfig._();

  static const enableLiveGoogleMaps = bool.fromEnvironment('ENABLE_LIVE_GOOGLE_MAPS');
}
