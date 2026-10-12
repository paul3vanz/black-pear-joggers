import 'dart:async' show unawaited;

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/logic/roster.dart';
import 'package:bpj/features/groups/ui/group_format.dart';
import 'package:bpj/features/groups/ui/leader_roster_screen.dart';
import 'package:bpj/features/runs/data/run_dtos.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/runs/data/session_changes.dart';
import 'package:bpj/features/runs/logic/run_modes.dart';
import 'package:bpj/features/runs/ui/runs_screen.dart';
import 'package:bpj/features/runs/ui/series_screens.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:bpj/features/runs/ui/session_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

/// Phase 8b: the `events` and `race` group modes (D76, D79) and runs without a
/// venue.
void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  group('run mode helpers', () {
    test('events and race are event-like, never pace groups', () {
      expect(isEventsMode('events'), isTrue);
      expect(isEventsMode('race'), isFalse);
      expect(isRaceMode('race'), isTrue);
      expect(isRaceMode('events'), isFalse);
      expect(isEventLikeMode('events'), isTrue);
      expect(isEventLikeMode('race'), isTrue);
      expect(isEventLikeMode('paced'), isFalse);
    });

    test('usesPaceGroups is true for paced, single and open only', () {
      expect(usesPaceGroups('paced'), isTrue);
      expect(usesPaceGroups('single'), isTrue);
      expect(usesPaceGroups('open'), isTrue);
      expect(usesPaceGroups('routes'), isFalse);
      expect(usesPaceGroups('events'), isFalse);
      expect(usesPaceGroups('race'), isFalse);
    });

    test('series cannot be races; ad-hoc runs can', () {
      expect(seriesGroupModes, contains('events'));
      expect(seriesGroupModes, isNot(contains('race')));
      expect(adHocGroupModes, containsAll(['events', 'race']));
    });

    test('labels and explainers', () {
      expect(groupModeLabel('events'), 'Events (e.g. parkrun)');
      expect(groupModeLabel('race'), 'Race (one event)');
      expect(groupModeExplainer('events'), isNotEmpty);
      expect(groupModeExplainer('race'), isNotEmpty);
    });

    test('the pace note and kind label cope with the new values', () {
      expect(showsPaceGroupsNote('events'), isFalse);
      expect(showsPaceGroupsNote('race'), isFalse);
      expect(showsPaceGroupsNote('paced'), isTrue);
      expect(groupKindLabel('event'), 'Event');
    });
  });

  group('roster guard', () {
    Session s(String id, String mode) => Session(
      id: id,
      clubId: 1,
      title: id,
      startsAt: DateTime.utc(2026, 10, 12, 18),
      endsAt: DateTime.utc(2026, 10, 12, 19, 30),
      localDate: '2026-10-12',
      localStartTime: '19:00',
      localEndTime: '20:30',
      groupMode: mode,
      status: 'scheduled',
      seriesId: null,
      occurrenceDate: null,
      venueId: null,
      notes: null,
      cancelReason: null,
      coordinatorMemberId: null,
      coordinatorName: null,
      originalJson: null,
      groupsJson: null,
      summaryJson: null,
      isDetached: false,
      updatedAt: DateTime.utc(2026, 10, 1),
    );

    test('Lead a run skips events and race runs', () {
      final weeks = buildRoster([
        s('p', 'paced'),
        s('e', 'events'),
        s('r', 'race'),
        s('o', 'open'),
      ], testNow);
      expect(weeks.expand((w) => w.sessions).map((x) => x.id), ['p', 'o']);
    });
  });

  group('screens', () {
    Future<void> seedAll(
      WidgetTester tester, {
      List<Map<String, Object?>> series = const [],
      List<Map<String, Object?>> sessions = const [],
    }) => tester.runAsync(() async {
      await db
          .into(db.venues)
          .insert(
            VenueDto.fromJson(venueJson('v1', name: 'OECC')).toCompanion(1),
          );
      for (final j in series) {
        await db
            .into(db.sessionSeries)
            .insert(SeriesDto.fromJson(j).toCompanion(1));
      }
      for (final j in sessions) {
        await db
            .into(db.sessions)
            .insert(SessionDto.fromJson(j).toCompanion(1));
      }
    });

    testWidgets('a run and a series with no venue show no venue row', (
      tester,
    ) async {
      final adapter = await prepareMember(tester, db);
      final today = localDateString(DateTime.now());
      await seedAll(
        tester,
        series: [
          seriesJson(
            's1',
            title: 'Saturday parkrun',
            venueId: null,
            groupMode: 'events',
          ),
        ],
        sessions: [
          sessionJson(
            'a',
            localDate: today,
            title: 'Saturday parkrun',
            venueId: null,
            groupMode: 'events',
          ),
        ],
      );
      await pumpGroupsApp(tester, db, adapter, const RunsScreen());
      expect(find.text('Saturday parkrun'), findsOneWidget);
      expect(find.text('Events (e.g. parkrun)'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      await unmount(tester);

      await pumpGroupsApp(tester, db, adapter, const SeriesListScreen());
      // "Mon 7pm-8:30pm · Events (e.g. parkrun)": no empty segment.
      expect(find.textContaining(' ·  · '), findsNothing);
      expect(find.textContaining('· Events (e.g. parkrun)'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the run page for a no-venue run has no place row', (
      tester,
    ) async {
      final adapter = await prepareMember(tester, db);
      await tester.runAsync(
        () => seedSession(db, 'a', groupMode: 'events', groups: const []),
      );
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const SessionDetailScreen(sessionId: 'a'),
      );
      expect(find.byIcon(Icons.place_outlined), findsNothing);
      expect(find.text('Open in maps'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await unmount(tester);
    });

    testWidgets('committee coverage and the pace note skip events and races', (
      tester,
    ) async {
      for (final mode in ['events', 'race']) {
        final adapter = await prepareMember(tester, db, roles: ['committee']);
        await tester.runAsync(
          () => seedSession(db, 'a$mode', groupMode: mode, groups: const []),
        );
        await pumpGroupsApp(
          tester,
          db,
          adapter,
          SessionDetailScreen(sessionId: 'a$mode'),
        );
        expect(find.text('Group coverage'), findsNothing, reason: mode);
        expect(
          find.textContaining('Other pace groups will be confirmed'),
          findsNothing,
          reason: mode,
        );
        await tester.pump(const Duration(seconds: 6));
        await unmount(tester);
      }
    });

    testWidgets('"I am coming" on an events run offers no pace groups', (
      tester,
    ) async {
      final adapter = await prepareMember(
        tester,
        db,
        routes: {
          'PUT /app/clubs/1/sessions/a/attendance': FakeResponse(
            200,
            attendanceJson('a'),
          ),
        },
      );
      await tester.runAsync(() async {
        await seedSession(
          db,
          'a',
          groupMode: 'events',
          groups: [groupJson('g1', label: 'Worcester parkrun')],
          summary: summaryJson(groupCount: 1),
        );
        await seedUnits(db);
      });
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const SessionDetailScreen(sessionId: 'a'),
      );
      await tester.tap(find.text("I'm coming"));
      await settle(tester);
      expect(find.text('Pick your pace group?'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await unmount(tester);
    });

    testWidgets('Lead a run lists no events runs', (tester) async {
      final adapter = await prepareMember(tester, db);
      await tester.runAsync(() async {
        await seedUnits(db);
        await seedSession(db, 'p', groupMode: 'paced', groups: const []);
        await seedSession(db, 'e', groupMode: 'events', groups: const []);
      });
      await pumpGroupsApp(tester, db, adapter, const LeaderRosterScreen());
      expect(find.text('Monday club run'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('editors', () {
    late FakeAdapter adapter;

    Future<void> pumpEditor(
      WidgetTester tester,
      Widget editor, {
      Map<String, Object> routes = const {},
    }) async {
      adapter = await prepareMember(
        tester,
        db,
        routes: {
          'GET /app/clubs/1/sessions': FakeResponse(200, {
            'items': <Object>[],
            'serverTime': '2026-10-07T12:00:00.000Z',
          }),
          ...routes,
        },
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/edit', builder: (_, _) => editor),
        ],
      );
      await pumpGroupsRouter(tester, db, adapter, router);
      unawaited(router.push('/edit'));
      await settle(tester);
    }

    Map<String, Object?> lastBody(String method) =>
        (adapter.requests.lastWhere((r) => r.method == method).data!
                as Map<Object?, Object?>)
            .cast<String, Object?>();

    Finder modeDropdown() => find.byType(DropdownButtonFormField<String>);

    Future<void> openModes(WidgetTester tester) async {
      await tester.ensureVisible(modeDropdown());
      await tester.tap(modeDropdown());
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Save'));
      await settle(tester);
    }

    testWidgets('series editor offers Events but not Race', (tester) async {
      await pumpEditor(tester, const SeriesEditScreen());
      await openModes(tester);
      expect(find.text('Events (e.g. parkrun)'), findsOneWidget);
      expect(find.text('Race (one event)'), findsNothing);
      await unmount(tester);
    });

    testWidgets('ad-hoc editor offers Events and Race', (tester) async {
      await pumpEditor(tester, const SessionEditScreen());
      await openModes(tester);
      expect(find.text('Events (e.g. parkrun)'), findsOneWidget);
      expect(find.text('Race (one event)'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('saving an ad-hoc race sends groupMode race and no venue', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        const SessionEditScreen(),
        routes: {
          'POST /app/clubs/1/sessions': FakeResponse(
            201,
            sessionJson(
              'x',
              localDate: '2026-11-01',
              seriesId: null,
              venueId: null,
              groupMode: 'race',
            ),
          ),
        },
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Droitwich 10k',
      );
      await openModes(tester);
      await tester.tap(find.text('Race (one event)').last);
      await tester.pumpAndSettle();
      await save(tester);
      final body = lastBody('POST');
      expect(body['groupMode'], 'race');
      expect(body.containsKey('venueId'), isTrue);
      expect(body['venueId'], isNull);
      await unmount(tester);
    });

    testWidgets('an events series saves with groupMode events', (tester) async {
      await pumpEditor(
        tester,
        const SeriesEditScreen(),
        routes: {
          'POST /app/clubs/1/series': FakeResponse(
            201,
            seriesJson('n', venueId: null, groupMode: 'events'),
          ),
        },
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Saturday parkrun',
      );
      await openModes(tester);
      await tester.tap(find.text('Events (e.g. parkrun)').last);
      await tester.pumpAndSettle();
      await save(tester);
      expect(lastBody('POST')['groupMode'], 'events');
      expect(lastBody('POST')['venueId'], isNull);
      await unmount(tester);
    });

    testWidgets('choosing "No venue" on a series with a venue sends null', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await db
            .into(db.venues)
            .insert(
              VenueDto.fromJson(venueJson('v1', name: 'OECC')).toCompanion(1),
            );
        await db
            .into(db.sessionSeries)
            .insert(SeriesDto.fromJson(seriesJson('s1')).toCompanion(1));
      });
      await pumpEditor(
        tester,
        const SeriesEditScreen(seriesId: 's1'),
        routes: {
          'PATCH /app/clubs/1/series/s1': FakeResponse(
            200,
            seriesJson('s1', venueId: null),
          ),
        },
      );
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String?>));
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No venue').last);
      await tester.pumpAndSettle();
      await save(tester);
      expect(lastBody('PATCH')['venueId'], isNull);
      await unmount(tester);
    });
  });
}
