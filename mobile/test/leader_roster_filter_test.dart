import 'dart:async';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/groups/data/small_kv_store.dart';
import 'package:bpj/features/groups/logic/roster.dart';
import 'package:bpj/features/groups/ui/leader_roster_screen.dart';
import 'package:bpj/features/runs/logic/my_days.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/gated_adapter.dart';
import 'support/groups_test_support.dart';

const _put = '/app/clubs/1/sessions/mon/attendance';
const _prefs = '/app/clubs/1/preferences';

/// `GET`/`PUT /preferences` body with just the fields these tests care about.
Map<String, Object?> _prefsBody(List<int>? leadDays, [List<int>? runDays]) => {
  'paceUnit': 'mi',
  'distanceUnit': 'mi',
  'leadDays': leadDays,
  'runDays': runDays,
};

void main() {
  late AppDatabase db;
  late GatedAdapter adapter;
  late List<Uri> opened;

  setUp(() {
    db = memoryDb();
    opened = [];
  });
  tearDown(() => db.close());

  // "Now" is Wed 7 Oct 2026. mon = Mon 12, tue1 = Tue 13, wed = Wed 14,
  // tue2 = Tue 20; lead = Wed 21 and the viewer leads a group on it.
  //
  // [serverDays] / [serverRunDays] are what `GET /preferences` returns (null =
  // never chosen); [putPrefs] false leaves `PUT /preferences` unrouted, i.e.
  // offline. A PUT of leadDays adds them to the run days, like the server.
  Future<void> pumpRoster(
    WidgetTester tester, {
    List<String> days = const ['mon', 'tue1', 'wed', 'tue2', 'lead'],
    String? storedDays,
    List<int>? serverDays,
    List<int>? serverRunDays,
    bool putPrefs = true,
  }) async {
    var runDays = serverRunDays;
    final base = await prepareMember(
      tester,
      db,
      routes: {
        'PUT $_put': FakeResponse(
          200,
          attendanceJson('mon', status: 'not_going'),
        ),
        'GET $_prefs': FakeResponse(200, _prefsBody(serverDays, runDays)),
        if (putPrefs)
          // Echo the body back, as the server returns the saved copy.
          'PUT $_prefs': () {
            final lead =
                ((adapter.requests.last.data as Map)['leadDays'] as List?)
                    ?.cast<int>();
            if (runDays != null && lead != null) {
              runDays = ({...runDays!, ...lead}.toList()..sort());
            }
            return FakeResponse(200, _prefsBody(lead, runDays));
          },
      },
    );
    adapter = GatedAdapter(base.routes);
    const dates = {
      'mon': '2026-10-12',
      'tue1': '2026-10-13',
      'wed': '2026-10-14',
      'tue2': '2026-10-20',
      'lead': '2026-10-21',
    };
    await tester.runAsync(() async {
      await seedUnits(db);
      for (final id in days) {
        final leading = id == 'lead';
        await seedSession(
          db,
          id,
          localDate: dates[id]!,
          groups: leading
              ? [
                  groupJson(
                    'g-$id',
                    sessionId: id,
                    leaders: [leaderJson('me', name: 'Jo Bloggs')],
                  ),
                ]
              : const [],
          summary: summaryJson(groupCount: leading ? 1 : 0, myLeading: leading),
        );
      }
      if (storedDays != null) {
        await SmallKvStore(db).set(SmallKvStore.leadDaysKey(1), storedDays);
      }
    });
    final router = GoRouter(
      initialLocation: '/runs/lead',
      routes: [
        GoRoute(
          path: '/runs/lead',
          builder: (_, _) => const LeaderRosterScreen(),
        ),
        GoRoute(
          path: '/runs/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
        ),
      ],
    );
    tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, fakeDio(adapter)),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  Finder card(String id) => find.byKey(ValueKey(id));
  Finder chip(String day) => find.widgetWithText(FilterChip, day);
  Finder save() => find.byKey(const ValueKey('leadDaysSave'));
  Finder change() => find.byKey(const ValueKey('leadDaysChange'));

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  group('days I may lead', () {
    testWidgets('first time: prompt, only weekdays that occur, all runs', (
      tester,
    ) async {
      await pumpRoster(tester);
      expect(find.text('Which days could you lead?'), findsOneWidget);
      expect(chip('Mon'), findsOneWidget);
      expect(chip('Tue'), findsOneWidget);
      expect(chip('Wed'), findsOneWidget);
      expect(chip('Thu'), findsNothing);
      expect(chip('Sun'), findsNothing);
      // Save is always enabled, even with nothing chosen.
      expect(tester.widget<FilledButton>(save()).onPressed, isNotNull);
      expect(find.text('Cancel'), findsNothing);
      expect(find.byType(Card), findsNWidgets(5)); // nothing filtered yet
      await finish(tester);
    });

    testWidgets('a single weekday still gets the prompt', (tester) async {
      await pumpRoster(tester, days: ['tue1', 'tue2']);
      expect(find.text('Which days could you lead?'), findsOneWidget);
      expect(chip('Tue'), findsOneWidget);
      expect(card('tue1'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Save sends only leadDays, then one line and a filtered list', (
      tester,
    ) async {
      await pumpRoster(tester);
      await tester.tap(chip('Tue'));
      await tester.tap(chip('Mon'));
      await tester.pump();
      await tester.tap(save());
      await settle(tester);

      expect(sent(adapter, 'PUT', _prefs).single.data, {
        'leadDays': [1, 2],
      });
      expect(find.text('Lead days: Mon, Tue'), findsOneWidget);
      expect(find.text('Which days could you lead?'), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(card('mon'), findsOneWidget);
      expect(card('tue1'), findsOneWidget);
      expect(card('tue2'), findsOneWidget);
      expect(card('wed'), findsNothing);
      // I lead 'lead' (a Wednesday): still shown despite the choice.
      expect(card('lead'), findsOneWidget);
      expect(find.text('Show 1 more'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('saving none is allowed and leaves only the runs I lead', (
      tester,
    ) async {
      await pumpRoster(tester);
      await tester.tap(save());
      await settle(tester);

      expect(sent(adapter, 'PUT', _prefs).single.data, {'leadDays': <int>[]});
      expect(find.text('Not leading on any day'), findsOneWidget);
      expect(card('lead'), findsOneWidget);
      expect(card('mon'), findsNothing);
      expect(card('tue1'), findsNothing);
      expect(find.text('Show 4 more'), findsOneWidget);
      await finish(tester);
    });

    testWidgets(
      'a saved choice shows the line; Change reopens, Cancel closes',
      (tester) async {
        await pumpRoster(tester, serverDays: [2, 3]);
        expect(find.text('Lead days: Tue, Wed'), findsOneWidget);
        expect(find.byType(FilterChip), findsNothing);
        expect(card('mon'), findsNothing);
        expect(card('wed'), findsOneWidget);

        await tester.tap(change());
        await settle(tester);
        expect(tester.widget<FilterChip>(chip('Tue')).selected, isTrue);
        expect(tester.widget<FilterChip>(chip('Mon')).selected, isFalse);
        // The roster is unchanged until Save.
        await tester.tap(chip('Mon'));
        await tester.pump();
        expect(card('mon'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('leadDaysCancel')));
        await settle(tester);
        expect(find.text('Lead days: Tue, Wed'), findsOneWidget);
        expect(sent(adapter, 'PUT', _prefs), isEmpty);
        await finish(tester);
      },
    );

    testWidgets('Change then Save sends the new list', (tester) async {
      await pumpRoster(tester, serverDays: [2]);
      await tester.tap(change());
      await settle(tester);
      await tester.tap(chip('Mon'));
      await tester.pump();
      await tester.tap(save());
      await settle(tester);
      expect(sent(adapter, 'PUT', _prefs).single.data, {
        'leadDays': [1, 2],
      });
      expect(find.text('Lead days: Mon, Tue'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Show N more lists every day until Just my days', (
      tester,
    ) async {
      await pumpRoster(tester, serverDays: [2]);
      expect(card('mon'), findsNothing);
      expect(card('wed'), findsNothing);
      await tester.tap(find.text('Show 2 more'));
      await settle(tester);
      expect(card('mon'), findsOneWidget);
      expect(card('wed'), findsOneWidget);
      expect(find.text('Lead days: Tue'), findsOneWidget); // still compact
      expect(sent(adapter, 'PUT', _prefs), isEmpty); // a view, not a save

      await tester.tap(find.text('Just my days'));
      await settle(tester);
      expect(card('mon'), findsNothing);
      expect(find.text('Show 2 more'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('old run days no longer narrow it or tick chips (D117)', (
      tester,
    ) async {
      await pumpRoster(tester, serverRunDays: [1, 3]);
      expect(find.text('Which days could you lead?'), findsOneWidget);
      expect(tester.widget<FilterChip>(chip('Mon')).selected, isFalse);
      expect(card('mon'), findsOneWidget);
      expect(card('tue1'), findsOneWidget);
      expect(find.textContaining('more'), findsNothing);
      await finish(tester);
    });

    testWidgets('saving lead days says nothing about run days', (tester) async {
      await pumpRoster(tester, serverDays: [1], serverRunDays: [1, 3]);
      await tester.tap(change());
      await settle(tester);
      await tester.tap(chip('Tue'));
      await tester.pump();
      expect(find.textContaining('run days'), findsNothing);
      await tester.tap(save());
      await settle(tester);
      expect(find.text('Lead days: Mon, Tue'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a chosen day with no runs still shows as a chip', (
      tester,
    ) async {
      await pumpRoster(tester, serverDays: [5]); // Friday: none
      expect(card('lead'), findsOneWidget);
      expect(card('mon'), findsNothing);
      await tester.tap(change());
      await settle(tester);
      expect(tester.widget<FilterChip>(chip('Fri')).selected, isTrue);
      await finish(tester);
    });

    testWidgets('the old local filter pre-selects but is not saved', (
      tester,
    ) async {
      await pumpRoster(tester, storedDays: '3'); // Wednesday
      expect(find.text('Which days could you lead?'), findsOneWidget);
      expect(tester.widget<FilterChip>(chip('Wed')).selected, isTrue);
      expect(tester.widget<FilterChip>(chip('Mon')).selected, isFalse);
      expect(sent(adapter, 'PUT', _prefs), isEmpty);
      expect(find.byType(Card), findsNWidgets(5)); // not filtered until Save

      await tester.tap(save());
      await settle(tester);
      expect(sent(adapter, 'PUT', _prefs).single.data, {
        'leadDays': [3],
      });
      // The server owns the choice now: the local key is gone.
      final kv = await tester.runAsync(
        () => SmallKvStore(db).get(SmallKvStore.leadDaysKey(1)),
      );
      expect(kv, isNull);
      await finish(tester);
    });

    testWidgets('offline Save shows a message and can be retried', (
      tester,
    ) async {
      await pumpRoster(tester, putPrefs: false);
      await tester.tap(chip('Tue'));
      await tester.pump();
      await tester.tap(save());
      await settle(tester);
      expect(
        find.text('You need a connection to save your days.'),
        findsOneWidget,
      );
      expect(find.text('Which days could you lead?'), findsOneWidget);
      expect(tester.widget<FilledButton>(save()).onPressed, isNotNull);
      expect(tester.widget<FilterChip>(chip('Tue')).selected, isTrue);
      await finish(tester);
    });

    testWidgets('Save is disabled with a spinner while the request runs', (
      tester,
    ) async {
      await pumpRoster(tester);
      final gate = adapter.gates['PUT $_prefs'] = Completer<void>();
      await tester.tap(chip('Tue'));
      await tester.pump();
      await tester.tap(save());
      await tester.pump();
      expect(tester.widget<FilledButton>(save()).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(sent(adapter, 'PUT', _prefs), hasLength(1));
      expect(find.text('Lead days: Tue'), findsOneWidget);
      await finish(tester);
    });
  });

  group("Can't attend", () {
    testWidgets('collapses the card to one line, in place, with no Undo', (
      tester,
    ) async {
      await pumpRoster(tester);
      final before = tester.getTopLeft(card('tue1')).dy;
      // Not offered on the run I lead.
      expect(
        find.descendant(of: card('lead'), matching: find.text("Can't attend")),
        findsNothing,
      );
      final fullHeight = tester.getSize(card('mon')).height;

      await tester.tap(
        find.descendant(of: card('mon'), matching: find.text("Can't attend")),
      );
      await settle(tester);

      expect(sent(adapter, 'PUT', _put).single.data, {'status': 'not_going'});
      // The one-line view: day and time, the label and "Change" (the API has
      // no way to clear an answer, so there is no Undo).
      expect(
        find.descendant(
          of: card('mon'),
          matching: find.text('Mon 12 Oct, 7pm'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card('mon'), matching: find.text("Can't attend")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card('mon'), matching: find.text('Offer to lead')),
        findsNothing,
      );
      expect(find.text('Undo'), findsNothing);
      expect(tester.getSize(card('mon')).height, lessThan(fullHeight / 2));
      // Still in date order: the next card follows directly.
      expect(tester.getTopLeft(card('tue1')).dy, lessThan(before));
      expect(
        tester.getTopLeft(card('mon')).dy,
        lessThan(tester.getTopLeft(card('tue1')).dy),
      );
      await finish(tester);
    });

    testWidgets('Change opens the run to answer again', (tester) async {
      await pumpRoster(tester);
      await tester.tap(
        find.descendant(of: card('mon'), matching: find.text("Can't attend")),
      );
      await settle(tester);
      await tester.tap(find.text('Change'));
      await settle(tester);
      expect(find.text('detail mon'), findsOneWidget);
      await finish(tester);
    });
  });

  testWidgets('has a tips link that opens the website page', (tester) async {
    await pumpRoster(tester);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    await tester.tap(find.text('Tips on leading a group'));
    await settle(tester);
    expect(opened, [Uri.parse('https://bpj.org.uk/leading-a-group')]);
    await finish(tester);
  });

  group('day helpers (D117)', () {
    test('Lead a run shows the lead days, else every day', () {
      expect(leadRosterDays(), isNull);
      expect(leadRosterDays(leadDays: [1, 3]), {1, 3});
      expect(leadRosterDays(leadDays: []), isEmpty);
    });
  });

  group('roster helpers', () {
    test('decode and format weekday lists', () {
      expect(decodeWeekdays('1,3'), {1, 3});
      expect(decodeWeekdays(null), isEmpty);
      expect(decodeWeekdays('0,8,x,7'), {7});
      expect(formatWeekdays([4, 2]), 'Tue, Thu');
      expect(formatWeekdays(const <int>[]), '');
    });

    test('null days show everything, empty days only the runs I lead', () {
      final weeks = [
        RosterWeek(
          monday: '2026-10-12',
          label: 'Next week',
          sessions: const [],
        ),
      ];
      expect(filterRosterByDays(weeks, null, (_) => false).hidden, 0);
      expect(
        filterRosterByDays(const [], <int>{}, (_) => false).weeks,
        isEmpty,
      );
    });
  });
}
