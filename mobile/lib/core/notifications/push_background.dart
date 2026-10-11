import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/env.dart';
import 'local_notifications.dart';
import 'notification_actions.dart';

/// Firebase options built from `config/*.json` (no `google-services.json`, no
/// flutterfire CLI). Only call when [Env.isFirebaseConfigured].
FirebaseOptions firebaseOptionsFromEnv() => FirebaseOptions(
  apiKey: Env.firebaseApiKey,
  appId: defaultTargetPlatform == TargetPlatform.iOS
      ? Env.firebaseIosAppId
      : Env.firebaseAndroidAppId,
  messagingSenderId: Env.firebaseMessagingSenderId,
  projectId: Env.firebaseProjectId,
);

/// Runs in a background isolate when a message arrives while the app isn't in the
/// foreground. It must be top-level and annotated, and it has no Riverpod, no
/// router, no UI. Messages with a `notification` block are shown by the OS itself
/// (on the channel named by `android.notification.channel_id`). Data-only run
/// reminders (with `actions`) are turned into a local notification with answer
/// buttons here. The inbox and posts are fetched the next time the app opens.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background push ${message.messageId}');
  final n = parseActionNotification(
    Map<String, Object?>.from(message.data),
    hasNotificationBlock: message.notification != null,
  );
  if (n == null) return;
  try {
    // A fresh isolate has no plugin state, so set the plugin up from scratch.
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(settings: localNotificationSettings());
    await showActionNotification(plugin, n);
  } on Object catch (e) {
    debugPrint('Background action notification failed: $e');
  }
}

/// Runs in the background isolate when the user taps a notification action button
/// (`showsUserInterface: false`). Registered as
/// `onDidReceiveBackgroundNotificationResponse`; must be top-level.
@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(settings: localNotificationSettings());
    await answerFromNotification(plugin, response);
  } on Object catch (e) {
    debugPrint('Background notification action failed: $e');
  }
}
