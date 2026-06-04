import 'package:flutter/foundation.dart';

/// Lightweight cross-screen signal. Bumped whenever a hot-zone report is
/// created so live screens (Map, Home) can reload from Firestore and show it
/// without a full app restart.
final ValueNotifier<int> hotZoneRevision = ValueNotifier<int>(0);

void notifyHotZonesChanged() => hotZoneRevision.value++;

/// Same idea for community-suggested cool spots.
final ValueNotifier<int> coolSpotRevision = ValueNotifier<int>(0);

void notifyCoolSpotsChanged() => coolSpotRevision.value++;

/// Same idea for community tree-planting events.
final ValueNotifier<int> treeEventRevision = ValueNotifier<int>(0);

void notifyTreeEventsChanged() => treeEventRevision.value++;

/// Bumped when the signed-in user's profile changes (saved routes, stat
/// counters) so the Profile tab can reload without a manual refresh.
final ValueNotifier<int> profileRevision = ValueNotifier<int>(0);

void notifyProfileChanged() => profileRevision.value++;
