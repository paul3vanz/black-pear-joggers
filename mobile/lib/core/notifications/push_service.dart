import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/router.dart';
import '../../features/inbox/data/inbox_repository.dart';
import '../../features/membership/ui/membership_providers.dart';
import '../../features/messages/data/messages_repository.dart';
import '../../features/messages/ui/messages_providers.dart';
import '../../features/runs/data/runs_repository.dart';
import '../../features/groups/ui/group_access.dart';
import '../../features/updates/data/post_receipts_repository.dart';
import '../../features/updates/data/posts_repository.dart';
import '../api/api_client.dart';
import '../api/json.dart';
import '../auth/account_store.dart';
import '../auth/accounts_controller.dart';
import '../auth/auth_service.dart';
import '../auth/session_expiry.dart';
import '../config/env.dart';
import 'local_notifications.dart';
import 'notification_actions.dart';
import 'notification_categories.dart';
import 'notification_routing.dart';
import 'push_background.dart';

part 'push_service.g.dart';

/// State of the OS notification permission, as the settings screen shows it.
enum PushPermission {
  /// Firebase isn't configured in this build, so push is off.
  unavailable,
  granted,
  denied,
  notDetermined,
}

const _promptedFlag = 'pushPrompted';

/// Everything push: Firebase init, Android channels, permission, device-token
/// registration for every signed-in account, foreground display and tap routing.
///
/// If Firebase isn't configured (empty `FIREBASE_*` in config) every method is a
/// silent no-op, so the feed, inbox and settings still work.
class PushService {
  PushService(this._ref);

  final Ref _ref;

  FirebaseMessaging? _fcm;
  final _local = FlutterLocalNotificationsPlugin();
  String? _token;
  bool _started = false;
  final _registered = <String>{};
  final _subscriptions = <StreamSubscription<Object?>>[];

  bool get isEnabled => _started;

  /// Initialises Firebase and starts listening. Safe to call more than once.
  Future<void> start() async {
    if (_started || !Env.isFirebaseConfigured) return;
    try {
      await Firebase.initializeApp(options: firebaseOptionsFromEnv());
      final fcm = FirebaseMessaging.instance;
      _fcm = fcm;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotifications();
      _started = true;

      _subscriptions
        ..add(FirebaseMessaging.onMessage.listen(_onForegroundMessage))
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen(
            (m) => unawaited(handleTap(_dataOf(m))),
          ),
        )
        ..add(
          fcm.onTokenRefresh.listen((token) {
            _token = token;
            _registered.clear();
            unawaited(registerAllAccounts());
          }),
        );

      final initial = await fcm.getInitialMessage();
      if (initial != null) unawaited(handleTap(_dataOf(initial)));

      _token = await fcm.getToken();
      await registerAllAccounts();
    } on Object catch (e) {
      // Push is a nicety: a Firebase/Play-services failure must not break the app.
      debugPrint('Push setup failed: $e');
    }
  }

  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
  }

  Map<String, Object?> _dataOf(RemoteMessage m) =>
      Map<String, Object?>.from(m.data);

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      settings: localNotificationSettings(),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      // Action buttons run in a separate isolate when the app isn't foregrounded.
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackgroundHandler,
    );
    // One channel per category, so users can mute each in system settings.
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final c in notificationCategories) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          c.key,
          c.name,
          description: c.description,
          importance: Importance.high,
        ),
      );
    }
  }

  /// A tap on a local notification: its body (open the screen) or, when
  /// `actionId` is set, one of its answer buttons (POST the answer).
  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      final outcome = await answerFromNotification(_local, response);
      // The foreground app picks the new answer up now rather than on next sync.
      if (outcome == ActionOutcome.sent) {
        await _refreshSessionsFor(decodePayload(response.payload));
      }
      return;
    }
    final data = decodePayload(response.payload);
    if (data.isNotEmpty) await handleTap(data);
  }

  // ---- Foreground messages ------------------------------------------------

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = _dataOf(message);
    // A message for the chat that is on screen: no notification, refresh it now.
    if (isForOpenChat(
      data,
      _ref.read(openChatGroupIdProvider),
      activeSub: _ref.read(activeSubProvider),
    )) {
      await _refreshOpenChat(data);
      return;
    }
    final notification = message.notification;
    final action = parseActionNotification(
      data,
      hasNotificationBlock: notification != null,
    );
    if (action != null) {
      // Data-only reminder with buttons: the OS won't show it, so we do.
      await showActionNotification(_local, action);
    } else if (notification != null) {
      final category = notificationCategoryFor(data['category'] as String?);
      await _local.show(
        id:
            (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
                .hashCode &
            0x7fffffff,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: androidDetails(category),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(data),
      );
    }
    await _refreshFor(data);
  }

  /// Pulls the new inbox row and post for the club in [data], if it's for the
  /// account that is currently active (other accounts' databases aren't open).
  Future<void> _refreshFor(Map<String, Object?> data) async {
    final userId = data['userId'] as String?;
    final clubId = int.tryParse('${data['clubId'] ?? ''}');
    if (clubId == null) return;
    if (userId != null && userId != _ref.read(activeSubProvider)) return;
    try {
      await _ref.read(inboxRepositoryProvider).refresh(clubId);
      await _ref.read(postsRepositoryProvider).refresh(clubId);
      unawaited(
        _ref
            .read(postReceiptsRepositoryProvider)
            .syncQuietly(clubId, myMemberId: _ref.read(myMemberIdProvider)),
      );
      // New chat message: update the unread dots and the Inbox chats list.
      if (isGroupMessagePush(data)) {
        await _ref
            .read(messagesRepositoryProvider)
            .refreshThreadsQuietly(clubId);
      }
    } on Object catch (e) {
      debugPrint('Push-triggered refresh failed: $e');
    }
  }

  /// Pulls the new messages straight into the chat that is open (the push is
  /// for it), if it is for the active account.
  Future<void> _refreshOpenChat(Map<String, Object?> data) async {
    final clubId = int.tryParse('${data['clubId'] ?? ''}');
    final groupId = data['groupId'] as String?;
    final userId = data['userId'] as String?;
    if (clubId == null || groupId == null) return;
    if (userId != null && userId != _ref.read(activeSubProvider)) return;
    try {
      await _ref.read(messagesRepositoryProvider).refresh(clubId, groupId);
    } on Object catch (e) {
      debugPrint('Push-triggered chat refresh failed: $e');
    }
  }

  /// Best-effort sessions refresh after answering from a button.
  Future<void> _refreshSessionsFor(Map<String, Object?> data) async {
    final clubId = int.tryParse('${data['clubId'] ?? ''}');
    if (clubId == null) return;
    final userId = data['userId'] as String?;
    if (userId != null && userId != _ref.read(activeSubProvider)) return;
    try {
      await _ref.read(runsRepositoryProvider).refreshSessions(clubId);
    } on Object catch (e) {
      debugPrint('Post-answer refresh failed: $e');
    }
  }

  // ---- Taps ---------------------------------------------------------------

  /// Opens the screen a notification points at, first switching account and/or
  /// club if the notification was for another one. Waits for the (possibly cold)
  /// app to be signed in and linked so the router doesn't redirect it away.
  Future<void> handleTap(Map<String, Object?> data) async {
    final state = await _ref.read(accountsControllerProvider.future);
    await _waitUntilLinked();
    final decision = decideTapRoute(
      data: data,
      activeSub: state.activeSub,
      activeClubId: _ref.read(activeClubIdProvider),
      knownSubs: {for (final a in state.accounts) a.sub},
    );
    final controller = _ref.read(accountsControllerProvider.notifier);
    var changed = false;
    if (decision.switchToSub != null) {
      await controller.switchTo(decision.switchToSub!);
      changed = true;
    }
    if (decision.setClubId != null) {
      await controller.setActiveClub(decision.setClubId!);
      changed = true;
    }
    if (changed) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _waitUntilLinked();
    }
    _ref.read(routerProvider).go(decision.route);
  }

  Future<void> _waitUntilLinked() async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (_ref.read(linkStatusProvider) != LinkStatus.linked &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  // ---- Device tokens ------------------------------------------------------

  /// Registers this device's FCM token for EVERY signed-in account (each request
  /// signed with that account's own token), so a push for any of them arrives.
  Future<void> registerAllAccounts() async {
    final token = _token;
    if (!_started || token == null) return;
    final accounts =
        _ref.read(accountsControllerProvider).value?.accounts ?? const [];
    final auth = _ref.read(authServiceProvider);
    final handleExpiry = _ref.read(sessionExpiryHandlerProvider);
    final version = await _appVersion();
    for (final account in accounts) {
      final key = '${account.sub}|$token';
      if (_registered.contains(key)) continue;
      final dio = buildApiClient(auth: auth, sub: account.sub);
      try {
        await guardApi(
          () => dio.post<Object?>(
            '/app/devices',
            data: {
              'token': token,
              'platform': defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
              'appVersion': version,
            },
          ),
        );
        _registered.add(key);
      } on Object catch (e) {
        // Best effort. A dead session is dropped like anywhere else.
        await handleExpiry(account.sub, e);
      } finally {
        dio.close();
      }
    }
  }

  /// Call when the accounts on the device change (sign-in registers the new one).
  Future<void> onAccountsChanged() => registerAllAccounts();

  /// Removes this device's token from [sub]'s login. Best effort and time-boxed:
  /// call BEFORE deleting that account's credentials. Never throws.
  Future<void> unregisterDevice(String sub) async {
    if (!_started) return;
    final dio = buildApiClient(auth: _ref.read(authServiceProvider), sub: sub);
    try {
      final token = _token ?? await _fcm?.getToken();
      if (token == null) return;
      await guardApi(
        () => dio.delete<Object?>('/app/devices/${Uri.encodeComponent(token)}'),
      ).timeout(const Duration(seconds: 5));
      _registered.remove('$sub|$token');
    } on Object catch (e) {
      debugPrint('Device unregister failed: $e');
    } finally {
      dio.close();
    }
  }

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } on Object {
      return 'unknown';
    }
  }

  // ---- Permission ---------------------------------------------------------

  Future<PushPermission> permissionState() async {
    final fcm = _fcm;
    if (!_started || fcm == null) return PushPermission.unavailable;
    final settings = await fcm.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermission.granted,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
    };
  }

  /// Shows the OS permission prompt (Android 13+/iOS).
  Future<PushPermission> requestPermission() async {
    await _fcm?.requestPermission();
    return permissionState();
  }

  Future<void> openSystemSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  /// Asks for notification permission ONCE per install, after membership is
  /// linked: a short explainer dialog first, then the OS prompt. Remembered in
  /// secure storage whether the user accepted or not ("Not now" can be undone from
  /// Profile > Notification settings).
  Future<void> requestPermissionWithExplainer(BuildContext context) async {
    if (!_started) return;
    final store = _ref.read(accountStoreProvider);
    if (await store.readFlag(_promptedFlag)) return;
    if (await permissionState() != PushPermission.notDetermined) {
      await store.writeFlag(_promptedFlag, value: true);
      return;
    }
    if (!context.mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stay in the loop'),
        content: const Text(
          'Allow notifications so the club can tell you about important '
          'updates, run changes and when a group needs you. You can choose '
          'exactly what you get in Notification settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow notifications'),
          ),
        ],
      ),
    );
    await store.writeFlag(_promptedFlag, value: true);
    if (accept ?? false) await requestPermission();
  }
}

/// Created once and kept alive. It re-registers tokens whenever the account list
/// changes, and starts Firebase right after creation.
@Riverpod(keepAlive: true)
PushService pushService(Ref ref) {
  final service = PushService(ref);
  ref.listen(
    accountsControllerProvider,
    (_, _) => unawaited(service.onAccountsChanged()),
  );
  ref.onDispose(service.dispose);
  unawaited(Future.microtask(service.start));
  return service;
}

/// Permission state for the settings screen. Override in tests.
final pushPermissionProvider = FutureProvider.autoDispose<PushPermission>(
  (ref) => ref.watch(pushServiceProvider).permissionState(),
);
