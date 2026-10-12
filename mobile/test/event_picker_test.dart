import 'dart:convert';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/events/data/event_dtos.dart';
import 'package:bpj/features/events/data/event_locations_repository.dart';
import 'package:bpj/features/events/logic/recent_events.dart';
import 'package:bpj/features/events/ui/event_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase8.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  EventPick? picked;
  var closed = false;

  setUp(() {
    db = memoryDb();
    picked = null;
    closed = false;
  });
  tearDown(() => db.close());

  final locations = [
    eventLocationJson('l-abbey', name: 'Abbey Park parkrun', slug: 'abbeypark'),
    eventLocationJson(
      'l-bromsgrove',
      name: 'Bromsgrove parkrun',
      slug: 'bromsgrove',
      region: 'Worcestershire',
    ),
    eventLocationJson(
      'l-cannon',
      name: 'Cannon Hill parkrun',
      region: 'West Midlands',
    ),
    eventLocationJson(
      'l-worcester',
      name: 'Worcester parkrun',
      slug: 'worcester',
      region: 'Worcestershire',
    ),
    eventLocationJson(
      'l-droitwich',
      kind: 'race',
      name: 'Droitwich 10k',
      source: 'manual',
    ),
  ];

  /// Cached runs: Worcester is used on three, Bromsgrove on one. Cannon Hill is
  /// too old (before the 12 weeks) and Abbey Park only on a cancelled run.
  Future<void> seed({List<Map<String, Object?>>? rows}) async {
    for (final j in rows ?? locations) {
      await db
          .into(db.eventLocations)
          .insert(EventLocationDto.fromJson(j).toCompanion(1));
    }
    Future<void> run(
      String id,
      String date,
      List<String> locs, {
      String status = 'scheduled',
    }) => seedSession(
      db,
      id,
      localDate: date,
      groupMode: 'events',
      status: status,
      groups: [
        for (final l in locs)
          eventGroupJson('g-$id-$l', sessionId: id, locationId: l),
      ],
    );
    await run('a', '2026-10-12', ['l-worcester']);
    await run('b', '2026-10-05', ['l-bromsgrove', 'l-worcester']);
    await run('c', '2026-09-28', ['l-worcester']);
    await run('d', '2026-06-01', ['l-cannon']);
    await run('e', '2026-10-05', ['l-abbey'], status: 'cancelled');
  }

  Future<void> open(
    WidgetTester tester, {
    bool allowCreate = false,
    List<String> used = const [],
    Map<String, Object> routes = const {},
    String sessionId = 'a',
    List<Map<String, Object?>>? rows,
  }) async {
    adapter = FakeAdapter({
      'GET /app/clubs/1/event-locations': FakeResponse(
        200,
        eventLocationsResponse(rows ?? locations),
      ),
      ...routes,
    });
    final dio = fakeDio(adapter);
    await tester.runAsync(() => seed(rows: rows));
    tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, dio),
          eventLocationsRepositoryProvider.overrideWithValue(
            EventLocationsRepository(db, dio, clock: () => testNow),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showEventPicker(
                      context,
                      ref,
                      clubId: 1,
                      sessionId: sessionId,
                      usedLocationIds: used,
                      allowCreate: allowCreate,
                    );
                    closed = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await unmount(tester);
  }

  group('rankRecentLocationIds', () {
    Session s(
      String id,
      String date,
      List<String> locs, {
      String status = 'scheduled',
    }) => Session(
      id: id,
      clubId: 1,
      title: id,
      startsAt: DateTime.utc(2026, 10, 12, 9),
      endsAt: DateTime.utc(2026, 10, 12, 11),
      localDate: date,
      localStartTime: '09:00',
      localEndTime: null,
      groupMode: 'events',
      status: status,
      seriesId: null,
      occurrenceDate: null,
      venueId: null,
      notes: null,
      cancelReason: null,
      coordinatorMemberId: null,
      coordinatorName: null,
      originalJson: null,
      groupsJson: jsonEncode([
        for (final l in locs) eventGroupJson('g$id$l', locationId: l),
      ]),
      summaryJson: null,
      isDetached: false,
      updatedAt: DateTime.utc(2026, 10, 1),
    );

    test('most used first, ties by recency, once per run', () {
      final ids = rankRecentLocationIds([
        s('1', '2026-10-01', ['x', 'y']),
        s('2', '2026-10-08', ['y', 'z']),
        s('3', '2026-09-20', ['x']),
        s('4', '2026-10-08', ['x', 'x']), // twice on one run counts once
      ], sinceDate: '2026-07-01');
      // x: 3 runs, y: 2, z: 1.
      expect(ids, ['x', 'y', 'z']);
    });

    test('ignores cancelled runs, old runs and groups without a location', () {
      final ids = rankRecentLocationIds([
        s('1', '2026-10-01', ['a'], status: 'cancelled'),
        s('2', '2026-05-01', ['b']),
        s('3', '2026-10-01', ['c']),
      ], sinceDate: '2026-07-01');
      expect(ids, ['c']);
    });
  });

  testWidgets('recently used first, then A to Z, with the refresh on open', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Recently used by the club'), findsOneWidget);
    expect(find.text('All events, A to Z'), findsOneWidget);
    // Worcester (3 runs) then Bromsgrove (1), above the alphabetical list.
    final worcester = tester.getTopLeft(find.text('Worcester parkrun').first);
    final bromsgrove = tester.getTopLeft(find.text('Bromsgrove parkrun').first);
    final abbey = tester.getTopLeft(find.text('Abbey Park parkrun'));
    expect(worcester.dy, lessThan(bromsgrove.dy));
    expect(bromsgrove.dy, lessThan(abbey.dy));
    // Each recent also appears in the full list.
    expect(find.text('Worcester parkrun'), findsNWidgets(2));
    // Cannon Hill (too old) and Abbey Park (cancelled run) are not recent.
    expect(find.text('Cannon Hill parkrun'), findsOneWidget);
    expect(find.text('Abbey Park parkrun'), findsOneWidget);
    // A race shows its kind.
    expect(find.text('Race'), findsOneWidget);
    expect(
      adapter.requests.where(
        (r) => r.method == 'GET' && r.path.endsWith('/event-locations'),
      ),
      isNotEmpty,
    );
    await finish(tester);
  });

  testWidgets('search is case-insensitive over name, region and slug', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'BROMS');
    await tester.pump();
    expect(find.text('Bromsgrove parkrun'), findsOneWidget);
    expect(find.text('Worcester parkrun'), findsNothing);
    expect(find.text('Recently used by the club'), findsNothing);

    // By region: Worcestershire matches two.
    await tester.enterText(find.byType(TextField), 'worcestershire');
    await tester.pump();
    expect(find.text('Bromsgrove parkrun'), findsOneWidget);
    expect(find.text('Worcester parkrun'), findsOneWidget);
    expect(find.text('Abbey Park parkrun'), findsNothing);

    // By slug.
    await tester.enterText(find.byType(TextField), 'abbeypark');
    await tester.pump();
    expect(find.text('Abbey Park parkrun'), findsOneWidget);
    expect(find.text('Bromsgrove parkrun'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.textContaining('Nothing matches'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('locations already on the run say so but can still be picked', (
    tester,
  ) async {
    // Run "a" already has Worcester; "used" adds Bromsgrove.
    await open(tester, used: ['l-bromsgrove']);
    expect(
      find.text('Already added'),
      findsNWidgets(4),
    ); // 2 each, recent + A-Z
    await tester.tap(find.text('Worcester parkrun').first);
    await settle(tester);
    expect(closed, isTrue);
    expect(picked?.locationId, 'l-worcester');
    expect(picked?.name, 'Worcester parkrun');
    expect(picked?.isFreeText, isFalse);
    await finish(tester);
  });

  testWidgets('"Other..." returns the typed name as free text', (tester) async {
    await open(tester);
    await tester.tap(find.text('Other...'));
    await tester.pumpAndSettle();
    expect(find.text('Save for next time'), findsNothing); // allowCreate off
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '  Bath Skyline  ');
    await tester.pump();
    await tester.tap(find.text('Use this name'));
    await settle(tester);
    expect(picked?.isFreeText, isTrue);
    expect(picked?.name, 'Bath Skyline');
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    await finish(tester);
  });

  testWidgets('the search text carries over to "Other..."', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Parkrun nowhere');
    await tester.pump();
    await tester.tap(find.text('Other...'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Parkrun nowhere'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Save for next time posts a race location and returns it', (
    tester,
  ) async {
    await open(
      tester,
      allowCreate: true,
      routes: {
        'POST /app/clubs/1/event-locations': FakeResponse(
          201,
          eventLocationJson(
            'new-id',
            kind: 'race',
            name: 'Bath Skyline',
            source: 'manual',
          ),
        ),
      },
    );
    await tester.tap(find.text('Other...'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bath Skyline');
    await tester.tap(find.text('Save for next time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this name'));
    await settle(tester);

    final post = adapter.requests.singleWhere((r) => r.method == 'POST');
    final body = post.data as Map;
    expect(body['kind'], 'race');
    expect(body['name'], 'Bath Skyline');
    expect(body['id'], isNotEmpty);
    expect(picked?.locationId, 'new-id');
    expect(picked?.name, 'Bath Skyline');
    // The new location is cached for next time.
    final rows = await tester.runAsync(
      () => (db.select(
        db.eventLocations,
      )..where((l) => l.id.equals('new-id'))).get(),
    );
    expect(rows, hasLength(1));
    await finish(tester);
  });

  testWidgets('saving as "Other" kind posts other', (tester) async {
    await open(
      tester,
      allowCreate: true,
      routes: {
        'POST /app/clubs/1/event-locations': FakeResponse(
          201,
          eventLocationJson('n', kind: 'other', name: 'Fell'),
        ),
      },
    );
    await tester.tap(find.text('Other...'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fell');
    await tester.tap(find.text('Save for next time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this name'));
    await settle(tester);
    expect(
      (adapter.requests.singleWhere((r) => r.method == 'POST').data
          as Map)['kind'],
      'other',
    );
    await finish(tester);
  });

  testWidgets('offline save shows an error and stays open', (tester) async {
    await open(tester, allowCreate: true);
    await tester.tap(find.text('Other...'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bath Skyline');
    await tester.tap(find.text('Save for next time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this name'));
    await settle(tester);
    expect(closed, isFalse);
    expect(find.textContaining('You need a connection'), findsOneWidget);
    // Unticking uses the name without saving.
    await tester.tap(find.text('Save for next time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this name'));
    await settle(tester);
    expect(picked?.name, 'Bath Skyline');
    expect(picked?.isFreeText, isTrue);
    await finish(tester);
  });

  testWidgets('800 locations build lazily', (tester) async {
    final rows = [
      for (var i = 0; i < 800; i++)
        eventLocationJson(
          'id$i',
          name: 'Place ${i.toString().padLeft(3, '0')} parkrun',
        ),
    ];
    await open(tester, rows: rows);
    expect(find.text('Place 000 parkrun'), findsOneWidget);
    // Only the rows near the viewport are built.
    expect(find.byType(ListTile).evaluate().length, lessThan(200));
    await tester.enterText(find.byType(TextField), 'place 799');
    await tester.pump();
    expect(find.text('Place 799 parkrun'), findsOneWidget);
    await finish(tester);
  });
}
