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

/// D127: "Lead a group" starts from the member's own last group (on this device,
/// else from the server), and when opened from an ask it also says what the
/// committee is looking for. The asked stretch never overrides a pace they have.
void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const lastLed = '/app/clubs/1/members/me/last-led';

  /// The server's answer for "the group I last led".
  final serverGroup = FakeResponse(200, {
    'group': {
      'kind': 'run',
      'label': 'Steady nines',
      'description': 'Hills',
      'paceUnit': 'mi',
      'paceFromS': 555,
      'paceToS': null,
      'distanceValue': 6.0,
      'distanceUnit': 'mi',
      'sessionTitle': 'Riverside Run',
      'ledOn': '2026-10-05',
      'sameSeries': true,
    },
  });

  const localSpec = LastGroupSpec(
    label: 'Local tens',
    pace: SinglePace(Pace(630, DistUnit.mi)),
    distance: Distance(5, DistUnit.km),
    sourceTitle: 'Monday club run',
  );

  Future<void> pumpEditor(
    WidgetTester tester,
    String query, {
    Object? lastLedRoute,
    LastGroupSpec? local,
    DistUnit paceUnit = DistUnit.mi,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      routes: {'GET $lastLed': ?lastLedRoute},
    );
    await tester.runAsync(() async {
      await seedSession(db, 'a');
      await db
          .update(db.sessions)
          .write(const SessionsCompanion(seriesId: Value('s1')));
      await seedUnits(db, pace: paceUnit);
      if (local != null) await LastGroupStore(db).write(1, 's1', local);
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('detail screen')),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, state) => GroupEditorScreen.fromUri(
            'a',
            Uri.parse('/runs/a/groups/new?$query'),
          ),
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
    unawaited(router.push('/edit'));
    await tester.pump();
    await settle(tester);
  }

  Finder valueField(String text) => find.byWidgetPredicate(
    (w) => w is EditableText && w.controller.text == text,
  );

  String spec(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('group-preview-spec')))
      .data!;

  String? kind(WidgetTester tester) => tester
      .widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      )
      .initialValue;

  Future<LastGroupSpec?> stored() => LastGroupStore(db).read(1, 's1');

  group('the leader\'s own last group', () {
    testWidgets('this device\'s group wins, and the server is not asked', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        'intent=lead',
        lastLedRoute: serverGroup,
        local: localSpec,
      );

      expect(valueField('Local tens'), findsOneWidget);
      expect(valueField('Steady nines'), findsNothing);
      expect(sent(adapter, 'GET', lastLed), isEmpty);
      expect(
        find.text('Filled in from your last group on Monday club run.'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('with none on the device, the server\'s is used and kept', (
      tester,
    ) async {
      await pumpEditor(tester, 'intent=lead', lastLedRoute: serverGroup);

      expect(valueField('Steady nines'), findsOneWidget);
      expect(valueField('Hills'), findsOneWidget);
      expect(spec(tester), contains('9:15/mi'));
      expect(
        find.text('Filled in from your last group on Riverside Run.'),
        findsOneWidget,
      );
      expect(sent(adapter, 'GET', lastLed).single.queryParameters, {
        'seriesId': 's1',
      });
      // Kept on the device for next time, in the same place a created group goes.
      final kept = await tester.runAsync(stored);
      expect(kept!.label, 'Steady nines');
      expect(kept.pace, const SinglePace(Pace(555, DistUnit.mi)));
      expect(kept.sourceTitle, 'Riverside Run');
      await unmount(tester);
    });

    testWidgets('a server that cannot answer is just no history', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        'intent=lead',
        lastLedRoute: const FakeResponse(500, {'error': 'server_error'}),
      );

      expect(find.text('Lead a group'), findsOneWidget);
      expect(find.text('Save group'), findsOneWidget);
      expect(find.byKey(const ValueKey('lead-hint')), findsNothing);
      expect(await tester.runAsync(stored), isNull);
      await unmount(tester);
    });

    testWidgets('a member who never led starts with an empty form', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        'intent=lead',
        lastLedRoute: const FakeResponse(200, {'group': null}),
      );

      expect(find.byKey(const ValueKey('lead-hint')), findsNothing);
      expect(await tester.runAsync(stored), isNull);
      await unmount(tester);
    });

    testWidgets('"Add a group" and routes never ask the server', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        'intent=add&kind=route&lead=false',
        lastLedRoute: serverGroup,
      );

      expect(sent(adapter, 'GET', lastLed), isEmpty);
      expect(valueField('Steady nines'), findsNothing);
      await unmount(tester);
    });
  });

  group('opened from an ask for a stretch', () {
    const stretch = 'intent=lead&fast=354&slow=382';

    testWidgets('their usual pace wins over the stretch', (tester) async {
      await pumpEditor(tester, stretch, lastLedRoute: serverGroup);

      expect(spec(tester), contains('9:15/mi')); // not the middle of 9:30-10:15
      expect(
        find.text(
          'Filled in from your last group on Riverside Run. The committee is '
          'looking for a group between 9:30 and 10:15/mi, but your usual pace '
          'wins.',
        ),
        findsOneWidget,
      );
      // Nothing to offer: they already have a pace.
      expect(find.byKey(const ValueKey('lead-hint-use')), findsNothing);
      await unmount(tester);
    });

    testWidgets(
      'with no history it says what is wanted and offers the middle',
      (tester) async {
        await pumpEditor(
          tester,
          stretch,
          lastLedRoute: const FakeResponse(200, {'group': null}),
        );

        expect(
          find.text(
            'The committee is looking for a group between 9:30 and 10:15/mi.',
          ),
          findsOneWidget,
        );
        expect(find.text('Use 9:50/mi'), findsOneWidget);
        expect(spec(tester), isNot(contains('9:50')));

        await tester.tap(find.byKey(const ValueKey('lead-hint-use')));
        await tester.pump();

        expect(spec(tester), contains('9:50/mi'));
        expect(find.text('Use 9:50/mi'), findsNothing); // done
        await unmount(tester);
      },
    );

    testWidgets('a km viewer is told, and offered, km', (tester) async {
      await pumpEditor(
        tester,
        stretch,
        lastLedRoute: const FakeResponse(200, {'group': null}),
        paceUnit: DistUnit.km,
      );

      expect(
        find.text(
          'The committee is looking for a group between 5:55 and 6:20/km.',
        ),
        findsOneWidget,
      );
      expect(find.text('Use 6:10/km'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('an open ended stretch says so and offers no pace', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        'intent=lead&fast=150&slow=317',
        lastLedRoute: const FakeResponse(200, {'group': null}),
      );

      expect(
        find.text('The committee is looking for a group faster than 8:30/mi.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lead-hint-use')), findsNothing);
      await unmount(tester);
    });

    testWidgets('a history with no pace gets the stretch and the button', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        stretch,
        local: const LastGroupSpec(label: 'Efforts', sourceTitle: 'Tuesday'),
      );

      expect(
        find.text(
          'Filled in from your last group on Tuesday. The committee is looking '
          'for a group between 9:30 and 10:15/mi.',
        ),
        findsOneWidget,
      );
      expect(find.text('Use 9:50/mi'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('saving what they offered leads a group at their pace', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        stretch,
        lastLedRoute: const FakeResponse(200, {'group': null}),
      );
      adapter.routes['POST /app/clubs/1/sessions/a/groups'] = FakeResponse(
        201,
        groupJson('new', sessionId: 'a', paceFromS: 590, paceToS: null),
      );
      await tester.tap(find.byKey(const ValueKey('lead-hint-use')));
      await tester.pump();
      await tester.tap(find.text('Save group'));
      await settle(tester);

      final post = sent(adapter, 'POST', '/app/clubs/1/sessions/a/groups');
      final data = post.single.data! as Map;
      expect(data['lead'], isTrue);
      expect(data['paceFromS'], 590);
      expect(data['paceUnit'], 'mi');
      await unmount(tester);
    });
  });

  group('opened from an ask for a jog/walk group', () {
    const walk = 'intent=lead&kind=jog_walk';

    testWidgets('preselects the kind and names it, with no history', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        walk,
        lastLedRoute: const FakeResponse(200, {'group': null}),
      );

      expect(kind(tester), 'jog_walk');
      expect(valueField('Jog/walk'), findsOneWidget);
      expect(
        find.text('The committee is looking for a jog/walk group.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lead-hint-use')), findsNothing);
      await unmount(tester);
    });

    testWidgets('keeps the distance but not a run\'s pace and name', (
      tester,
    ) async {
      await pumpEditor(tester, walk, local: localSpec);

      expect(kind(tester), 'jog_walk');
      expect(valueField('Local tens'), findsNothing);
      expect(valueField('Jog/walk'), findsOneWidget);
      expect(spec(tester), isNot(contains('10:30')));
      await unmount(tester);
    });

    testWidgets('a jog/walk group they led before comes back as it was', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        walk,
        local: const LastGroupSpec(kind: 'jog_walk', label: 'Easy walkers'),
      );

      expect(kind(tester), 'jog_walk');
      expect(valueField('Easy walkers'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('the route', () {
    test('an ask\'s kind does not stand in for the form\'s own kind', () {
      final walk = GroupEditorScreen.fromUri(
        'a',
        Uri.parse('/runs/a/groups/new?intent=lead&kind=jog_walk'),
      );
      expect(walk.askedJogWalk, isTrue);
      expect(walk.initialKind, isNull); // so the last group still pre-fills

      final route = GroupEditorScreen.fromUri(
        'a',
        Uri.parse('/runs/a/groups/new?intent=add&kind=route&lead=false'),
      );
      expect(route.askedJogWalk, isFalse);
      expect(route.initialKind, 'route');
    });

    test('reads the asked stretch only when leading', () {
      final lead = GroupEditorScreen.fromUri(
        'a',
        Uri.parse('/runs/a/groups/new?intent=lead&fast=354&slow=382'),
      );
      expect((lead.askedFastSPerKm, lead.askedSlowSPerKm), (354, 382));

      final add = GroupEditorScreen.fromUri(
        'a',
        Uri.parse('/runs/a/groups/new?intent=add&fast=354&slow=382'),
      );
      expect(add.askedFastSPerKm, isNull);

      final junk = GroupEditorScreen.fromUri(
        'a',
        Uri.parse('/runs/a/groups/new?intent=lead&fast=x'),
      );
      expect(junk.askedFastSPerKm, isNull);
    });
  });
}
