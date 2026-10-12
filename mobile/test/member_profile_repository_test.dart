import 'dart:typed_data';

import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/members/data/member_dtos.dart';
import 'package:bpj/features/members/data/member_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase65.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late MemberProfileRepository repo;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  void setup(Map<String, Object> routes) {
    adapter = FakeAdapter(routes);
    repo = MemberProfileRepository(
      db,
      fakeDio(adapter),
      apiBaseUrl: 'https://bpj.example/api/public/index.php',
    );
  }

  const cardsKey = 'GET /app/clubs/1/member-cards';
  const profileKey = 'GET /app/clubs/1/members/sam/profile';
  const mineKey = 'GET /app/clubs/1/member-profile';

  Matcher apiError({int? status, bool? network}) => isA<ApiException>()
      .having((e) => e.statusCode, 'status', status)
      .having((e) => e.isNetworkError, 'network', network ?? false);

  group('cards', () {
    test('refreshCards replaces the club rows only', () async {
      await seedCard(db, 'old', name: 'Old O.');
      await seedCard(db, 'other-club', name: 'Else E.', clubId: 2);
      setup({
        cardsKey: FakeResponse(
          200,
          memberCardsBody([
            memberCardJson(
              'sam',
              photoPath: photoPathJson,
              roles: ['leader', 'committee'],
              hasBio: true,
            ),
            memberCardJson('kim', displayName: 'Kim L.'),
          ]),
        ),
      });
      await repo.refreshCards(1);
      final rows = await db.select(db.memberCards).get();
      expect(
        rows.map((r) => r.memberId),
        unorderedEquals(['sam', 'kim', 'other-club']),
      );
      final sam = rows.firstWhere((r) => r.memberId == 'sam');
      expect(sam.rolesCsv, 'leader,committee');
      expect(sam.hasBio, isTrue);
      expect(sam.photoPath, photoPathJson);
    });

    test('a failed refresh keeps the old rows; quiet ignores it', () async {
      await seedCard(db, 'old');
      setup({}); // no route -> connection error
      await expectLater(repo.refreshCards(1), throwsA(apiError(network: true)));
      await repo.refreshCardsQuietly(1);
      expect(await db.select(db.memberCards).get(), hasLength(1));
    });

    test('watchCard and watchCards stream the table', () async {
      setup({
        cardsKey: FakeResponse(
          200,
          memberCardsBody([memberCardJson('sam'), memberCardJson('kim')]),
        ),
      });
      final single = repo.watchCard('sam').firstWhere((c) => c != null);
      final all = repo.watchCards(1).firstWhere((m) => m.length == 2);
      await repo.refreshCards(1);
      expect((await single)!.displayName, 'Sam B.');
      expect((await all).keys, unorderedEquals(['sam', 'kim']));
    });
  });

  group('profiles', () {
    test('fetchProfile parses, caches and watchProfile emits it', () async {
      setup({
        profileKey: FakeResponse(
          200,
          memberProfileJson(
            'sam',
            roles: ['leader'],
            photoPath: photoPathJson,
            goals: 'Sub-20 5k',
          ),
        ),
      });
      final result = await repo.fetchProfile(1, 'sam');
      expect(result.fromCache, isFalse);
      expect(result.value.displayName, 'Sam B.');
      expect(result.value.goals, 'Sub-20 5k');
      expect(result.value.roles, ['leader']);
      final cached = await repo.watchProfile(1, 'sam').first;
      expect(cached!.bio, 'Love a hilly run.');
    });

    test('offline returns the cached copy', () async {
      setup({profileKey: FakeResponse(200, memberProfileJson('sam'))});
      await repo.fetchProfile(1, 'sam');
      adapter.routes.remove(profileKey);
      final result = await repo.fetchProfile(1, 'sam');
      expect(result.fromCache, isTrue);
      expect(result.fetchedAt, isNotNull);
      expect(result.value.displayName, 'Sam B.');
    });

    test('offline with nothing cached throws the typed error', () async {
      setup({});
      await expectLater(
        repo.fetchProfile(1, 'sam'),
        throwsA(isA<MemberOfflineException>()),
      );
    });

    test('404 propagates and drops the cached copy', () async {
      setup({profileKey: FakeResponse(200, memberProfileJson('sam'))});
      await repo.fetchProfile(1, 'sam');
      adapter.routes[profileKey] = const FakeResponse(404, {
        'error': 'not_found',
        'message': 'No such member',
      });
      await expectLater(
        repo.fetchProfile(1, 'sam'),
        throwsA(apiError(status: 404)),
      );
      expect(await db.select(db.memberProfiles).get(), isEmpty);
    });

    test('clearMemberProfile deletes, drops the cache and refreshes', () async {
      setup({
        profileKey: FakeResponse(200, memberProfileJson('sam')),
        'DELETE /app/clubs/1/members/sam/profile': const FakeResponse(204),
        cardsKey: FakeResponse(200, memberCardsBody([])),
      });
      await repo.fetchProfile(1, 'sam');
      await seedCard(db, 'sam', photoPath: photoPathJson);
      await repo.clearMemberProfile(1, 'sam');
      expect(await db.select(db.memberProfiles).get(), isEmpty);
      expect(await db.select(db.memberCards).get(), isEmpty);
      expect(
        adapter.requests.map((r) => '${r.method} ${r.path}'),
        contains('DELETE /app/clubs/1/members/sam/profile'),
      );
    });

    test('clearMemberProfile surfaces a 403', () async {
      setup({
        'DELETE /app/clubs/1/members/sam/profile': const FakeResponse(403, {
          'error': 'forbidden',
          'message': 'Committee only',
        }),
      });
      await expectLater(
        repo.clearMemberProfile(1, 'sam'),
        throwsA(apiError(status: 403)),
      );
    });
  });

  group('my card', () {
    const putKey = 'PUT /app/clubs/1/member-profile';
    const photoKey = 'PUT /app/clubs/1/member-profile/photo';

    test(
      'fetchMine caches, offline falls back, empty offline throws',
      () async {
        setup({});
        await expectLater(
          repo.fetchMine(1),
          throwsA(isA<MemberOfflineException>()),
        );
        adapter.routes[mineKey] = FakeResponse(
          200,
          myCardJson(bio: 'Hi', goalsVisible: true),
        );
        final online = await repo.fetchMine(1);
        expect(online.value.bio, 'Hi');
        expect(online.value.goalsVisible, isTrue);
        adapter.routes.remove(mineKey);
        final offline = await repo.fetchMine(1);
        expect(offline.fromCache, isTrue);
        expect(offline.value.bio, 'Hi');
        expect((await repo.watchMine(1).first)!.bio, 'Hi');
      },
    );

    test('saveMine sends only the given keys and caches the reply', () async {
      setup({
        putKey: FakeResponse(200, myCardJson(bio: 'New', goalsVisible: true)),
        cardsKey: FakeResponse(200, memberCardsBody([])),
      });
      final card = await repo.saveMine(1, bio: 'New', goalsVisible: true);
      expect(card.bio, 'New');
      final put = adapter.requests.firstWhere((r) => r.method == 'PUT');
      expect(put.data, {'bio': 'New', 'goalsVisible': true});
      // The cards list is refreshed afterwards.
      expect(
        adapter.requests.map((r) => r.path),
        contains('/app/clubs/1/member-cards'),
      );
      expect((await repo.watchMine(1).first)!.bio, 'New');
    });

    test('saveMine maps a 422 to field errors', () async {
      setup({putKey: FakeResponse(422, validationBody('bio', 'Too long.'))});
      await expectLater(
        repo.saveMine(1, bio: 'x'),
        throwsA(
          isA<ApiException>().having((e) => e.fieldErrors, 'fieldErrors', {
            'bio': 'Too long.',
          }),
        ),
      );
    });

    test(
      'uploadPhoto sends multipart photo / photo.jpg / image/jpeg',
      () async {
        setup({
          photoKey: FakeResponse(200, myCardJson(photoPath: photoPathJson)),
          cardsKey: FakeResponse(200, memberCardsBody([])),
        });
        final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]);
        final card = await repo.uploadPhoto(1, bytes);
        expect(card.photoPath, photoPathJson);
        final req = adapter.requests.firstWhere(
          (r) => r.path.endsWith('/photo'),
        );
        final form = req.data as FormData;
        expect(form.files, hasLength(1));
        expect(form.files.single.key, 'photo');
        final file = form.files.single.value;
        expect(file.filename, 'photo.jpg');
        expect(file.contentType.toString(), 'image/jpeg');
        expect(file.length, bytes.length);
      },
    );

    test('removePhoto deletes and caches the card', () async {
      setup({
        'DELETE /app/clubs/1/member-profile/photo': FakeResponse(
          200,
          myCardJson(bio: 'Hi'),
        ),
        cardsKey: FakeResponse(200, memberCardsBody([])),
      });
      final card = await repo.removePhoto(1);
      expect(card.photoPath, isNull);
      expect((await repo.watchMine(1).first)!.photoPath, isNull);
    });

    test('writes while offline throw a network ApiException', () async {
      setup({});
      await expectLater(
        repo.saveMine(1, bio: 'x'),
        throwsA(apiError(network: true)),
      );
      await expectLater(
        repo.uploadPhoto(1, Uint8List(3)),
        throwsA(apiError(network: true)),
      );
    });
  });

  group('photoUrl', () {
    test('joins the base path segment and the relative path', () {
      setup({});
      expect(
        repo.photoUrl(photoPathJson),
        'https://bpj.example/api/public/index.php$photoPathJson',
      );
    });

    test('is null-safe and tolerant of slashes and absolute URLs', () {
      expect(joinApiUrl('https://h/api/public/index.php', null), isNull);
      expect(joinApiUrl('https://h/api/public/index.php', ''), isNull);
      expect(joinApiUrl('https://h/x/', '/app/a'), 'https://h/x/app/a');
      expect(joinApiUrl('https://h/x', 'app/a'), 'https://h/x/app/a');
      expect(
        joinApiUrl('https://h/x', 'https://cdn/a.jpg'),
        'https://cdn/a.jpg',
      );
    });
  });
}
