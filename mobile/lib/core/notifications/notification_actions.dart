import 'dart:convert';

import 'package:dio/dio.dart';

/// Android shows buttons only on notifications the app builds itself, so the API
/// sends run reminders as data-only pushes and the app turns them into local
/// notifications (D32). This file is the Flutter-free part of that: deciding
/// which messages count, parsing them, and answering from a button tap. The
/// plugin glue lives in `local_notifications.dart`.
///
/// Nothing here may touch Riverpod: it also runs in the background isolate.

/// The two answers a reminder can carry, same strings as the API's `actions`.
const actionGoing = 'going';
const actionNotGoing = 'not_going';

const _knownActions = [actionGoing, actionNotGoing];

/// A data-only push that should become a local notification with buttons.
class ActionNotification {
  const ActionNotification({
    required this.title,
    required this.body,
    required this.notificationId,
    required this.actionToken,
    required this.actions,
    required this.localId,
    required this.category,
    required this.data,
  });

  final String title;
  final String body;

  /// Server notification id, sent back with the answer.
  final String notificationId;

  /// One-time-per-notification secret from the push (never in the inbox API).
  final String actionToken;

  /// Subset of [_knownActions], in the order the server listed them.
  final List<String> actions;

  /// Stable Android notification id, so the same news replaces itself.
  final int localId;

  /// Android channel key (a category from `notification_categories.dart`).
  final String category;

  /// The full `data` map; becomes the local notification's JSON payload.
  final Map<String, Object?> data;
}

/// Decides whether a push [data] map is an action notification. Pure.
///
/// Only data-only messages qualify: if the push carries a `notification` block
/// ([hasNotificationBlock]) the OS already shows it (and FCM_ACTION_BUTTONS is
/// off server-side), so showing a second one would double it up.
ActionNotification? parseActionNotification(
  Map<String, Object?> data, {
  required bool hasNotificationBlock,
}) {
  if (hasNotificationBlock) return null;
  final title = _str(data['title']);
  final body = _str(data['body']);
  final notificationId = _str(data['notificationId']);
  final token = _str(data['actionToken']);
  final actions = [
    for (final a in _str(data['actions'])?.split(',') ?? const <String>[])
      if (_knownActions.contains(a.trim())) a.trim(),
  ];
  if (title == null ||
      body == null ||
      notificationId == null ||
      token == null ||
      actions.isEmpty) {
    return null;
  }
  return ActionNotification(
    title: title,
    body: body,
    notificationId: notificationId,
    actionToken: token,
    actions: actions,
    localId: localNotificationId(_str(data['tag']) ?? notificationId),
    category: _str(data['category']) ?? 'run_reminders',
    data: data,
  );
}

String? _str(Object? v) {
  final s = v?.toString();
  return s == null || s.isEmpty ? null : s;
}

/// Stable positive 31-bit id for a notification [key] (the dedupe `tag`, or the
/// notification id as fallback). Dart's `String.hashCode` isn't promised to match
/// between isolates or runs, so this is FNV-1a, which always gives the same
/// number: a re-sent reminder then replaces the one already showing.
int localNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// How the server took the answer.
enum ActionOutcome {
  /// 2xx.
  sent,

  /// 404 or 409: the notification or run is gone, cancelled or finished.
  changed,

  /// No connection, timeout or a server error: nothing was recorded.
  failed,
}

/// What the replacement notification says after an answer.
String confirmationText(String action, ActionOutcome outcome) =>
    switch (outcome) {
      ActionOutcome.sent when action == actionGoing =>
        "Thanks, you're down as coming",
      ActionOutcome.sent => "Thanks, we've noted you can't make it",
      ActionOutcome.changed => 'That run has changed - open the app',
      ActionOutcome.failed => "Couldn't send - open the app to answer",
    };

/// Posts an answer to `POST /app/notification-actions`. No sign-in (the token
/// is the credential), so it uses a bare Dio with no auth interceptor. Pass
/// [dio] in tests; otherwise one is built for [baseUrl] with a 15 s timeout.
Future<ActionOutcome> postNotificationAction({
  required String baseUrl,
  required String notificationId,
  required String token,
  required String action,
  Dio? dio,
}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );
  try {
    await client.post<Object?>(
      '/app/notification-actions',
      data: {
        'notificationId': notificationId,
        'token': token,
        'action': action,
      },
    );
    return ActionOutcome.sent;
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    return status == 404 || status == 409
        ? ActionOutcome.changed
        : ActionOutcome.failed;
  } on Object {
    return ActionOutcome.failed;
  } finally {
    if (dio == null) client.close();
  }
}

/// Reads the JSON payload we put on a local notification ({} if it isn't ours).
Map<String, Object?> decodePayload(String? payload) {
  if (payload == null || payload.isEmpty) return const {};
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) return Map<String, Object?>.from(decoded);
  } on FormatException {
    // Not ours.
  }
  return const {};
}
