import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';

/// Per-series run reminder choice. `auto` reminds you about runs you usually come
/// to (D35); `on` always; `off` never. Wire values: `auto`, `on`, `off`.
enum ReminderMode {
  auto,
  on,
  off;

  /// Unknown server values fall back to `auto`.
  static ReminderMode parse(String? value) => ReminderMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => ReminderMode.auto,
  );
}

/// One row of `series` in `GET /app/clubs/{clubId}/notification-settings`.
class SeriesReminder {
  const SeriesReminder({
    required this.seriesId,
    required this.title,
    required this.weekday,
    required this.localStartTime,
    required this.reminders,
  });

  final String seriesId;
  final String title;

  /// ISO weekday, 1 = Monday ... 7 = Sunday.
  final int weekday;

  /// Club-local `HH:MM`.
  final String localStartTime;
  final ReminderMode reminders;

  factory SeriesReminder.fromJson(Map<String, Object?> json) => SeriesReminder(
    seriesId: json['seriesId']! as String,
    title: json['title'] as String? ?? 'Run',
    weekday: (json['weekday'] as num?)?.toInt() ?? 1,
    localStartTime: json['localStartTime'] as String? ?? '',
    reminders: ReminderMode.parse(json['reminders'] as String?),
  );

  SeriesReminder copyWith({ReminderMode? reminders}) => SeriesReminder(
    seriesId: seriesId,
    title: title,
    weekday: weekday,
    localStartTime: localStartTime,
    reminders: reminders ?? this.reminders,
  );
}

/// `GET/PUT /app/clubs/{clubId}/notification-settings`.
class NotificationSettings {
  const NotificationSettings({
    required this.dailyPushCap,
    required this.defaultDailyPushCap,
    required this.series,
  });

  /// Effective pushes per rolling 24 h; 0 = no limit.
  final int dailyPushCap;
  final int defaultDailyPushCap;
  final List<SeriesReminder> series;

  factory NotificationSettings.fromJson(Map<String, Object?> json) {
    final defaultCap = (json['defaultDailyPushCap'] as num?)?.toInt() ?? 6;
    return NotificationSettings(
      dailyPushCap: (json['dailyPushCap'] as num?)?.toInt() ?? defaultCap,
      defaultDailyPushCap: defaultCap,
      series: [
        for (final s in (json['series'] as List<Object?>? ?? const []))
          SeriesReminder.fromJson(Map<String, Object?>.from(s! as Map)),
      ],
    );
  }

  NotificationSettings copyWith({
    int? dailyPushCap,
    Map<String, ReminderMode>? series,
  }) => NotificationSettings(
    dailyPushCap: dailyPushCap ?? this.dailyPushCap,
    defaultDailyPushCap: defaultDailyPushCap,
    series: [
      for (final s in this.series)
        if (series != null && series.containsKey(s.seriesId))
          s.copyWith(reminders: series[s.seriesId])
        else
          s,
    ],
  );
}

/// Like the category switches (`PreferencesRepository`): online-only, no local
/// cache, so a settings screen shows the server's truth or a "needs a connection"
/// message rather than stale choices.
class NotificationSettingsRepository {
  NotificationSettingsRepository(this._dio);

  final Dio _dio;

  Future<NotificationSettings> fetch(int clubId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('/app/clubs/$clubId/notification-settings'),
    );
    return NotificationSettings.fromJson(jsonObject(response));
  }

  /// Sends only what changed; the server answers with the full settings.
  Future<NotificationSettings> update(
    int clubId, {
    int? dailyPushCap,
    Map<String, ReminderMode>? series,
  }) async {
    final response = await guardApi(
      () => _dio.put<Object?>(
        '/app/clubs/$clubId/notification-settings',
        data: {
          'dailyPushCap': ?dailyPushCap, // `?x` = include only when non-null
          if (series != null)
            'series': {for (final e in series.entries) e.key: e.value.name},
        },
      ),
    );
    return NotificationSettings.fromJson(jsonObject(response));
  }
}

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>(
      (ref) => NotificationSettingsRepository(ref.watch(apiClientProvider)),
    );
