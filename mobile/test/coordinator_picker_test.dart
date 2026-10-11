import 'dart:async';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/ui/session_edit_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _members = '/app/clubs/1/members';
const _patch = '/app/clubs/1/sessions/a';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pumpEdit(
    WidgetTester tester, {
    String? coordinator,
    String? coordinatorName,
    List<String> roles = const ['committee'],
    Map<String, Object> routes = const {},
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      routes: {
        'GET $_members': FakeResponse(
          200,
          membersListJson([
            memberItemJson('m1', 'Sam Lead', roles: ['leader']),
            memberItemJson('m2', 'Pat Lapsed', status: 'lapsed'),
          ]),
        ),
        'PATCH $_patch': FakeResponse(
          200,
          sessionWithGroups('a', localDate: '2026-10-12'),
        ),
        ...routes,
      },
    );
    await tester.runAsync(() async {
      await seedSession(db, 'a', groupMode: 'routes');
      await db
          .update(db.sessions)
          .write(
            SessionsCompanion(
              coordinatorMemberId: Value(coordinator),
              coordinatorName: Value(coordinatorName),
            ),
          );
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('detail screen')),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, _) => const SessionEditScreen(sessionId: 'a'),
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
    unawaited(router.push('/edit'));
    await tester.pump();
    await settle(tester);
  }

  Future<void> debounced(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }

  Map<String, Object?> patched() => Map<String, Object?>.from(
    sent(adapter, 'PATCH', _patch).single.data as Map,
  );

  testWidgets('shows the current coordinator', (tester) async {
    await pumpEdit(tester, coordinator: 'm1', coordinatorName: 'Sam Lead');
    expect(find.text('Sam Lead'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('picking a member sends coordinatorMemberId', (tester) async {
    await pumpEdit(tester);
    expect(find.text('No coordinator'), findsOneWidget);
    await tester.tap(find.text('Choose'));
    await settle(tester);

    expect(find.text('Sam Lead'), findsOneWidget);
    expect(find.text('Pat Lapsed'), findsOneWidget);
    expect(find.text('Lapsed'), findsOneWidget);
    expect(find.text('Leader'), findsOneWidget);
    await tester.tap(find.text('Sam Lead'));
    await settle(tester);
    expect(find.text('Sam Lead'), findsOneWidget); // on the form now

    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(patched()['coordinatorMemberId'], 'm1');
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('the search is debounced and sends q and limit', (tester) async {
    await pumpEdit(tester);
    await tester.tap(find.text('Choose'));
    await settle(tester);
    final before = sent(adapter, 'GET', _members).length;

    await tester.enterText(find.byType(TextField).last, 'sa');
    await tester.enterText(find.byType(TextField).last, 'sam');
    await debounced(tester);

    final requests = sent(adapter, 'GET', _members);
    expect(requests.length, before + 1);
    expect(requests.last.queryParameters, {'q': 'sam', 'limit': 50});
    await unmount(tester);
  });

  testWidgets('"No coordinator" clears it with an explicit null', (
    tester,
  ) async {
    await pumpEdit(tester, coordinator: 'm1', coordinatorName: 'Sam Lead');
    await tester.tap(find.text('Change'));
    await settle(tester);
    await tester.tap(find.text('No coordinator'));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    final body = patched();
    expect(body.containsKey('coordinatorMemberId'), isTrue);
    expect(body['coordinatorMemberId'], isNull);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('leaving it alone does not send a coordinator', (tester) async {
    await pumpEdit(tester, coordinator: 'm1', coordinatorName: 'Sam Lead');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(patched().containsKey('coordinatorMemberId'), isFalse);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets('offline search shows a friendly error with Retry', (
    tester,
  ) async {
    await pumpEdit(
      tester,
      routes: {'GET $_members': const FakeResponse(503, null)},
    );
    await tester.tap(find.text('Choose'));
    await settle(tester);
    expect(find.text('Retry'), findsOneWidget);
    await unmount(tester);
  });
}
