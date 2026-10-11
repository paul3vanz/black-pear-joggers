import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';

part 'preferences_repository.g.dart';

/// One entry of `GET /app/clubs/{clubId}/notification-preferences`.
class NotificationCategoryPref {
  const NotificationCategoryPref({
    required this.category,
    required this.label,
    required this.description,
    required this.pushEnabled,
    required this.locked,
  });

  final String category;
  final String label;
  final String description;
  final bool pushEnabled;

  /// Can't be turned off (always shown on).
  final bool locked;

  factory NotificationCategoryPref.fromJson(Map<String, Object?> json) =>
      NotificationCategoryPref(
        category: json['category']! as String,
        label: json['label'] as String? ?? json['category']! as String,
        description: json['description'] as String? ?? '',
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
      );

  NotificationCategoryPref copyWith({bool? pushEnabled}) =>
      NotificationCategoryPref(
        category: category,
        label: label,
        description: description,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        locked: locked,
      );
}

/// Notification preferences are online-only (no local cache): they're a settings
/// screen, so a friendly "needs a connection" message beats stale switches.
class PreferencesRepository {
  PreferencesRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationCategoryPref>> fetch(int clubId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('/app/clubs/$clubId/notification-preferences'),
    );
    return _parse(response);
  }

  Future<List<NotificationCategoryPref>> update(
    int clubId,
    Map<String, bool> changes,
  ) async {
    final response = await guardApi(
      () => _dio.put<Object?>(
        '/app/clubs/$clubId/notification-preferences',
        data: changes,
      ),
    );
    return _parse(response);
  }

  List<NotificationCategoryPref> _parse(Response<Object?> response) => [
    for (final c
        in (jsonObject(response)['categories'] as List<Object?>? ?? const []))
      NotificationCategoryPref.fromJson(Map<String, Object?>.from(c! as Map)),
  ];
}

@Riverpod(keepAlive: true)
PreferencesRepository preferencesRepository(Ref ref) =>
    PreferencesRepository(ref.watch(apiClientProvider));
