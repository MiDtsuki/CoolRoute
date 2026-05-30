// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<void> loadGoogleMapsWebApi(String? apiKey) async {
  if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('YOUR_')) {
    return;
  }

  const scriptId = 'google-maps-js-api';
  if (html.document.getElementById(scriptId) != null) {
    return;
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = scriptId
    ..async = true
    ..defer = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey';

  script.onLoad.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });
  script.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError('Google Maps JavaScript API failed to load.');
    }
  });

  html.document.head?.append(script);
  await completer.future.timeout(const Duration(seconds: 12));
}
