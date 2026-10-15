import 'dart:async';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/distance.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/data/last_group_store.dart';
import 'package:bpj/features/groups/ui/group_editor_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const easy = LastGroupSpec(
    label: 'Easy',
    description: 'No drop',
    pace: SinglePace(Pace(600, DistUnit.mi)),
    distance: Distance(5, DistUnit.km),
  );

  group('LastGroupStore', () {
    test('reads nothing before anything is written', () async {
      expect(await LastGroupStore(db).read(1, 's1'), isNull);
      expect(await LastGroupStore(db).read(1, null), isNull);
    });

    test('round-trips a spec through JSON', () async {
      final store = LastGroupStore(db);
      await store.write(1, 's1', easy);
      expect(await store.read(1, 's1'), easy);
      final range = LastGroupSpec(
        kind: 'jog_walk',
        pace: PaceRange(Pace(540, DistUnit.km), Pace(600, DistUnit.km)),
      );
      await store.write(1, 's2', range);
      expect(await store.read(1, 's2'), range);
    });

    test('is per series, falling back to the last group overall', () async {
      final store = LastGroupStore(db);
      await store.write(1, 's1', easy);
      const tempo = LastGroupSpec(
        label: 'Tempo',
        pace: SinglePace(Pace(480, DistUnit.mi)),
      );
      await store.write(1, 's2', tempo);
      expect(await store.read(1, 's1'), easy);
      expect(await store.read(1, 's2'), tempo);
      // A series with no history, and ad-hoc runs, get the latest overall.
      expect(await store.read(1, 's3'), tempo);
      expect(await store.read(1, null), tempo);
    });

    test('ad-hoc runs write only the overall entry', () async {
      final store = LastGroupStore(db);
      await store.write(1, null, easy);
      expect(await store.read(1, null), easy);
      expect(await store.read(1, 's1'), easy); // via the overall fallback
    });

    test('keeps clubs apart', () async {
      final store = LastGroupStore(db);
      await store.write(1, 's1', easy);
      expect(await store.read(2, 's1'), isNull);
    });

    test('ignores a corrupt value', () async {
      await db
          .into(db.syncCursors)
          .insert(
            SyncCursorsCompanion.insert(
              key: 'lastGroup:1:any',
              serverTime: 'not json',
            ),
          );
      expect(await LastGroupStore(db).read(1, null), isNull);
    });
  });

  group('editor', () {
    late FakeAdapter adapter;

    Finder valueField(String text) => find.byWidgetPredicate(
      (w) => w is EditableText && w.controller.text == text,
    );

    Future<void> pumpEditor(
      WidgetTester tester, {
      Map<String, Object> routes = const {},
      String? kind,
      GroupIntent intent = GroupIntent.lead,
      bool? lead,
    }) async {
      adapter = await prepareMember(tester, db, routes: routes);
      await tester.runAsync(() async {
        await seedSession(db, 'a');
        await db
            .update(db.sessions)
            .write(const SessionsCompanion(seriesId: Value('s1')));
        await seedUnits(db);
        await LastGroupStore(db).write(1, 's1', easy);
      });
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('detail screen')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) => GroupEditorScreen(
              sessionId: 'a',
              initialKind: kind,
              intent: intent,
              initialLead: lead,
            ),
          ),
        ],
      );
      await pumpGroupsRouter(tester, db, adapter, router);
      unawaited(router.push('/edit'));
      await tester.pump();
      await settle(tester);
    }

    testWidgets('a new group starts from the last one', (tester) async {
      await pumpEditor(tester);
      expect(valueField('Easy'), findsOneWidget);
      expect(valueField('10'), findsOneWidget); // pace minutes
      await unmount(tester);
    });

    testWidgets('leaderless groups and routes are not pre-filled', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        kind: 'route',
        intent: GroupIntent.add,
        lead: false,
      );
      expect(valueField('Easy'), findsNothing);
      await unmount(tester);
    });

    testWidgets('saving a group to lead remembers it', (tester) async {
      await pumpEditor(
        tester,
        routes: {
          'POST /app/clubs/1/sessions/a/groups': FakeResponse(
            201,
            groupJson('new', label: 'Easier', paceFromS: 600, paceToS: null),
          ),
        },
      );
      await tester.enterText(valueField('Easy'), 'Easier');
      await tester.tap(find.text('Save group'));
      await settle(tester);
      expect(
        sent(adapter, 'POST', '/app/clubs/1/sessions/a/groups'),
        hasLength(1),
      );
      final remembered = await tester.runAsync(
        () => LastGroupStore(db).read(1, 's1'),
      );
      expect(remembered!.label, 'Easier');
      await unmount(tester);
    });
  });
}
