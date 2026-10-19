import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';

/// `GET/PUT /app/clubs/{clubId}/notification-settings`: the daily push limit.
/// (The response's per-series `series` list is for older app versions; run
/// reminders now follow Runs I follow, D117.)
class NotificationSettings {
  const NotificationSettings({
    required this.dailyPushCap,
    required this.defaultDailyPushCap,
  });

  /// Effective pushes per rolling 24 h; 0 = no limit.
  final int dailyPushCap;
  final int defaultDailyPushCap;

  factory NotificationSettings.fromJson(Map<String, Object?> json) {
    final defaultCap = (json['defaultDailyPushCap'] as num?)?.toInt() ?? 6;
    return NotificationSettings(
      dailyPushCap: (json['dailyPushCap'] as num?)?.toInt() ?? defaultCap,
      defaultDailyPushCap: defaultCap,
    );
  }

  NotificationSettings copyWith({int? dailyPushCap}) => NotificationSettings(
    dailyPushCap: dailyPushCap ?? this.dailyPushCap,
    defaultDailyPushCap: defaultDailyPushCap,
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

  /// Saves the daily push limit; the server answers with the full settings.
  Future<NotificationSettings> update(
    int clubId, {
    required int dailyPushCap,
  }) async {
    final response = await guardApi(
      () => _dio.put<Object?>(
        '/app/clubs/$clubId/notification-settings',
        data: {'dailyPushCap': dailyPushCap},
      ),
    );
    return NotificationSettings.fromJson(jsonObject(response));
  }
}

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>(
      (ref) => NotificationSettingsRepository(ref.watch(apiClientProvider)),
    );
