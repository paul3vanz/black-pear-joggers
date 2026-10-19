import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/data/follows_repository.dart';
import 'package:bpj/features/runs/logic/follow_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_follows.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late FakeFollowsServer server;
  late FollowsRepository repo;

  setUp(() {
    db = memoryDb();
    server = FakeFollowsServer([
      followJson('mon', usuallyComes: true),
      followJson('mug', title: 'The Mug Run', weekday: 4, start: '18:30'),
      followJson('perd', title: 'Thursday Perdiswell', weekday: 4),
    ]);
    adapter = FakeAdapter(server.routes(() => adapter.requests.last.data));
    repo = FollowsRepository(db, fakeDio(adapter));
  });
  tearDown(() => db.close());

  Future<Map<String, FollowMode>> cached() async => {
    for (final f in await repo.watch(1).first) f.seriesId: f.mode,
  };

  test('refresh caches every series in week order', () async {
    await repo.refresh(1);
    final list = await repo.watch(1).first;
    expect(list.map((f) => f.seriesId), ['mon', 'mug', 'perd']);
    expect(list.first.usuallyComes, isTrue);
    expect(list.first.followed, isTrue); // auto + usually comes
    expect(list[1].followed, isFalse);

    // A series the server no longer lists is dropped.
    server.series.removeLast();
    await repo.refresh(1);
    expect((await cached()).keys, ['mon', 'mug']);
  });

  test(
    'setMode updates the cache at once and keeps the server answer',
    () async {
      await repo.refresh(1);
      final seen = <FollowMode>[];
      final sub = repo
          .watch(1)
          .listen(
            (l) => seen.add(l.firstWhere((f) => f.seriesId == 'perd').mode),
          );

      await repo.setMode(1, 'perd', FollowMode.hide);
      await pumpEventQueue();

      expect(adapter.requests.last.data, {'mode': 'hide'});
      expect(adapter.requests.last.path, '/app/clubs/1/follows/perd');
      expect((await cached())['perd'], FollowMode.hide);
      expect(seen, contains(FollowMode.hide));
      await sub.cancel();
    },
  );

  test('a failed write puts the old value back and rethrows', () async {
    await repo.refresh(1);
    server.fail = true;

    await expectLater(
      repo.setMode(1, 'mug', FollowMode.follow),
      throwsA(isA<ApiException>()),
    );
    expect((await cached())['mug'], FollowMode.auto);

    await expectLater(
      repo.setMany(1, ['mug', 'perd'], FollowMode.follow),
      throwsA(isA<ApiException>()),
    );
    expect(await cached(), {
      'mon': FollowMode.auto,
      'mug': FollowMode.auto,
      'perd': FollowMode.auto,
    });
  });

  test(
    'setMany returns the previous modes and restore puts them back',
    () async {
      await repo.refresh(1);
      await repo.setMode(1, 'perd', FollowMode.hide);

      final previous = await repo.setMany(1, [
        'mon',
        'mug',
        'perd',
      ], FollowMode.follow);
      expect(adapter.requests.last.data, {
        'seriesIds': ['mon', 'mug', 'perd'],
        'mode': 'follow',
      });
      expect(previous, {
        'mon': FollowMode.auto,
        'mug': FollowMode.auto,
        'perd': FollowMode.hide,
      });
      expect((await cached()).values.toSet(), {FollowMode.follow});

      await repo.restore(1, previous);
      expect(adapter.requests.last.data, {
        'modes': {'mon': 'auto', 'mug': 'auto', 'perd': 'hide'},
      });
      expect(await cached(), previous);
    },
  );
}
