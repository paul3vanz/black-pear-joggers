import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/notifications/push_service.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/settings/data/notification_settings_repository.dart';
import 'package:bpj/features/settings/data/preferences_repository.dart';
import 'package:bpj/features/settings/ui/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'notification_settings_repository_test.dart' show settingsJson;

Map<String, Object?> _category(
  String key,
  String label, {
  bool pushEnabled = true,
  bool locked = false,
}) => {
  'category': key,
  'label': label,
  'description': 'About $label',
  'pushEnabled': pushEnabled,
  'locked': locked,
};

void main() {
  late FakeAdapter adapter;

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationSettingsRepositoryProvider.overrideWithValue(
            NotificationSettingsRepository(fakeDio(adapter)),
          ),
          preferencesRepositoryProvider.overrideWithValue(
            PreferencesRepository(fakeDio(adapter)),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          pushPermissionProvider.overrideWith(
            (ref) async => PushPermission.denied,
          ),
        ],
        child: const MaterialApp(home: NotificationSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('locked categories are on and disabled; others toggle', (
    tester,
  ) async {
    adapter = FakeAdapter({
      'GET /app/clubs/1/notification-preferences': FakeResponse(200, {
        'categories': [
          _category('club_updates', 'Club updates'),
          _category('my_group_changes', 'My group changes', locked: true),
        ],
      }),
      'PUT /app/clubs/1/notification-preferences': FakeResponse(200, {
        'categories': [
          _category('club_updates', 'Club updates', pushEnabled: false),
          _category('my_group_changes', 'My group changes', locked: true),
        ],
      }),
    });
    await pumpSettings(tester);

    final locked = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('pref-my_group_changes')),
    );
    expect(locked.value, isTrue);
    expect(locked.onChanged, isNull);
    expect(find.textContaining('Always on'), findsOneWidget);

    // OS permission state is shown, with the way out when denied.
    expect(find.text('Open settings'), findsOneWidget);

    final open = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('pref-club_updates')),
    );
    expect(open.value, isTrue);
    expect(open.onChanged, isNotNull);

    await tester.tap(find.byKey(const ValueKey('pref-club_updates')));
    await tester.pumpAndSettle();
    final put = adapter.requests.lastWhere((r) => r.method == 'PUT');
    expect(put.method, 'PUT');
    expect(put.data, {'club_updates': false});
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('pref-club_updates')),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('offline shows a friendly message with a retry button', (
    tester,
  ) async {
    adapter = FakeAdapter({});
    await pumpSettings(tester);
    expect(find.textContaining('need an internet connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  final prefsRoute = <String, Object>{
    'GET /app/clubs/1/notification-preferences': FakeResponse(200, {
      'categories': [_category('club_updates', 'Club updates')],
    }),
  };

  testWidgets('shows the push limit and a Run reminders row', (tester) async {
    adapter = FakeAdapter({
      ...prefsRoute,
      'GET /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(cap: 12, thursday: 'off'),
      ),
    });
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('runsIFollowRow')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Daily push limit'), findsOneWidget);
    expect(find.textContaining('At most 12'), findsOneWidget);
    expect(find.textContaining('still arrives in your inbox'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<int>>(find.byKey(const ValueKey('push-cap')))
          .selected,
      {12},
    );
    // The per-run Automatic / Always / Never list is gone (D117).
    expect(find.text('Run reminders'), findsOneWidget);
    expect(find.textContaining('Runs I follow'), findsOneWidget);
    expect(find.text('Always'), findsNothing);
    expect(find.text('Tuesday 7pm · Tuesday run'), findsNothing);
  });

  testWidgets('the Run reminders row opens Runs I follow', (tester) async {
    adapter = FakeAdapter({
      ...prefsRoute,
      'GET /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(),
      ),
    });
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/follows',
          builder: (_, _) => const Scaffold(body: Text('Follows page')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationSettingsRepositoryProvider.overrideWithValue(
            NotificationSettingsRepository(fakeDio(adapter)),
          ),
          preferencesRepositoryProvider.overrideWithValue(
            PreferencesRepository(fakeDio(adapter)),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          pushPermissionProvider.overrideWith(
            (ref) async => PushPermission.denied,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('runsIFollowRow')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('runsIFollowRow')));
    await tester.pumpAndSettle();
    expect(find.text('Follows page'), findsOneWidget);
  });

  testWidgets('changing the cap saves through the repository', (tester) async {
    adapter = FakeAdapter({
      ...prefsRoute,
      'GET /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(),
      ),
      'PUT /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(cap: 0),
      ),
    });
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.text('No limit'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('No limit'));
    await tester.pumpAndSettle();
    final put = adapter.requests.last;
    expect(put.method, 'PUT');
    expect(put.data, {'dailyPushCap': 0});
    expect(find.textContaining('No limit: every notification'), findsOneWidget);
  });

  testWidgets('a failed save reverts the choice and shows a snackbar', (
    tester,
  ) async {
    adapter = FakeAdapter({
      ...prefsRoute,
      'GET /app/clubs/1/notification-settings': FakeResponse(
        200,
        settingsJson(),
      ),
      // No PUT route: the fake adapter throws a connection error.
    });
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.text('12'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<int>>(find.byKey(const ValueKey('push-cap')))
          .selected,
      {6},
    );
  });
}
