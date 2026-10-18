import 'package:bpj/app/theme.dart';
import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/groups/ui/groups_providers.dart';
import 'package:bpj/features/members/data/member_profile_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/profile/data/profile_repository.dart';
import 'package:bpj/features/profile/ui/profile_providers.dart';
import 'package:bpj/features/profile/ui/profile_screen.dart';
import 'package:bpj/features/profile/ui/run_preferences_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  final opened = <Uri>[];

  setUp(() {
    opened.clear();
    db = memoryDb();
    adapter = FakeAdapter({
      'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
      'GET /app/clubs/1/profile': FakeResponse(200, profileJson()),
      'GET /app/clubs/1/preferences': const FakeResponse(200, {
        'paceUnit': 'mi',
        'distanceUnit': 'km',
        'paceFromS': 540,
        'paceToS': 600,
        'updatedAt': '2026-10-01T10:00:00.000Z',
      }),
    });
  });
  tearDown(() => db.close());

  /// Fills the cache (as a previous online session would), then goes "offline" if
  /// [online] is false by removing the profile route.
  Future<void> pumpProfile(WidgetTester tester, {required bool online}) async {
    // Tall enough that the whole list is built (it is a lazy ListView).
    tester.view
      ..physicalSize = const Size(800, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dio = fakeDio(adapter);
    await tester.runAsync(() async {
      await MembershipRepository(
        db,
        dio,
      ).link(1, urn: 1, dob: DateTime(1990, 1, 1));
      await ProfileRepository(db, dio).refreshProfile(1);
    });
    if (!online) adapter.routes.remove('GET /app/clubs/1/profile');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(
            MembershipRepository(db, dio),
          ),
          memberProfileRepositoryProvider.overrideWithValue(
            MemberProfileRepository(db, dio),
          ),
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(db, dio),
          ),
          runPreferencesRepositoryProvider.overrideWithValue(
            RunPreferencesRepository(db, dio),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          activeAccountProvider.overrideWithValue(
            const Account(sub: 'test|sub', email: 'jo@example.com'),
          ),
          appVersionProvider.overrideWith((ref) async => '1.2.3 (4)'),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        // The app theme, so layout bugs from its button sizes show up here.
        child: MaterialApp(theme: BpjTheme.dark, home: const ProfileScreen()),
      ),
    );
    // Let the Drift streams and the background refresh complete.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the cached profile and refreshes quietly when online', (
    tester,
  ) async {
    await pumpProfile(tester, online: true);

    expect(find.text('Jo Bloggs'), findsOneWidget);
    expect(find.text('V40 · Women'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Leader'), findsOneWidget);
    expect(find.text('Registered'), findsOneWidget);
    expect(find.text('Race results'), findsOneWidget);
    expect(find.text('Claim an award'), findsOneWidget);
    // powerOf10 is null in the fixture, so the tile is hidden.
    expect(find.text('Power of 10'), findsNothing);
    expect(find.text('Signed in as jo@example.com'), findsOneWidget);
    expect(find.textContaining('Offline'), findsNothing);
    await unmount(tester);
  });

  testWidgets('committee see an Event locations row, members do not', (
    tester,
  ) async {
    await pumpProfile(tester, online: true);
    expect(find.text('Event locations'), findsNothing);
    await unmount(tester);

    adapter.routes['GET /app/clubs/1/profile'] = FakeResponse(200, {
      ...profileJson(),
      'roles': ['committee'],
    });
    await pumpProfile(tester, online: true);
    expect(find.text('Event locations'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('has an About & privacy row', (tester) async {
    await pumpProfile(tester, online: true);

    expect(find.text('About & privacy'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('has a My profile card row that prompts for a photo and bio', (
    tester,
  ) async {
    await pumpProfile(tester, online: true);

    expect(find.text('My profile card'), findsOneWidget);
    expect(find.text('Add a photo and a few words about you'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('lists the club website first, above the member links', (
    tester,
  ) async {
    await pumpProfile(tester, online: true);

    final website = tester.getTopLeft(find.text('Club website')).dy;
    expect(website, lessThan(tester.getTopLeft(find.text('Race results')).dy));
    expect(website, greaterThan(tester.getTopLeft(find.text('Links')).dy));

    await tester.tap(find.text('Club website'));
    await tester.pump();
    expect(opened, [Uri.parse('https://bpj.org.uk')]);
    await unmount(tester);
  });
  testWidgets(
    'shows the cached profile and an offline banner when refresh fails',
    (tester) async {
      await pumpProfile(tester, online: false);

      expect(find.text('Jo Bloggs'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(
        find.textContaining(
          'Offline — showing saved details (updated just now)',
        ),
        findsOneWidget,
      );
      // No full-screen error when there is a cache.
      expect(find.text("Couldn't load your profile."), findsNothing);
      await unmount(tester);
    },
  );

  group('running preferences card', () {
    String fieldText(WidgetTester tester, String key) {
      String t(String k) =>
          tester.widget<TextField>(find.byKey(ValueKey(k))).controller!.text;
      final m = t('$key-min');
      final s = t('$key-sec');
      if (m.isEmpty && s.isEmpty) return '';
      return '$m:${s.isEmpty ? '00' : s.padLeft(2, '0')}';
    }

    Future<void> typePace(
      WidgetTester tester,
      String key,
      String min, [
      String sec = '',
    ]) async {
      await tester.enterText(find.byKey(ValueKey('$key-min')), min);
      await tester.enterText(find.byKey(ValueKey('$key-sec')), sec);
    }

    testWidgets('shows the saved units and pace range', (tester) async {
      await pumpProfile(tester, online: true);

      expect(find.text('Running preferences'), findsOneWidget);
      expect(fieldText(tester, 'pace-from'), '9:00');
      expect(fieldText(tester, 'pace-to'), '10:00');
      final paceUnit = tester.widget<SegmentedButton<DistUnit>>(
        find.byKey(const ValueKey('pace-unit')),
      );
      expect(paceUnit.selected, {DistUnit.mi});
      final distUnit = tester.widget<SegmentedButton<DistUnit>>(
        find.byKey(const ValueKey('distance-unit')),
      );
      expect(distUnit.selected, {DistUnit.km});
      await unmount(tester);
    });

    bool saveEnabled(WidgetTester tester) =>
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-prefs')))
            .onPressed !=
        null;

    testWidgets('Save is disabled until the pace is valid and changed', (
      tester,
    ) async {
      await pumpProfile(tester, online: true);
      // Seeded from the cache: nothing changed yet.
      expect(saveEnabled(tester), isFalse);
      expect(find.text('Not saved yet'), findsNothing);

      // Invalid: no minutes.
      await typePace(tester, 'pace-from', '', '30');
      await tester.pump();
      expect(
        find.text('Enter minutes, like 9 (seconds are optional)'),
        findsOneWidget,
      );
      expect(saveEnabled(tester), isFalse);

      // Invalid: seconds out of range.
      await typePace(tester, 'pace-from', '9', '75');
      await tester.pump();
      expect(find.text('Seconds must be 0 to 59'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);

      // Invalid: reversed range.
      await typePace(tester, 'pace-from', '10', '30');
      await typePace(tester, 'pace-to', '9', '30');
      await tester.pump();
      expect(find.text('Must be the same or slower than From'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);

      // Invalid: outside 3:00-30:00.
      await typePace(tester, 'pace-to', '12');
      await typePace(tester, 'pace-from', '2');
      await tester.pump();
      expect(find.text('Between 3:00 and 30:00'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);

      // Valid and different from what is saved.
      await typePace(tester, 'pace-from', '8', '45');
      await tester.pump();
      expect(saveEnabled(tester), isTrue);
      expect(find.text('Not saved yet'), findsOneWidget);

      // Back to exactly the saved range: nothing to save.
      await typePace(tester, 'pace-from', '9');
      await typePace(tester, 'pace-to', '10');
      await tester.pump();
      expect(saveEnabled(tester), isFalse);
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      await unmount(tester);
    });

    testWidgets(
      'saving PUTs the pace, updates the shared provider, shows Saved',
      (tester) async {
        adapter.routes['PUT /app/clubs/1/preferences'] = const FakeResponse(
          200,
          {
            'paceUnit': 'mi',
            'distanceUnit': 'km',
            'paceFromS': 510,
            'paceToS': 570,
            'updatedAt': '2026-10-07T10:00:00.000Z',
          },
        );
        await pumpProfile(tester, online: true);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(RunPreferencesCard)),
        );
        // Not saved: the shared provider still holds the server's 9:00-10:00.
        await typePace(tester, 'pace-from', '8', '30');
        await typePace(tester, 'pace-to', '9', '30');
        await tester.pump();
        expect(
          container.read(runPreferencesProvider(1)).value!.paceFromS,
          540,
          reason: 'typing alone must not look saved',
        );
        expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);

        await tester.tap(find.byKey(const ValueKey('save-prefs')));
        await settle(tester);

        final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
        expect(put.data, {
          'paceUnit': 'mi',
          'distanceUnit': 'km',
          'paceFromS': 510,
          'paceToS': 570,
        });
        expect(find.byKey(const ValueKey('pace-saved')), findsOneWidget);
        expect(find.text('Not saved yet'), findsNothing);
        final prefs = container.read(runPreferencesProvider(1)).value!;
        expect(prefs.paceFromS, 510);
        expect(prefs.paceToS, 570);
        expect(saveEnabled(tester), isFalse);
        await unmount(tester);
      },
    );

    testWidgets('a unit change saves at once with the converted range', (
      tester,
    ) async {
      adapter.routes['PUT /app/clubs/1/preferences'] = const FakeResponse(200, {
        'paceUnit': 'km',
        'distanceUnit': 'km',
        'paceFromS': 336,
        'paceToS': 373,
        'updatedAt': '2026-10-07T10:00:00.000Z',
      });
      await pumpProfile(tester, online: true);

      await tester.tap(find.text('min/km'));
      await settle(tester);

      // 9:00/mi and 10:00/mi converted to the new unit.
      expect(fieldText(tester, 'pace-from'), '5:36');
      expect(fieldText(tester, 'pace-to'), '6:13');
      final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(put.data, {
        'paceUnit': 'km',
        'distanceUnit': 'km',
        'paceFromS': 336,
        'paceToS': 373,
      });
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RunPreferencesCard)),
      );
      expect(container.read(unitPrefsProvider).paceUnit, DistUnit.km);
      await unmount(tester);
    });

    testWidgets('a failed unit change goes back and explains', (tester) async {
      await pumpProfile(tester, online: true);

      await tester.tap(find.text('min/km')); // no PUT route: offline
      await settle(tester);

      expect(
        find.text('You need a connection to save your preferences.'),
        findsWidgets,
      );
      final paceUnit = tester.widget<SegmentedButton<DistUnit>>(
        find.byKey(const ValueKey('pace-unit')),
      );
      expect(paceUnit.selected, {DistUnit.mi});
      expect(fieldText(tester, 'pace-from'), '9:00');
      await unmount(tester);
    });

    testWidgets('a failed save keeps the typed pace and shows the error', (
      tester,
    ) async {
      await pumpProfile(tester, online: true);

      await typePace(tester, 'pace-from', '8');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await settle(tester); // no PUT route: the fake network is down

      expect(
        tester.widget<Text>(find.byKey(const ValueKey('pace-error'))).data,
        'You need a connection to save your preferences.',
      );
      expect(find.byKey(const ValueKey('pace-saved')), findsNothing);
      expect(fieldText(tester, 'pace-from'), '8:00');
      expect(saveEnabled(tester), isTrue, reason: 'can retry');
      await unmount(tester);
    });

    testWidgets('a server validation error is shown', (tester) async {
      adapter.routes['PUT /app/clubs/1/preferences'] = const FakeResponse(422, {
        'message': 'The pace from s must be between 180 and 1800.',
      });
      await pumpProfile(tester, online: true);

      await typePace(tester, 'pace-from', '8');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await settle(tester);

      expect(find.byKey(const ValueKey('pace-error')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Clear removes the stored pace straight away', (tester) async {
      adapter.routes['PUT /app/clubs/1/preferences'] = const FakeResponse(200, {
        'paceUnit': 'mi',
        'distanceUnit': 'km',
        'paceFromS': null,
        'paceToS': null,
        'updatedAt': '2026-10-07T10:00:00.000Z',
      });
      await pumpProfile(tester, online: true);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RunPreferencesCard)),
      );

      await tester.tap(find.byKey(const ValueKey('clear-pace')));
      await settle(tester);

      expect(fieldText(tester, 'pace-from'), '');
      final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(put.data, containsPair('paceFromS', null));
      expect(put.data, containsPair('paceToS', null));
      expect(
        container.read(runPreferencesProvider(1)).value!.usualPace.isNone,
        isTrue,
      );
      expect(find.byKey(const ValueKey('pace-saved')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Clear with nothing saved only empties the boxes', (
      tester,
    ) async {
      adapter.routes['GET /app/clubs/1/preferences'] = const FakeResponse(200, {
        'paceUnit': 'mi',
        'distanceUnit': 'mi',
        'paceFromS': null,
        'paceToS': null,
        'updatedAt': null,
      });
      await pumpProfile(tester, online: true);

      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('clear-pace')))
            .onPressed,
        isNull,
      );
      await typePace(tester, 'pace-from', '8');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('clear-pace')));
      await tester.pump();
      expect(fieldText(tester, 'pace-from'), '');
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      await unmount(tester);
    });
  });
}

/// Drift schedules a zero-length timer when a watched query is cancelled, and
/// flutter_test fails a test that ends with a timer pending. Unmounting the tree
/// inside the test body (then pumping) lets those timers fire first.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

/// Lets an in-flight save (dio, Drift) finish: real time for I/O, then pumps
/// for the fake-async microtasks and timers.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
}
