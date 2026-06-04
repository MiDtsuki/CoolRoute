import 'package:flutter/foundation.dart';

/// Lightweight cross-screen signal. Bumped whenever a hot-zone report is
/// created so live screens (Map, Home) can reload from Firestore and show it
/// without a full app restart.
final ValueNotifier<int> hotZoneRevision = ValueNotifier<int>(0);

void notifyHotZonesChanged() => hotZoneRevision.value++;
