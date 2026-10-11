import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/env.dart';
import 'notification_actions.dart';
import 'notification_categories.dart';

/// iOS category named by the push's `apns.payload.aps.category`. Declared once at
/// plugin initialisation. (Untested until there is an iOS build: keep it small.)
const iosRunReminderCategory = 'BPJ_RUN_REMINDER';

final iosNotificationCategories = <DarwinNotificationCategory>[
  DarwinNotificationCategory(
    iosRunReminderCategory,
    actions: [
      DarwinNotificationAction.plain(actionGoing, "I'm coming"),
      DarwinNotificationAction.plain(actionNotGoing, 'Not coming'),
    ],
  ),
];

/// Shared init settings for the main isolate and the background isolate.
InitializationSettings localNotificationSettings() => InitializationSettings(
  android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
  iOS: DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: iosNotificationCategories,
  ),
);

/// Creates the Android channel for [category] (a no-op if it already exists).
Future<void> ensureChannel(
  FlutterLocalNotificationsPlugin plugin,
  NotificationCategory category,
) async {
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        AndroidNotificationChannel(
          category.key,
          category.name,
          description: category.description,
          importance: Importance.high,
        ),
      );
}

/// Shows [n] with "I'm coming" / "Not coming" buttons. Used by the foreground
/// handler and the background isolate. Same [ActionNotification.localId] = the
/// same slot, so a re-sent reminder replaces the one already showing.
Future<void> showActionNotification(
  FlutterLocalNotificationsPlugin plugin,
  ActionNotification n,
) async {
  final category = notificationCategoryFor(n.category);
  await ensureChannel(plugin, category);
  await plugin.show(
    id: n.localId,
    title: n.title,
    body: n.body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        category.key,
        category.name,
        channelDescription: category.description,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          for (final a in n.actions)
            AndroidNotificationAction(
              a,
              a == actionGoing ? "I'm coming" : 'Not coming',
              // Run in the background isolate without opening the app.
              showsUserInterface: false,
              // We replace the notification ourselves with the confirmation.
              cancelNotification: false,
            ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: iosRunReminderCategory,
      ),
    ),
    payload: jsonEncode(n.data),
  );
}

/// Handles a tap on an action button: POSTs the answer, then replaces the
/// notification with a short confirmation. Returns the outcome (null if the
/// response wasn't an action we can answer). Free of Riverpod: it runs in the
/// background isolate too.
Future<ActionOutcome?> answerFromNotification(
  FlutterLocalNotificationsPlugin plugin,
  NotificationResponse response,
) async {
  final action = response.actionId;
  if (action == null || action.isEmpty) return null;
  final data = decodePayload(response.payload);
  final notificationId = data['notificationId']?.toString();
  final token = data['actionToken']?.toString();
  final id = response.id;
  if (notificationId == null || token == null || id == null) return null;

  final outcome = await postNotificationAction(
    baseUrl: Env.apiBaseUrl,
    notificationId: notificationId,
    token: token,
    action: action,
  );
  final category = notificationCategoryFor(data['category']?.toString());
  await ensureChannel(plugin, category);
  await plugin.show(
    id: id,
    title: data['title']?.toString() ?? 'Black Pear Joggers',
    body: confirmationText(action, outcome),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        category.key,
        category.name,
        channelDescription: category.description,
        importance: Importance.high,
        priority: Priority.high,
        onlyAlertOnce: true,
        timeoutAfter: 15000, // ms; the confirmation tidies itself away
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    // Same payload (without the token being needed again): tapping opens the run.
    payload: jsonEncode(data),
  );
  return outcome;
}
