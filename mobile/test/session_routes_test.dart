import 'dart:convert';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/distance.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/data/groups_repository.dart';
import 'package:bpj/features/groups/data/route_dtos.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';

Map<String, Object?> routeJson(
  String id, {
  String label = '10 mile',
  String url = 'https://www.plotaroute.com/route/403075',
  double? distanceValue = 10,
  String? distanceUnit = 'mi',
  int sortOrder = 0,
}) => {
  'id': id,
  'sessionId': 'a',
  'label': label,
  'url': url,
  'distanceValue': distanceValue,
  'distanceUnit': distanceUnit,
  'distanceM': 16093,
  'sortOrder': sortOrder,
};

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('a route survives JSON and a bad blob decodes to none', () {
    final r = SessionRoute.fromJson(routeJson('r1'));
    expect(r.distance, const Distance(10, DistUnit.mi));
    expect(SessionRoute.fromJson(r.toJson()).url, r.url);
    expect(decodeRoutes(encodeRoutes([r])).single.id, 'r1');
    expect(decodeRoutes(null), isEmpty);
    expect(decodeRoutes('nope'), isEmpty);
  });

  test('a group carries its picked route and can drop it', () {
    final g = Group.fromJson({
      'id': 'g',
      'routeId': 'r1',
      'routeLabel': '10 mile',
      'routeUrl': 'https://example.com/r',
    });
    expect(g.routeId, 'r1');
    expect(Group.fromJson(g.toJson()).routeLabel, '10 mile');
    expect(g.copyWith(goingCount: 2).routeId, 'r1');
    final cleared = g.copyWith(clearRoute: true);
    expect(cleared.routeId, isNull);
    expect(cleared.routeUrl, isNull);
    expect(cleared.routeLabel, isNull);
  });

  group('GroupsRepository routes', () {
    late FakeAdapter adapter;
    late GroupsRepository repo;

    Future<void> setup(Map<String, Object> routes) async {
      adapter = FakeAdapter(routes);
      repo = GroupsRepository(db, fakeDio(adapter), newId: () => 'new-uuid');
      await seedMembership(db);
    }

    Future<Session> row() => db.select(db.sessions).getSingle();

    test('createRoute posts the fields and caches the route', () async {
      await seedSession(db, 'a');
      await setup({
        'POST /app/clubs/1/sessions/a/routes': FakeResponse(
          201,
          routeJson('new-uuid'),
        ),
      });
      final r = await repo.createRoute(
        'a',
        label: '10 mile',
        url: 'https://www.plotaroute.com/route/403075',
        distance: const Distance(10, DistUnit.mi),
      );
      expect(r.id, 'new-uuid');
      expect(adapter.requests.single.data, {
        'id': 'new-uuid',
        'label': '10 mile',
        'url': 'https://www.plotaroute.com/route/403075',
        'distanceValue': 10.0,
        'distanceUnit': 'mi',
      });
      expect(decodeRoutes((await row()).routesJson).single.label, '10 mile');
    });

    test('editing a route updates the groups that picked it', () async {
      await seedSession(
        db,
        'a',
        groups: [
          groupJson('g1', label: 'Steady'),
          groupJson('g2'),
        ],
      );
      final groups = [
        Group.fromJson({
          ...groupJson('g1', label: 'Steady'),
          'routeId': 'r1',
          'routeLabel': 'Old',
          'routeUrl': 'https://old.example.com',
        }),
        Group.fromJson(groupJson('g2')),
      ];
      await (db.update(db.sessions)).write(
        SessionsCompanion(
          groupsJson: Value(encodeGroups(groups)),
          routesJson: Value(
            encodeRoutes([SessionRoute.fromJson(routeJson('r1'))]),
          ),
        ),
      );
      await setup({
        'PATCH /app/clubs/1/routes/r1': FakeResponse(
          200,
          routeJson('r1', label: 'Ten', url: 'https://new.example.com'),
        ),
      });
      await repo.updateRoute(
        'a',
        'r1',
        label: 'Ten',
        url: 'https://new.example.com',
      );
      final cached = decodeGroups((await row()).groupsJson);
      expect(cached.first.routeUrl, 'https://new.example.com');
      expect(cached.first.routeLabel, 'Ten');
      expect(cached.last.routeId, isNull);
    });

    test('deleting a route leaves its groups with none', () async {
      await seedSession(db, 'a', groups: [groupJson('g1', label: 'Steady')]);
      final g = Group.fromJson({
        ...groupJson('g1', label: 'Steady'),
        'routeId': 'r1',
        'routeLabel': 'Ten',
        'routeUrl': 'https://x.example.com',
      });
      await db
          .update(db.sessions)
          .write(
            SessionsCompanion(
              groupsJson: Value(encodeGroups([g])),
              routesJson: Value(jsonEncode([routeJson('r1')])),
            ),
          );
      await setup({'DELETE /app/clubs/1/routes/r1': FakeResponse(204, null)});
      await repo.deleteRoute('a', 'r1');
      final r = await row();
      expect(decodeRoutes(r.routesJson), isEmpty);
      final cached = decodeGroups(r.groupsJson).single;
      expect(cached.routeId, isNull);
      expect(cached.routeUrl, isNull);
    });
  });
}
