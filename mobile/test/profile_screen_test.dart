import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/profile/data/profile_repository.dart';
import 'package:bpj/features/profile/ui/profile_providers.dart';
import 'package:bpj/features/profile/ui/profile_screen.dart';
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
        child: const MaterialApp(home: ProfileScreen()),
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

    testWidgets('rejects bad paces and a reversed range', (tester) async {
      await pumpProfile(tester, online: true);

      await typePace(tester, 'pace-from', '', '30');
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await tester.pump();
      expect(
        find.text('Enter minutes, like 9 (seconds are optional)'),
        findsOneWidget,
      );

      await typePace(tester, 'pace-from', '9', '75');
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await tester.pump();
      expect(find.text('Seconds must be 0 to 59'), findsOneWidget);

      await typePace(tester, 'pace-from', '10', '30');
      await typePace(tester, 'pace-to', '9', '30');
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await tester.pump();
      expect(find.text('Must be the same or slower than From'), findsOneWidget);

      await typePace(tester, 'pace-from', '2');
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await tester.pump();
      expect(find.text('Between 3:00 and 30:00'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      await unmount(tester);
    });

    testWidgets('saving PUTs the new values and shows a snackbar', (
      tester,
    ) async {
      adapter.routes['PUT /app/clubs/1/preferences'] = const FakeResponse(200, {
        'paceUnit': 'km',
        'distanceUnit': 'km',
        'paceFromS': 330,
        'paceToS': 360,
        'updatedAt': '2026-10-07T10:00:00.000Z',
      });
      await pumpProfile(tester, online: true);

      await tester.tap(find.text('min/km'));
      await tester.pump();
      // 9:00/mi and 10:00/mi converted to the new unit.
      expect(fieldText(tester, 'pace-from'), '5:36');
      await typePace(tester, 'pace-from', '5', '30');
      await typePace(tester, 'pace-to', '6');
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await settle(tester);

      final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(put.data, {
        'paceUnit': 'km',
        'distanceUnit': 'km',
        'paceFromS': 330,
        'paceToS': 360,
      });
      expect(find.text('Running preferences saved'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('clear then save sends null, and offline save explains', (
      tester,
    ) async {
      await pumpProfile(tester, online: true);

      await tester.tap(find.byKey(const ValueKey('clear-pace')));
      await tester.pump();
      expect(fieldText(tester, 'pace-from'), '');
      await tester.tap(find.byKey(const ValueKey('save-prefs')));
      await settle(tester);

      // No PUT route: the fake network is down.
      expect(
        find.text('You need a connection to save your preferences.'),
        findsOneWidget,
      );
      final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(put.data, containsPair('paceFromS', null));
      expect(put.data, containsPair('paceToS', null));
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
