import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_settings_repository.dart';
import '../data/preferences_repository.dart';

/// Server notification preferences for a club. Auto-disposed so leaving the
/// screen and coming back refetches. Errors surface as `AsyncError`.
final preferencesProvider = FutureProvider.autoDispose
    .family<List<NotificationCategoryPref>, int>(
      (ref, clubId) => ref.watch(preferencesRepositoryProvider).fetch(clubId),
    );

/// Daily push limit and per-series reminder choices for a club (same lifecycle
/// as [preferencesProvider]).
final notificationSettingsProvider = FutureProvider.autoDispose
    .family<NotificationSettings, int>(
      (ref, clubId) =>
          ref.watch(notificationSettingsRepositoryProvider).fetch(clubId),
    );
