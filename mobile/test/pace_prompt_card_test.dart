import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/small_kv_store.dart';
import 'package:bpj/features/runs/ui/pace_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

/// The "Set your usual pace" nudge at the top of the Runs tab.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final prompt = find.byKey(const ValueKey('pacePrompt'));

  Future<void> pumpCard(
    WidgetTester tester, {
    int? usualFromS,
    DateTime? snoozedUntil,
  }) async {
    final adapter = await prepareMember(tester, db, roles: []);
    await tester.runAsync(() async {
      await seedUnits(db, usualFromS: usualFromS);
      if (snoozedUntil != null) {
        await SmallKvStore(db).set(
          SmallKvStore.pacePromptSnoozeKey(1),
          snoozedUntil.toIso8601String(),
        );
      }
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: PacePromptCard()),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Profile page')),
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
  }

  testWidgets('shows for a member with no usual pace', (tester) async {
    await pumpCard(tester);
    expect(prompt, findsOneWidget);
    expect(find.text('Set your usual pace'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('hidden once a usual pace is saved', (tester) async {
    await pumpCard(tester, usualFromS: 540);
    expect(prompt, findsNothing);
    await unmount(tester);
  });

  testWidgets('Set pace opens the profile', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byKey(const ValueKey('pacePromptSet')));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Not now hides it and saves a week-long snooze', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byKey(const ValueKey('pacePromptLater')));
    await tester.pump();
    expect(prompt, findsNothing);
    final saved = await tester.runAsync(
      () => SmallKvStore(db).get(SmallKvStore.pacePromptSnoozeKey(1)),
    );
    final until = DateTime.parse(saved!);
    expect(
      until.difference(DateTime.now()).inDays,
      pacePromptSnooze.inDays - 1, // a few ms in, so 6 whole days remain
    );
    await unmount(tester);
  });

  testWidgets('stays hidden while snoozed', (tester) async {
    await pumpCard(
      tester,
      snoozedUntil: DateTime.now().add(const Duration(days: 3)),
    );
    expect(prompt, findsNothing);
    await unmount(tester);
  });

  testWidgets('comes back once the snooze has passed', (tester) async {
    await pumpCard(
      tester,
      snoozedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(prompt, findsOneWidget);
    await unmount(tester);
  });
}
