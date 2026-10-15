import 'package:bpj/core/api/api_client.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/util/clock.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// "Now" for the groups screens in tests: before the 2026-10-12 fixtures.
final testNow = DateTime.utc(2026, 10, 7, 12);

/// Provider overrides every screen that reads groups, attendance or the
/// viewer's units needs: one in-memory db and one fake dio for all of them.
List<Override> groupsOverrides(AppDatabase db, Dio dio, {DateTime? now}) => [
  appDatabaseProvider.overrideWithValue(db),
  apiClientProvider.overrideWithValue(dio),
  membershipRepositoryProvider.overrideWithValue(MembershipRepository(db, dio)),
  runsRepositoryProvider.overrideWithValue(RunsRepository(db, dio)),
  activeClubIdProvider.overrideWithValue(1),
  activeSubProvider.overrideWithValue('test|sub'),
  clockProvider.overrideWithValue(() => now ?? testNow),
];

/// Links the caller (member [memberId] with [roles]) to club 1 in [db] and
/// returns the fake network with [routes] added.
Future<FakeAdapter> prepareMember(
  WidgetTester tester,
  AppDatabase db, {
  List<String> roles = const [],
  String memberId = 'me',
  Map<String, Object> routes = const {},
}) async {
  final adapter = FakeAdapter({
    'POST /app/clubs/1/link': FakeResponse(
      200,
      membershipJson(memberId: memberId, roles: roles),
    ),
    ...routes,
  });
  await tester.runAsync(
    () => MembershipRepository(
      db,
      fakeDio(adapter),
    ).link(1, urn: 1, dob: DateTime(1990, 1, 1)),
  );
  return adapter;
}

/// A tall phone-sized surface so long screens build fully.
void tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// Pumps [home] with the groups overrides and lets the Drift streams emit.
Future<void> pumpGroupsApp(
  WidgetTester tester,
  AppDatabase db,
  FakeAdapter adapter,
  Widget home, {
  DateTime? now,
}) async {
  tallSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: groupsOverrides(db, fakeDio(adapter), now: now),
      child: MaterialApp(home: home),
    ),
  );
  await _settle(tester);
}

/// Same, with a router (for screens that pop or push).
Future<void> pumpGroupsRouter(
  WidgetTester tester,
  AppDatabase db,
  FakeAdapter adapter,
  GoRouter router,
) async {
  tallSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: groupsOverrides(db, fakeDio(adapter)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
}

/// Pumps a few frames after a tap, letting async writes and streams finish.
Future<void> settle(WidgetTester tester) => _settle(tester);

/// Works around Drift's stream-cleanup timer outliving the test.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

/// Requests the fake network saw for [method] [path].
List<RequestOptions> sent(FakeAdapter adapter, String method, String path) => [
  for (final r in adapter.requests)
    if (r.method == method && r.path == path) r,
];
