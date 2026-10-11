import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/profile/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  group('MembershipRepository', () {
    test('refreshMe replaces the cached rows', () async {
      final adapter = FakeAdapter({
        'GET /app/me': FakeResponse(
          200,
          meJson([
            membershipJson(memberId: 'new', roles: ['leader']),
          ]),
        ),
      });
      final repo = MembershipRepository(db, fakeDio(adapter));
      // A stale row that the server no longer returns.
      await repo.refreshMe();
      adapter.routes['GET /app/me'] = FakeResponse(
        200,
        meJson([membershipJson(memberId: 'newer', firstName: 'Sam')]),
      );
      await repo.refreshMe();

      final rows = await repo.watchMemberships().first;
      expect(rows.map((r) => r.memberId), ['newer']);
      expect(rows.single.firstName, 'Sam');
      expect(rows.single.clubName, 'Black Pear Joggers');
    });

    test('refreshMe with no memberships empties the cache', () async {
      final adapter = FakeAdapter({
        'GET /app/me': FakeResponse(200, meJson([membershipJson()])),
      });
      final repo = MembershipRepository(db, fakeDio(adapter));
      await repo.refreshMe();
      adapter.routes['GET /app/me'] = FakeResponse(200, meJson([]));
      await repo.refreshMe();
      expect(await repo.watchMemberships().first, isEmpty);
    });

    test('link upserts the membership and sends dob as yyyy-MM-dd', () async {
      final adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
      });
      final repo = MembershipRepository(db, fakeDio(adapter));

      final m = await repo.link(1, urn: 1234567, dob: DateTime(1983, 1, 5));

      expect(m.memberId, 'member-1');
      expect(m.category, 'V40');
      expect(adapter.requests.single.data, {
        'urn': 1234567,
        'dob': '1983-01-05',
      });
      expect((await repo.watchMemberships().first).length, 1);
    });

    test(
      'link 404 throws ApiException(not_found) and stores nothing',
      () async {
        final adapter = FakeAdapter({
          'POST /app/clubs/1/link': const FakeResponse(404, {
            'error': 'not_found',
          }),
        });
        final repo = MembershipRepository(db, fakeDio(adapter));

        await expectLater(
          repo.link(1, urn: 1, dob: DateTime(1990, 1, 1)),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'not_found')
                .having((e) => e.statusCode, 'status', 404),
          ),
        );
        expect(await repo.watchMemberships().first, isEmpty);
      },
    );

    test('unlink removes the membership and its profile', () async {
      final adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
        'GET /app/clubs/1/profile': FakeResponse(200, profileJson()),
        'DELETE /app/clubs/1/link': const FakeResponse(204),
      });
      final dio = fakeDio(adapter);
      final repo = MembershipRepository(db, dio);
      final profiles = ProfileRepository(db, dio);
      await repo.link(1, urn: 1, dob: DateTime(1990, 1, 1));
      await profiles.refreshProfile(1);
      expect(await profiles.watchProfile(1).first, isNotNull);

      await repo.unlink(1);

      expect(await repo.watchMemberships().first, isEmpty);
      expect(await profiles.watchProfile(1).first, isNull);
    });
  });

  group('ProfileRepository', () {
    test('refreshProfile stores the profile', () async {
      final adapter = FakeAdapter({
        'GET /app/clubs/1/profile': FakeResponse(200, profileJson()),
      });
      final repo = ProfileRepository(db, fakeDio(adapter));

      expect(await repo.refreshProfile(1), ProfileRefresh.updated);

      final p = (await repo.watchProfile(1).first)!;
      expect(p.firstName, 'Jo');
      expect(p.competitiveRegStatus, 'Registered');
      expect(p.resultsUrl, contains('450606'));
      expect(p.powerOf10Url, isNull);
      expect(p.rolesJson, '["leader"]');
    });

    test('403 not_a_member clears the local membership', () async {
      final adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
        'GET /app/clubs/1/profile': FakeResponse(200, profileJson()),
      });
      final dio = fakeDio(adapter);
      final memberships = MembershipRepository(db, dio);
      final profiles = ProfileRepository(db, dio);
      await memberships.link(1, urn: 1, dob: DateTime(1990, 1, 1));
      await profiles.refreshProfile(1);

      adapter.routes['GET /app/clubs/1/profile'] = const FakeResponse(403, {
        'error': 'not_a_member',
        'message': 'Not a member',
      });
      expect(await profiles.refreshProfile(1), ProfileRefresh.notAMember);

      expect(await memberships.watchMemberships().first, isEmpty);
      expect(await profiles.watchProfile(1).first, isNull);
    });

    test('other failures are rethrown and the cache is kept', () async {
      final adapter = FakeAdapter({
        'GET /app/clubs/1/profile': FakeResponse(200, profileJson()),
      });
      final repo = ProfileRepository(db, fakeDio(adapter));
      await repo.refreshProfile(1);
      adapter.routes.remove('GET /app/clubs/1/profile'); // now "offline"

      await expectLater(
        repo.refreshProfile(1),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
        ),
      );
      expect(await repo.watchProfile(1).first, isNotNull);
    });
  });
}
