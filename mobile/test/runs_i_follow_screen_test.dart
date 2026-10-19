import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/runs/data/follows_repository.dart';
import 'package:bpj/features/runs/ui/runs_i_follow_screen.dart';
import 'package:flutter/material.dart';

import 'dart:ui' show Tristate;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_follows.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late FakeFollowsServer server;

  setUp(() {
    db = memoryDb();
    server = FakeFollowsServer([
      followJson('mon', title: 'Monday Club Run', usuallyComes: true),
      followJson('mug', title: 'The Mug Run', weekday: 4, start: '18:30'),
      followJson(
        'perd',
        title: 'Thursday Perdiswell',
        weekday: 4,
        usuallyComes: true,
      ),
    ]);
    adapter = FakeAdapter(server.routes(() => adapter.requests.last.data));
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          followsRepositoryProvider.overrideWithValue(
            FollowsRepository(db, fakeDio(adapter)),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
        ],
        child: const MaterialApp(home: RunsIFollowScreen()),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Finder row(String id) => find.byKey(ValueKey('follow-$id'));
  Finder segment(String id, String mode) => find.descendant(
    of: row(id),
    matching: find.byKey(ValueKey('mode-$mode')),
  );
  String statusLine(WidgetTester tester, String id) =>
      tester.widget<Text>(find.byKey(ValueKey('status-line-$id'))).data!;

  testWidgets('series grouped by day with a status line each', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Runs I follow'), findsOneWidget);
    expect(find.textContaining('decide what shows in My runs'), findsOneWidget);
    expect(find.text('MONDAY'), findsOneWidget);
    expect(find.text('THURSDAY'), findsOneWidget);
    expect(find.text('Follow all'), findsNWidgets(2));
    expect(find.text('7pm · Monday Club Run'), findsOneWidget);
    expect(find.text('6:30pm · The Mug Run'), findsOneWidget);
    // Both Auto cases.
    expect(statusLine(tester, 'mon'), 'Auto: following (you usually come)');
    expect(statusLine(tester, 'mug'), 'Auto: not following (you rarely come)');
    expect(find.text('Follow everything'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a tap saves at once and the status line follows it', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(segment('perd', 'hide'));
    await tester.pump();
    expect(statusLine(tester, 'perd'), 'Hidden · only shown in All runs');
    await settle(tester);
    expect(sent(adapter, 'PUT', '/app/clubs/1/follows/perd').single.data, {
      'mode': 'hide',
    });

    await tester.tap(segment('mug', 'follow'));
    await settle(tester);
    expect(statusLine(tester, 'mug'), 'Following');
    // No Save step anywhere.
    expect(find.text('Save'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a failed write puts the control back and says so', (
    tester,
  ) async {
    await pumpScreen(tester);
    server.fail = true;

    await tester.tap(segment('mug', 'follow'));
    await settle(tester);

    expect(find.textContaining("didn't save"), findsOneWidget);
    expect(statusLine(tester, 'mug'), 'Auto: not following (you rarely come)');
    await unmount(tester);
  });

  testWidgets('Follow all sets only that day', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('followAll-Thursday')));
    await settle(tester);

    expect(sent(adapter, 'PUT', '/app/clubs/1/follows').single.data, {
      'seriesIds': ['mug', 'perd'],
      'mode': 'follow',
    });
    expect(statusLine(tester, 'mug'), 'Following');
    expect(statusLine(tester, 'perd'), 'Following');
    expect(statusLine(tester, 'mon'), 'Auto: following (you usually come)');
    expect(find.text('Following every Thursday run'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Follow everything, then Undo restores every mode exactly', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(segment('perd', 'hide'));
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('followEverything')));
    await settle(tester);
    expect(find.text('Following every run'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing); // no confirmation
    for (final id in ['mon', 'mug', 'perd']) {
      expect(statusLine(tester, id), 'Following');
    }

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(sent(adapter, 'PUT', '/app/clubs/1/follows').last.data, {
      'modes': {'mon': 'auto', 'mug': 'auto', 'perd': 'hide'},
    });
    expect(statusLine(tester, 'mon'), 'Auto: following (you usually come)');
    expect(statusLine(tester, 'mug'), 'Auto: not following (you rarely come)');
    expect(statusLine(tester, 'perd'), 'Hidden · only shown in All runs');
    await unmount(tester);
  });

  testWidgets('a later change dismisses the Undo snackbar', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('followEverything')));
    await settle(tester);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(segment('mug', 'hide'));
    await settle(tester);
    expect(find.text('Undo'), findsNothing);
    await unmount(tester);
  });

  testWidgets('controls are 44dp or more and announce the selected option', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);

    for (final finder in [
      segment('mon', 'follow'),
      find.byKey(const ValueKey('followAll-Monday')),
      find.byKey(const ValueKey('followEverything')),
    ]) {
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
    }
    expect(
      tester.getSize(find.byKey(const ValueKey('followAll-Monday'))).height,
      greaterThanOrEqualTo(44),
    );
    // The selected segment has a check icon.
    expect(
      find.descendant(of: row('mon'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Auto, Monday Club Run')),
      matchesSemantics(
        label: 'Auto, Monday Club Run',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    final follow = tester
        .getSemantics(find.bySemanticsLabel('Follow, Monday Club Run'))
        .getSemanticsData();
    expect(follow.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
    await unmount(tester);
  });
}
