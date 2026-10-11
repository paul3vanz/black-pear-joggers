import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/runs/data/run_dtos.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  final opened = <Uri>[];

  setUp(() {
    db = memoryDb();
    opened.clear();
  });
  tearDown(() => db.close());

  Future<void> pumpDetail(
    WidgetTester tester, {
    required List<String> roles,
    String? cmsSlug = 'monday-club-run',
    String status = 'scheduled',
  }) async {
    adapter = FakeAdapter({
      'POST /app/clubs/1/link': FakeResponse(200, membershipJson(roles: roles)),
    });
    final dio = fakeDio(adapter);
    await tester.runAsync(() async {
      await MembershipRepository(
        db,
        dio,
      ).link(1, urn: 1, dob: DateTime(1990, 1, 1));
      await db
          .into(db.venues)
          .insert(
            VenueDto.fromJson(
              venueJson('v1', name: 'OECC', lat: 52.19, lng: -2.22),
            ).toCompanion(1),
          );
      await db
          .into(db.sessionSeries)
          .insert(
            SeriesDto.fromJson(seriesJson('s1', cmsSlug: cmsSlug))
                .toCompanion(1),
          );
      await db
          .into(db.sessions)
          .insert(
            SessionDto.fromJson(
              sessionJson(
                'a',
                localDate: '2026-10-12',
                status: status,
                cancelReason: status == 'cancelled' ? 'Bank holiday' : null,
              ),
            ).toCompanion(1),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, dio),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: const MaterialApp(home: SessionDetailScreen(sessionId: 'a')),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('shows venue, maps and series page links; no committee actions', (
    tester,
  ) async {
    await pumpDetail(tester, roles: []);
    expect(find.text('Monday 12 October, 19:00–20:30'), findsOneWidget);
    expect(find.textContaining('OECC'), findsOneWidget);
    expect(find.text('Cancel run'), findsNothing);

    await tester.scrollUntilVisible(find.text('Open in maps'), 100);
    await tester.tap(find.text('Open in maps'));
    await tester.pump();
    expect(
      opened.single.toString(),
      'https://www.google.com/maps/search/?api=1&query=52.19%2C-2.22',
    );

    await tester.ensureVisible(find.text('More about this run'));
    await tester.tap(find.text('More about this run'));
    await tester.pump();
    expect(
      opened.last.toString(),
      'https://bpj.org.uk/club-runs/monday-club-run',
    );
    await unmount(tester);
  });

  testWidgets('hides the series page link when there is no slug', (
    tester,
  ) async {
    await pumpDetail(tester, roles: [], cmsSlug: null);
    expect(find.text('More about this run'), findsNothing);
    await unmount(tester);
  });

  testWidgets('committee see edit and cancel; restore when cancelled', (
    tester,
  ) async {
    await pumpDetail(tester, roles: ['committee']);
    await tester.scrollUntilVisible(find.text('Edit this run'), 200);
    expect(find.text('Edit this run'), findsOneWidget);
    expect(find.text('Cancel run'), findsOneWidget);
    expect(find.text('Restore run'), findsNothing);
    await unmount(tester);

    await db.clearAll();
    await pumpDetail(tester, roles: ['committee'], status: 'cancelled');
    expect(find.text('This run is cancelled'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Restore run'), 200);
    expect(find.text('Restore run'), findsOneWidget);
    expect(find.text('Cancel run'), findsNothing);
    await unmount(tester);
  });
}
