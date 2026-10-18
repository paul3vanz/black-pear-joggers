import 'dart:async';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/ui/group_editor_screen.dart';
import 'package:bpj/features/groups/ui/pace_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/gated_adapter.dart';
import 'support/groups_test_support.dart';

const _create = '/app/clubs/1/sessions/a/groups';

void main() {
  late AppDatabase db;
  late GatedAdapter adapter;
  late GoRouter router;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pumpEditor(
    WidgetTester tester, {
    List<String> roles = const [],
    String? groupId,
    String? kind,
    GroupIntent intent = GroupIntent.lead,
    bool? lead,
    String groupMode = 'paced',
    List<Map<String, Object?>> groups = const [],
    Map<String, Object> routes = const {},
  }) async {
    adapter = GatedAdapter(
      (await prepareMember(tester, db, roles: roles, routes: routes)).routes,
    );
    await tester.runAsync(() async {
      await seedSession(db, 'a', groups: groups, groupMode: groupMode);
      await seedUnits(db);
    });
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('detail screen')),
        ),
        GoRoute(
          path: '/runs/a/groups/:gid/edit',
          builder: (_, state) =>
              Scaffold(body: Text('opened ${state.pathParameters['gid']}')),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, _) => GroupEditorScreen(
            sessionId: 'a',
            groupId: groupId,
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

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  /// Types a pace into the minutes and seconds boxes (keys from PaceInput).
  Future<void> typePace(
    WidgetTester tester,
    String prefix,
    String min, [
    String sec = '',
  ]) async {
    await tester.enterText(find.byKey(ValueKey('$prefix-min')), min);
    await tester.enterText(find.byKey(ValueKey('$prefix-sec')), sec);
  }

  Future<void> tapSave(
    WidgetTester tester, [
    String label = 'Save group',
  ]) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  Map<String, Object?> posted() {
    final body = Map<String, Object?>.from(
      sent(adapter, 'POST', _create).single.data as Map,
    );
    expect(body['id'], isA<String>());
    return body..remove('id');
  }

  final created = FakeResponse(201, groupJson('new'));

  testWidgets('creates a single-pace group with a distance in km', (
    tester,
  ) async {
    await pumpEditor(tester, routes: {'POST $_create': created});
    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();
    await typePace(tester, 'pace-fast', '9', '30');
    await tester.enterText(field('Distance (optional)'), '5');
    final distanceUnits = find.byType(SegmentedButton<DistUnit>).last;
    await tester.tap(
      find.descendant(of: distanceUnits, matching: find.text('km')),
    );
    await tester.enterText(field('Label (optional)'), '  Easy 5k ');
    await tapSave(tester);

    expect(posted(), {
      'kind': 'run',
      'label': 'Easy 5k',
      'description': null,
      'paceUnit': 'mi',
      'paceFromS': 570,
      'paceToS': null,
      'distanceValue': 5.0,
      'distanceUnit': 'km',
      'lead': true,
    });
    expect(find.text('detail screen'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('creates a range in km/min', (tester) async {
    await pumpEditor(tester, routes: {'POST $_create': created});
    await tester.tap(find.text('Range'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('min/km'));
    await tester.pumpAndSettle();
    await typePace(tester, 'pace-fast', '5', '30');
    await typePace(tester, 'pace-slow', '6');
    expect(find.text('Faster end'), findsOneWidget);
    expect(find.text('Slower end'), findsOneWidget);
    await tapSave(tester);

    final body = posted();
    expect(body['paceUnit'], 'km');
    expect(body['paceFromS'], 330);
    expect(body['paceToS'], 360);
    expect(body['distanceValue'], isNull);
    await unmount(tester);
  });

  testWidgets('a distance-only group sends no pace', (tester) async {
    await pumpEditor(tester, routes: {'POST $_create': created});
    await tester.enterText(field('Label (required)'), 'Social jog');
    await tester.enterText(field('Distance (optional)'), '10');
    await tester.enterText(
      field('Description (optional)'),
      'Muster at the bridge',
    );
    await tapSave(tester);

    expect(posted(), {
      'kind': 'run',
      'label': 'Social jog',
      'description': 'Muster at the bridge',
      'paceUnit': null,
      'paceFromS': null,
      'paceToS': null,
      'distanceValue': 10.0,
      'distanceUnit': 'mi',
      'lead': true,
    });
    await unmount(tester);
  });

  group('validation blocks saving', () {
    testWidgets('a range with the ends the wrong way round', (tester) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      await typePace(tester, 'pace-fast', '9', '30');
      await typePace(tester, 'pace-slow', '9');
      await tapSave(tester);
      expect(
        find.text('The slower end must not be faster than the faster end'),
        findsOneWidget,
      );
      expect(sent(adapter, 'POST', _create), isEmpty);
      await unmount(tester);
    });

    testWidgets('a pace without minutes, or out of range', (tester) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      await typePace(tester, 'pace-fast', '', '30');
      await tapSave(tester);
      expect(find.text('Enter a pace like 9:30'), findsOneWidget);
      expect(sent(adapter, 'POST', _create), isEmpty);

      await typePace(tester, 'pace-fast', '2');
      await tester.pumpAndSettle();
      expect(find.text('Enter a pace from 3:00 to 30:00'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a distance outside 0.1 to 200', (tester) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      await tester.enterText(field('Distance (optional)'), '250');
      await tapSave(tester);
      expect(find.text('Enter a distance from 0.1 to 200'), findsOneWidget);
      await tester.enterText(field('Distance (optional)'), '0.05');
      await tester.pumpAndSettle();
      expect(find.text('Enter a distance from 0.1 to 200'), findsOneWidget);
      await tester.enterText(field('Distance (optional)'), 'far');
      await tester.pumpAndSettle();
      expect(find.text('Enter a number like 5 or 5.5'), findsOneWidget);
      expect(sent(adapter, 'POST', _create), isEmpty);
      await unmount(tester);
    });
  });

  group('"I will lead this group"', () {
    SwitchListTile lead(WidgetTester tester) =>
        tester.widget<SwitchListTile>(find.byType(SwitchListTile));

    testWidgets('an ordinary member is never asked (D86)', (tester) async {
      // Not for "lead", and not even when opened as "add" with lead=false.
      for (final intent in GroupIntent.values) {
        await pumpEditor(
          tester,
          intent: intent,
          lead: false,
          routes: {'POST $_create': created},
        );
        expect(find.byType(SwitchListTile), findsNothing, reason: '$intent');
        expect(find.text('I will lead this group'), findsNothing);
        await tester.enterText(field('Label (required)'), 'Jog/walk');
        await tapSave(tester);
        expect(posted()['lead'], isTrue, reason: '$intent');
        await unmount(tester);
        await db.clearAll();
      }
    });

    testWidgets('committee with "lead" is not asked either', (tester) async {
      await pumpEditor(
        tester,
        roles: ['committee'],
        routes: {'POST $_create': created},
      );
      expect(find.byType(SwitchListTile), findsNothing);
      await tester.enterText(field('Label (required)'), 'Jog/walk');
      await tapSave(tester);
      expect(posted()['lead'], isTrue);
      await unmount(tester);
    });

    testWidgets('committee "add" can create a leaderless group', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        roles: ['committee'],
        intent: GroupIntent.add,
        routes: {'POST $_create': created},
      );
      expect(lead(tester).value, isTrue, reason: 'on by default');
      expect(lead(tester).onChanged, isNotNull);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.enterText(field('Label (required)'), 'Jog/walk');
      await tapSave(tester);
      expect(posted()['lead'], isFalse);
      await unmount(tester);
    });

    testWidgets('"Add route" opens a route group with lead off', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        roles: ['committee'],
        kind: 'route',
        intent: GroupIntent.add,
        lead: false,
        groupMode: 'routes',
        routes: {'POST $_create': created},
      );
      expect(lead(tester).value, isFalse);
      expect(find.text('Route'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Distance'), findsOneWidget);
      await tester.enterText(field('Distance'), '16');
      await tester.enterText(field('Label (required)'), 'Canal loop');
      await tapSave(tester);
      final body = posted();
      expect(body['kind'], 'route');
      expect(body['lead'], isFalse);
      expect(body['distanceValue'], 16.0);
      expect(body['paceFromS'], isNull);
      await unmount(tester);
    });
  });

  testWidgets('a refused save keeps the form and says why', (tester) async {
    await pumpEditor(
      tester,
      routes: {
        'POST $_create': const FakeResponse(403, {'error': 'forbidden'}),
      },
    );
    await tester.enterText(field('Label (required)'), 'Jog/walk');
    await tapSave(tester);
    expect(find.text("You can't do that."), findsOneWidget);
    expect(find.text('Save group'), findsOneWidget);
    expect(find.text('detail screen'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  group('label rule (no pace needs a label)', () {
    testWidgets('None pace: the label is required and blocks saving', (
      tester,
    ) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      expect(field('Label (required)'), findsOneWidget);
      expect(field('Label (optional)'), findsNothing);
      await tapSave(tester);
      expect(
        find.text('Add a label, e.g. Jog/walk or Efforts'),
        findsOneWidget,
      );
      expect(sent(adapter, 'POST', _create), isEmpty);
      await unmount(tester);
    });

    testWidgets('a pace makes the label optional again', (tester) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      expect(field('Label (optional)'), findsOneWidget);
      await typePace(tester, 'pace-fast', '9', '30');
      await tapSave(tester);
      expect(posted()['label'], isNull);
      expect(posted()['paceFromS'], 570);
      await unmount(tester);
    });

    testWidgets("the server's 422 on label shows on the field", (tester) async {
      await pumpEditor(
        tester,
        routes: {
          'POST $_create': const FakeResponse(422, {
            'error': 'validation_failed',
            'message': 'Give this group a label.',
            'errors': {
              'label': ['A group with no pace needs a label.'],
            },
          }),
        },
      );
      // A pace so the client rule passes, then the server refuses anyway.
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      await typePace(tester, 'pace-fast', '9', '30');
      await tapSave(tester);
      expect(find.text('A group with no pace needs a label.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await unmount(tester);
    });

    testWidgets('the preview heads a no-pace group with its label', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(field('Label (required)'), 'Efforts');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('group-preview-spec')))
            .data,
        'Efforts',
      );
      await unmount(tester);
    });
  });

  group('checkGroupLabel', () {
    test('only None pace with an empty label is an error', () {
      expect(checkGroupLabel(mode: PaceMode.none, label: '  '), isNotNull);
      expect(checkGroupLabel(mode: PaceMode.none, label: 'Jog'), isNull);
      expect(checkGroupLabel(mode: PaceMode.single, label: ''), isNull);
      expect(checkGroupLabel(mode: PaceMode.range, label: ''), isNull);
    });
  });
  testWidgets('previews the group in the viewer units', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('min/km'));
    await tester.pumpAndSettle();
    await typePace(tester, 'pace-fast', '6');
    await tester.enterText(field('Distance (optional)'), '5');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('group-preview-spec')))
          .data,
      '9:39/mi (6:00/km) · 5 mi',
    );
    await unmount(tester);
  });

  group('editing', () {
    final existing = groupJson(
      'g',
      label: 'Steady',
      description: 'Old text',
      leaders: [leaderJson('me')],
      distanceValue: 3,
      distanceUnit: 'mi',
    );

    testWidgets('loads the group and sends nulls for cleared parts', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        groupId: 'g',
        groups: [existing],
        routes: {
          'PATCH /app/clubs/1/groups/g': FakeResponse(200, groupJson('g')),
        },
      );
      expect(find.text('Edit group'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
      String boxes(String prefix) => [
        for (final k in ['min', 'sec'])
          tester
              .widget<TextField>(find.byKey(ValueKey('$prefix-$k')))
              .controller!
              .text,
      ].join('|');
      expect(boxes('pace-fast'), '9|30');
      expect(boxes('pace-slow'), '10|');

      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Distance (optional)'), '');
      await tester.enterText(field('Label (required)'), '');
      await tapSave(tester, 'Save changes');
      // No pace now, so an empty label is refused before anything is sent.
      expect(
        find.text('Add a label, e.g. Jog/walk or Efforts'),
        findsOneWidget,
      );
      expect(sent(adapter, 'PATCH', '/app/clubs/1/groups/g'), isEmpty);
      await tester.enterText(field('Label (required)'), 'Jog/walk');
      await tapSave(tester, 'Save changes');

      final body =
          sent(adapter, 'PATCH', '/app/clubs/1/groups/g').single.data as Map;
      expect(body, {
        'kind': 'run',
        'label': 'Jog/walk',
        'description': 'Old text',
        'paceUnit': null,
        'paceFromS': null,
        'paceToS': null,
        'distanceValue': null,
        'distanceUnit': null,
      });
      expect(find.text('detail screen'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('double submit (one group, one id)', () {
    String sentId(int i) =>
        (sent(adapter, 'POST', _create)[i].data as Map)['id']! as String;

    Finder saveButton() =>
        find.widgetWithText(FilledButton, 'Save group', skipOffstage: false);

    testWidgets('a second tap while saving sends nothing more', (tester) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      final gate = adapter.gates['POST $_create'] = Completer<void>();
      await tester.enterText(field('Label (required)'), 'Jog/walk');
      await tester.ensureVisible(find.text('Save group'));
      await tester.tap(find.text('Save group'));
      await tester.pump();
      // In flight: the button is disabled and shows a spinner, not its label.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save group'), findsNothing);
      final button = find.byType(FilledButton).last;
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();

      gate.complete();
      await settle(tester);
      expect(sent(adapter, 'POST', _create), hasLength(1));
      expect(find.text('detail screen'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a failed save can be retried with the same id', (
      tester,
    ) async {
      var calls = 0;
      await pumpEditor(
        tester,
        routes: {
          'POST $_create': () => ++calls == 1
              ? const FakeResponse(500, {'error': 'server_error'})
              : FakeResponse(201, groupJson('new')),
        },
      );
      await tester.enterText(field('Label (required)'), 'Jog/walk');
      await tapSave(tester);
      expect(sent(adapter, 'POST', _create), hasLength(1));
      // The form stays, enabled again, with the error shown.
      expect(find.text('detail screen'), findsNothing);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tapSave(tester);
      expect(sent(adapter, 'POST', _create), hasLength(2));
      expect(sentId(1), sentId(0), reason: 'a retry replays the same id');
      expect(find.text('detail screen'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a 200 (the server replaying that id) closes as a success', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        routes: {'POST $_create': FakeResponse(200, groupJson('new'))},
      );
      await tester.enterText(field('Label (required)'), 'Jog/walk');
      await tapSave(tester);
      expect(find.text('detail screen'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await unmount(tester);
    });

    testWidgets('each new editor makes its own id', (tester) async {
      await pumpEditor(tester, routes: {'POST $_create': created});
      await tester.enterText(field('Label (required)'), 'One');
      await tapSave(tester);
      final first = sentId(0);
      await unmount(tester);
      await tester.runAsync(db.clearAll);

      await pumpEditor(tester, routes: {'POST $_create': created});
      await tester.enterText(field('Label (required)'), 'Two');
      await tapSave(tester);
      expect(sentId(0), isNot(first));
      await unmount(tester);
    });
  });

  group('one group per leader per run (D108)', () {
    final mine = groupJson(
      'mine',
      label: 'Mine',
      leaders: [leaderJson('me')],
      goingCount: 1,
    );

    testWidgets('a second led group is blocked, with a way to open mine', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        groups: [mine],
        routes: {'POST $_create': created},
      );
      await tester.enterText(field('Label (required)'), 'Another');
      await tapSave(tester);

      expect(sent(adapter, 'POST', _create), isEmpty);
      expect(
        find.text("You're already leading a group on this run"),
        findsOneWidget,
      );
      expect(find.text('detail screen'), findsNothing);
      await tester.tap(find.text('Open it'));
      await tester.pumpAndSettle();
      expect(find.text('opened mine'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await unmount(tester);
    });

    testWidgets('a server 409 already_leading is handled the same way', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        routes: {
          'POST $_create': const FakeResponse(409, {
            'error': 'already_leading',
            'message': 'You already lead a group on this run.',
            'groupId': 'elsewhere',
          }),
        },
      );
      await tester.enterText(field('Label (required)'), 'Another');
      await tapSave(tester);

      expect(sent(adapter, 'POST', _create), hasLength(1));
      expect(
        find.text("You're already leading a group on this run"),
        findsOneWidget,
      );
      // The form stays open and can be used again.
      expect(find.text('Save group'), findsOneWidget);
      await tester.tap(find.text('Open it'));
      await tester.pumpAndSettle();
      expect(find.text('opened elsewhere'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await unmount(tester);
    });

    testWidgets('a committee leaderless add is not blocked', (tester) async {
      await pumpEditor(
        tester,
        roles: ['committee'],
        intent: GroupIntent.add,
        kind: 'route',
        lead: false,
        groups: [mine],
        routes: {'POST $_create': created},
      );
      await tester.enterText(field('Label (required)'), 'Route A');
      await tapSave(tester);
      expect(posted()['lead'], false);
      expect(find.text('detail screen'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('someone leading nothing here can create a group', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        groups: [
          groupJson('other', label: 'Theirs', leaders: [leaderJson('l1')]),
        ],
        routes: {'POST $_create': created},
      );
      await tester.enterText(field('Label (required)'), 'Mine too');
      await tapSave(tester);
      expect(sent(adapter, 'POST', _create), hasLength(1));
      await unmount(tester);
    });
  });
}
