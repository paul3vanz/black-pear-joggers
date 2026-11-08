import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/ui/ask_leaders_sheet.dart';
import 'package:bpj/features/groups/ui/groups_providers.dart';
import 'package:bpj/features/messages/data/leader_pool_dtos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

/// The committee's ask sheet (D127): it lists the people who could lead the run,
/// the committee picks by name, and the ask goes to exactly those people.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const pool = '/app/clubs/1/sessions/a/leaders-chat/pool';
  const ask = '/app/clubs/1/sessions/a/leaders-chat/ask';

  const stretch = (
    fastSPerKm: 354,
    slowSPerKm: 382,
    jogWalk: false,
    label: 'a group between 9:30 and 10:15/mi',
  );

  Map<String, Object?> askResponse({
    int notified = 2,
    List<Map<String, Object?>> skipped = const [],
  }) => {
    'message': messageJson(
      'ask-1',
      groupId: 'leaders:a',
      memberId: 'me',
      authorRole: 'committee',
      kind: 'ask',
      askFast: 354,
      askSlow: 382,
      askedNames: ['Anna H.'],
    ),
    'notified': notified,
    'skipped': skipped,
  };

  final people = [
    poolJson('anna', fitsRange: true),
    poolJson(
      'ben',
      name: 'Ben C.',
      ledCount: 1,
      lastLedOn: '2026-10-05',
      lastLed: const {
        'kind': 'run',
        'paceUnit': 'mi',
        'paceFromS': 630,
        'paceToS': null,
      },
    ),
    poolJson(
      'cara',
      name: 'Cara D.',
      ledCount: 2,
      lastLedOn: '2026-10-07',
      lastLed: const {'kind': 'jog_walk'},
      leadingThisRun: true,
    ),
    poolJson('dee', name: 'Dee E.', notGoing: true),
    poolJson('eli', name: 'Eli F.', askedRecently: true),
  ];

  Future<FakeAdapter> pump(
    WidgetTester tester, {
    AskTarget target = stretch,
    Object? poolResponse,
    Object? askRoute,
    DistUnit paceUnit = DistUnit.mi,
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      roles: ['committee'],
      routes: {
        'GET $pool': poolResponse ?? FakeResponse(200, {'items': people}),
        'POST $ask': askRoute ?? FakeResponse(201, askResponse()),
      },
    );
    late Session session;
    await tester.runAsync(() async {
      await seedUnits(db, pace: paceUnit);
      await seedSession(db, 'a');
      session = await db.select(db.sessions).getSingle();
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showAskLeadersSheet(
                    context,
                    ref,
                    session: session,
                    target: target,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/runs/:id/leaders-chat',
          builder: (_, _) => const Scaffold(body: Text('leaders thread page')),
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
    await tester.tap(find.text('Open'));
    await settle(tester);
    return adapter;
  }

  Finder row(String id) => find.byKey(ValueKey('pool-$id'));

  Finder box(String id) =>
      find.descendant(of: row(id), matching: find.byType(Checkbox));

  bool ticked(WidgetTester tester, String id) =>
      tester.widget<Checkbox>(box(id)).value ?? false;

  Future<void> pick(WidgetTester tester, String id) async {
    await tester.tap(row(id));
    await tester.pump();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('ask-send')));
    await tester.tap(find.byKey(const ValueKey('ask-send')));
    await settle(tester);
  }

  testWidgets('titled for the stretch and laid out in sections', (
    tester,
  ) async {
    final adapter = await pump(tester);

    expect(
      find.text('Ask for a group between 9:30 and 10:15/mi'),
      findsOneWidget,
    );
    expect(find.text('Usually lead around here'), findsOneWidget);
    expect(find.text('Other previous leaders'), findsOneWidget);
    expect(find.text("Can't be asked"), findsOneWidget);
    // The pool was asked for this stretch.
    expect(sent(adapter, 'GET', pool).single.queryParameters, {
      'fastSPerKm': 354,
      'slowSPerKm': 382,
    });
    // The fitting person is in the first section, above the others.
    expect(
      tester.getTopLeft(row('anna')).dy,
      lessThan(tester.getTopLeft(row('ben')).dy),
    );
    expect(
      tester.getTopLeft(row('ben')).dy,
      lessThan(tester.getTopLeft(row('cara')).dy),
    );
    await unmount(tester);
  });

  testWidgets('rows say how often, when and at what pace', (tester) async {
    await pump(tester);

    Finder inRow(String id, String text) =>
        find.descendant(of: row(id), matching: find.text(text));
    expect(
      inRow('anna', 'Led 3 times · last 14 Oct at 9:15/mi'),
      findsOneWidget,
    );
    expect(inRow('ben', 'Led once · last 5 Oct at 10:30/mi'), findsOneWidget);
    expect(inRow('cara', 'Led twice · last 7 Oct, jog/walk'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('nothing is ticked, and people who cannot be asked stay out', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Send to 0 people'), findsOneWidget);
    for (final id in ['anna', 'ben', 'cara', 'dee', 'eli']) {
      expect(ticked(tester, id), isFalse, reason: id);
    }
    // Why each one cannot be asked.
    expect(find.text('Already leading'), findsOneWidget);
    expect(find.text("Can't make it"), findsOneWidget);
    expect(find.text('Asked recently'), findsOneWidget);
    await pick(tester, 'cara');
    await pick(tester, 'dee');
    await pick(tester, 'eli');
    expect(find.text('Send to 0 people'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sends the stretch and exactly the people picked', (
    tester,
  ) async {
    final adapter = await pump(tester);

    await pick(tester, 'anna');
    await pick(tester, 'ben');
    expect(find.text('Send to 2 people'), findsOneWidget);
    await pick(tester, 'ben'); // un-tick
    expect(find.text('Send to 1 person'), findsOneWidget);
    await pick(tester, 'ben');
    await tester.enterText(
      find.byKey(const ValueKey('ask-note')),
      'Back to the usual?',
    );
    await send(tester);

    final data = sent(adapter, 'POST', ask).single.data! as Map;
    expect(data['memberIds'], unorderedEquals(['anna', 'ben']));
    expect(data['fastSPerKm'], 354);
    expect(data['slowSPerKm'], 382);
    expect(data['note'], 'Back to the usual?');
    expect(data.containsKey('kind'), isFalse);
    // Told how many, and the thread opens.
    expect(find.text('leaders thread page'), findsOneWidget);
    expect(find.text('Asked 2 leaders'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('says who was left out', (tester) async {
    await pump(
      tester,
      askRoute: FakeResponse(
        201,
        askResponse(
          notified: 1,
          skipped: [
            {'memberId': 'ben', 'reason': 'asked_recently'},
            {'memberId': 'eli', 'reason': 'leading'},
          ],
        ),
      ),
    );
    await pick(tester, 'anna');
    await send(tester);

    expect(
      find.text('Asked 1 leader (1 already asked, 1 already leading)'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('says so when nobody could be asked', (tester) async {
    await pump(
      tester,
      askRoute: FakeResponse(
        201,
        askResponse(
          notified: 0,
          skipped: [
            {'memberId': 'anna', 'reason': 'leading'},
          ],
        ),
      ),
    );
    await pick(tester, 'anna');
    await send(tester);

    expect(
      find.text(
        'Nobody could be asked for that. It is in the leaders thread for the '
        'committee.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('sending with nobody picked asks to pick someone', (
    tester,
  ) async {
    final adapter = await pump(tester);

    await send(tester);

    expect(find.text('Pick at least one person'), findsOneWidget);
    expect(sent(adapter, 'POST', ask), isEmpty);
    await pick(tester, 'anna');
    await send(tester);
    expect(find.text('Pick at least one person'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('a failed ask says why and keeps the sheet open', (tester) async {
    await pump(
      tester,
      askRoute: const FakeResponse(403, {
        'error': 'forbidden',
        'message': 'Only the committee can ask for leaders.',
      }),
    );
    await pick(tester, 'anna');
    await send(tester);

    expect(
      find.text('Only the committee can ask for leaders.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ask-send')), findsOneWidget);
    expect(find.text('leaders thread page'), findsNothing);
    await unmount(tester);
  });

  testWidgets('with nobody in the pool, says so', (tester) async {
    await pump(
      tester,
      poolResponse: const FakeResponse(200, {'items': <Object?>[]}),
    );

    expect(
      find.text(
        'Nobody has led this series or day before, or chosen it in their '
        'settings.',
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('a pool that cannot load offers to try again', (tester) async {
    var calls = 0;
    FakeResponse next() {
      calls++;
      return calls == 1
          ? const FakeResponse(500, {'error': 'server_error'})
          : FakeResponse(200, {'items': people});
    }

    await pump(tester, poolResponse: next);

    expect(find.byKey(const ValueKey('ask-load-error')), findsOneWidget);
    expect(row('anna'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('ask-retry')));
    await settle(tester);
    expect(find.byKey(const ValueKey('ask-load-error')), findsNothing);
    expect(row('anna'), findsOneWidget);
    expect(calls, 2);
    await unmount(tester);
  });

  testWidgets('offline says it needs a connection', (tester) async {
    final adapter = await prepareMember(tester, db, roles: ['committee']);
    late Session session;
    await tester.runAsync(() async {
      await seedUnits(db);
      await seedSession(db, 'a');
      session = await db.select(db.sessions).getSingle();
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showAskLeadersSheet(
                  context,
                  ref,
                  session: session,
                  target: stretch,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
    await tester.tap(find.text('Open'));
    await settle(tester);

    expect(
      find.text('You need a connection to see who could lead.'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('a jog/walk ask is titled for it and sends the kind, no pace', (
    tester,
  ) async {
    final adapter = await pump(
      tester,
      target: (
        fastSPerKm: null,
        slowSPerKm: null,
        jogWalk: true,
        label: 'a jog/walk group',
      ),
    );

    expect(find.text('Ask for a jog/walk group'), findsOneWidget);
    expect(sent(adapter, 'GET', pool).single.queryParameters, {
      'kind': 'jog_walk',
    });
    await pick(tester, 'anna');
    await send(tester);
    final data = sent(adapter, 'POST', ask).single.data! as Map;
    expect(data['kind'], 'jog_walk');
    expect(data['memberIds'], ['anna']);
    expect(data.containsKey('fastSPerKm'), isFalse);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('an ask for the whole run has no stretch', (tester) async {
    final adapter = await pump(
      tester,
      target: (fastSPerKm: null, slowSPerKm: null, jogWalk: false, label: ''),
      // Asked about no stretch, the server marks nobody as fitting.
      poolResponse: FakeResponse(200, {
        'items': [poolJson('anna'), poolJson('ben', name: 'Ben C.')],
      }),
    );

    expect(find.text('Ask for leaders'), findsOneWidget);
    expect(sent(adapter, 'GET', pool).single.queryParameters, isEmpty);
    // Nobody fits a stretch that was not asked about, so there is no top section.
    expect(find.text('Previous leaders'), findsOneWidget);
    await pick(tester, 'anna');
    await send(tester);
    final data = sent(adapter, 'POST', ask).single.data! as Map;
    expect(data.containsKey('fastSPerKm'), isFalse);
    expect(data.containsKey('kind'), isFalse);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  group('poolSubtitle', () {
    const mi = UnitPrefs();
    const km = UnitPrefs(paceUnit: DistUnit.km);
    PoolMember member(Map<String, Object?> json) => PoolMember.fromJson(json);

    test('a leader who has led, in the viewer\'s unit', () {
      expect(
        poolSubtitle(member(poolJson('a')), mi),
        'Led 3 times · last 14 Oct at 9:15/mi',
      );
      expect(
        poolSubtitle(member(poolJson('a')), km),
        'Led 3 times · last 14 Oct at 5:45/km (9:15/mi)',
      );
    });

    test('a range shows both ends', () {
      final m = member(
        poolJson(
          'a',
          lastLed: const {
            'kind': 'run',
            'paceUnit': 'mi',
            'paceFromS': 540,
            'paceToS': 555,
          },
        ),
      );
      expect(poolSubtitle(m, mi), 'Led 3 times · last 14 Oct at 9:00-9:15/mi');
    });

    test('someone who only signed up before, chose the day, or is new', () {
      expect(
        poolSubtitle(member(poolJson('a', ledCount: 0, lastLedOn: null)), mi),
        'Signed up to lead before at 9:15/mi',
      );
      expect(
        poolSubtitle(
          member(
            poolJson(
              'a',
              reason: 'chose_day',
              ledCount: 0,
              lastLedOn: null,
              lastLed: null,
            ),
          ),
          mi,
        ),
        'Chose this day in their settings',
      );
      expect(
        poolSubtitle(
          member(
            poolJson(
              'a',
              reason: 'new_leader',
              ledCount: 0,
              lastLedOn: null,
              lastLed: null,
            ),
          ),
          mi,
        ),
        "Leader, hasn't led yet",
      );
    });
  });
}
