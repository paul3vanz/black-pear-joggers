import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/groups/data/small_kv_store.dart';
import 'package:bpj/features/profile/ui/profile_providers.dart';
import 'package:bpj/features/profile/ui/profile_screen.dart';
import 'package:bpj/features/standards/data/standards_repository.dart';
import 'package:bpj/features/standards/ui/standards_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase9.dart';
import 'support/groups_test_support.dart';

const _path = '/app/clubs/1/standards';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late Dio dio;
  final opened = <Uri>[];
  // The cache was filled 3 days before the test clock (2026-10-07 12:00).
  final cachedAt = testNow.subtract(const Duration(days: 3));

  setUp(() {
    opened.clear();
    db = memoryDb();
  });
  tearDown(() => db.close());

  /// Pumps the screen. [cache] fills the standards cache first (as an earlier
  /// online visit would, 3 days ago). [online] true makes the screen's own
  /// refresh answer 304 (unchanged); false makes it fail (no route).
  Future<void> pump(
    WidgetTester tester, {
    Map<String, Object?>? json,
    bool cache = true,
    bool online = true,
    String paceUnit = 'mi',
    Size size = const Size(800, 3000),
    Widget? home,
    bool introSeen = true,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      routes: {
        'GET /app/clubs/1/preferences': FakeResponse(200, {
          'paceUnit': paceUnit,
          'distanceUnit': 'mi',
          'paceFromS': null,
          'paceToS': null,
          'updatedAt': '2026-10-01T10:00:00.000Z',
        }),
        'GET $_path': FakeResponse(200, json ?? standardsJson(), {
          'etag': '"v1"',
        }),
      },
    );
    dio = fakeDio(adapter);
    await tester.runAsync(() async {
      await RunPreferencesRepository(db, dio).refresh(1);
      if (cache) {
        await StandardsRepository(db, dio, clock: () => cachedAt).refresh(1);
      }
      if (introSeen) {
        await SmallKvStore(db).set(SmallKvStore.standardsIntroSeenKey, '1');
      }
    });
    // From here on the server is unreachable, or says "unchanged".
    if (online) {
      adapter.routes['GET $_path'] = const FakeResponse(304);
    } else {
      adapter.routes.remove('GET $_path');
    }

    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, dio),
          standardsRepositoryProvider.overrideWithValue(
            // fetchedAt after a 304 is the test clock.
            StandardsRepository(db, dio, clock: () => cachedAt),
          ),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: MaterialApp(home: home ?? const StandardsScreen()),
      ),
    );
    await settle(tester);
  }

  Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

  bool chipSelected(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(chip(label)).selected;

  testWidgets("opens on the viewer's own category and marks it", (
    tester,
  ) async {
    await pump(tester); // mine = female V50
    expect(find.text('Club standards awards'), findsOneWidget);
    expect(chipSelected(tester, 'V50'), isTrue);
    expect(chipSelected(tester, 'SEN'), isFalse);
    // The star marks mine; it is announced as "Your category".
    expect(
      find.descendant(
        of: chip('V50'),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Your category'), findsOneWidget);
    expect(find.text('Showing your category'), findsOneWidget);
    expect(find.text('Back to mine'), findsNothing);
    // Women V50: 5K bronze is 31:20.
    expect(find.text('31:20'), findsOneWidget);
    expect(find.text('Platinum'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('switching gender and category updates the table, Back to mine '
      'returns', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Men'));
    await settle(tester);
    // Mine is women V50; men have no V50, so it falls to SEN.
    expect(chipSelected(tester, 'SEN'), isTrue);
    expect(find.text('Showing SEN men'), findsOneWidget);
    expect(find.text('25:48'), findsOneWidget);
    expect(find.text('Back to mine'), findsOneWidget);
    // The star is only on women's V50.
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    await tester.tap(chip('V45'));
    await settle(tester);
    expect(find.text('Showing V45 men'), findsOneWidget);
    expect(find.text('26:30'), findsOneWidget);
    expect(find.text('25:48'), findsNothing);

    await tester.tap(find.text('Back to mine'));
    await settle(tester);
    expect(chipSelected(tester, 'V50'), isTrue);
    expect(find.text('Showing your category'), findsOneWidget);
    expect(find.text('31:20'), findsOneWidget);

    // Going Men then Women again lands on mine too.
    await tester.tap(find.text('Men'));
    await settle(tester);
    await tester.tap(find.text('Women'));
    await settle(tester);
    expect(chipSelected(tester, 'V50'), isTrue);
    await unmount(tester);
  });

  testWidgets('hides events that have no standards for the category', (
    tester,
  ) async {
    await pump(tester); // women V50 has Mile and 5K only
    expect(find.text('Mile'), findsOneWidget);
    expect(find.text('5K'), findsOneWidget);
    expect(find.text('Half Marathon'), findsNothing);

    await tester.tap(chip('SEN'));
    await settle(tester);
    expect(find.text('Half Marathon'), findsOneWidget);
    expect(find.text('2:15:00'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('with no known category it opens on Men SEN and says why', (
    tester,
  ) async {
    await pump(tester, json: standardsJson(mine: null));
    expect(chipSelected(tester, 'SEN'), isTrue);
    expect(find.textContaining('Link your membership'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.text('25:48'), findsOneWidget);
    await unmount(tester);
  });

  group('Time / Pace', () {
    testWidgets("pace uses the viewer's unit (min/mile)", (tester) async {
      await pump(tester, paceUnit: 'mi');
      await tester.tap(find.text('Men'));
      await settle(tester);
      expect(find.text('Pace (min/mile)'), findsOneWidget);
      await tester.tap(find.text('Pace (min/mile)'));
      await settle(tester);
      // 5K in 25:48 is 8:18/mi; the time itself is gone.
      expect(find.text('8:18/mi'), findsOneWidget);
      expect(find.text('25:48'), findsNothing);
      expect(find.textContaining('not pace'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets("pace uses the viewer's unit (min/km)", (tester) async {
      await pump(tester, paceUnit: 'km');
      await tester.tap(find.text('Men'));
      await settle(tester);
      await tester.tap(find.text('Pace (min/km)'));
      await settle(tester);
      expect(find.text('5:10/km'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the choice is remembered on the device', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Pace (min/mile)'));
      await settle(tester);
      expect(
        await tester.runAsync(
          () => SmallKvStore(db).get(SmallKvStore.standardsShowPaceKey),
        ),
        '1',
      );
      await unmount(tester);

      // A new visit opens on Pace. (Same db, so the stored choice is read.)
      await pump(tester, cache: false);
      expect(find.text('10:05/mi'), findsOneWidget); // 31:20 over 5K
      expect(find.text('31:20'), findsNothing);
      await unmount(tester);
    });
  });

  testWidgets('the last picked category is not remembered', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Men'));
    await settle(tester);
    expect(chipSelected(tester, 'SEN'), isTrue);
    await unmount(tester);

    // The cache survives in the same db; reopening starts on mine again.
    await pump(tester, cache: false);
    expect(chipSelected(tester, 'V50'), isTrue);
    await unmount(tester);
  });

  testWidgets('How it works is open the first time and collapsed after', (
    tester,
  ) async {
    await pump(tester, introSeen: false);
    expect(find.textContaining('in three of the five events'), findsOneWidget);
    await unmount(tester);

    await pump(tester, cache: false, introSeen: false);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.textContaining('in three of the five events'), findsNothing);

    await tester.tap(find.text('How it works'));
    await settle(tester);
    expect(find.textContaining('in three of the five events'), findsOneWidget);
    expect(find.textContaining('licensed event'), findsOneWidget);
    expect(find.textContaining('Magic Mile'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the claim button opens the website claim page', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Claim an award on the website'));
    await tester.tap(find.text('Claim an award on the website'));
    await tester.pump();
    expect(opened, [Uri.parse('https://bpj.org.uk/claim-award')]);
    await unmount(tester);
  });

  group('offline and loading', () {
    testWidgets('online shows a quiet "Updated" line, no banner', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Updated 3 days ago'), findsOneWidget);
      expect(find.textContaining('Offline'), findsNothing);
      await unmount(tester);
    });

    testWidgets('offline with a cache shows the saved table and a banner', (
      tester,
    ) async {
      await pump(tester, online: false);
      expect(find.text('31:20'), findsOneWidget);
      expect(
        find.text('Offline — showing saved standards. Updated 3 days ago'),
        findsOneWidget,
      );
      expect(find.textContaining("Couldn't load"), findsNothing);
      await unmount(tester);
    });

    testWidgets('no cache and no network shows a retry that works', (
      tester,
    ) async {
      await pump(tester, cache: false, online: false);
      expect(find.textContaining("Couldn't load"), findsOneWidget);
      expect(find.text('Club standards awards'), findsNothing);

      adapter.routes['GET $_path'] = FakeResponse(200, standardsJson(), {
        'etag': '"v1"',
      });
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.text('Club standards awards'), findsOneWidget);
      expect(find.text('31:20'), findsOneWidget);
      await unmount(tester);
    });
  });

  testWidgets('a 320 px wide phone does not overflow, in time and pace', (
    tester,
  ) async {
    await pump(tester, size: const Size(320, 700));
    await tester.tap(find.text('Men')); // Men SEN has 1:58:26
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('1:58:26'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1:58:26'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Pace (min/mile)'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('a 320 px phone with large text still lays out', (tester) async {
    await pump(
      tester,
      size: const Size(320, 700),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: const StandardsScreen(),
        ),
      ),
    );
    await tester.tap(find.text('Men'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('the Profile tab row opens the screen and Back returns', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'standards',
              builder: (_, _) => const StandardsScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    adapter = await prepareMember(
      tester,
      db,
      routes: {
        'GET /app/clubs/1/profile': FakeResponse(200, profileJson()),
        'GET /app/clubs/1/preferences': const FakeResponse(200, {
          'paceUnit': 'mi',
          'distanceUnit': 'mi',
        }),
        'GET $_path': FakeResponse(200, standardsJson(), {'etag': '"v1"'}),
      },
    );
    dio = fakeDio(adapter);
    tester.view
      ..physicalSize = const Size(800, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, dio),
          activeAccountProvider.overrideWithValue(
            const Account(sub: 'test|sub', email: 'jo@example.com'),
          ),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);

    expect(find.text('Club standards'), findsOneWidget);
    expect(find.text('Targets for your age category'), findsOneWidget);
    await tester.tap(find.text('Club standards'));
    await settle(tester);
    expect(find.text('Club standards awards'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    expect(find.text('Club standards awards'), findsNothing);
    expect(find.text('Targets for your age category'), findsOneWidget);
    await unmount(tester);
  });
}
