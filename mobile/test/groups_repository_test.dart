import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/distance.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/data/groups_repository.dart';
import 'package:bpj/features/groups/data/members_repository.dart';
import 'package:bpj/features/groups/data/plan_repository.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/groups/data/summary_dtos.dart';
import 'package:drift/drift.dart' show Value;
import 'package:bpj/features/runs/logic/my_days.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  group('GroupsRepository', () {
    late FakeAdapter adapter;
    late GroupsRepository repo;

    Future<void> setup(Map<String, Object> routes) async {
      adapter = FakeAdapter(routes);
      repo = GroupsRepository(db, fakeDio(adapter), newId: () => 'new-uuid');
      await seedMembership(db);
    }

    Future<List<Group>> groups() async =>
        decodeGroups((await db.select(db.sessions).getSingle()).groupsJson);

    Future<SessionSummary> summary() async =>
        decodeSummary((await db.select(db.sessions).getSingle()).summaryJson)!;

    test('createGroup sends the spec and merges the returned group', () async {
      await seedSession(db, 'a', groups: [], summary: summaryJson());
      await setup({
        'POST /app/clubs/1/sessions/a/groups': FakeResponse(
          201,
          groupJson(
            'new-uuid',
            leaders: [leaderJson('me')],
            distanceValue: 3,
            distanceUnit: 'mi',
          ),
        ),
      });
      final g = await repo.createGroup(
        'a',
        pace: PaceRange(
          const Pace(570, DistUnit.mi),
          const Pace(600, DistUnit.mi),
        ),
        distance: const Distance(3, DistUnit.mi),
        label: 'Steady',
      );
      expect(g.id, 'new-uuid');
      expect(adapter.requests.single.data, {
        'id': 'new-uuid',
        'kind': 'run',
        'label': 'Steady',
        'description': null,
        'paceUnit': 'mi',
        'paceFromS': 570,
        'paceToS': 600,
        'distanceValue': 3.0,
        'distanceUnit': 'mi',
        'lead': true,
      });
      expect((await groups()).single.id, 'new-uuid');
      final s = await summary();
      expect(s.groupCount, 1);
      expect(s.leaderCount, 1);
      expect(s.myLeading, isTrue);
    });

    group(
      'leaders attend their own group (D30); stepping down leaves it (D109)',
      () {
        Future<MyAttendanceRow?> attendance() =>
            db.select(db.myAttendance).getSingleOrNull();

        test('createGroup(lead) marks me going in the new group', () async {
          await seedSession(db, 'a', groups: [], summary: summaryJson());
          await setup({
            'POST /app/clubs/1/sessions/a/groups': FakeResponse(
              201,
              groupJson('new-uuid', leaders: [leaderJson('me')], goingCount: 1),
            ),
          });
          await repo.createGroup('a');

          final row = (await attendance())!;
          expect(row.status, 'going');
          expect(row.groupId, 'new-uuid');
          expect(row.pending, isFalse);
          final s = await summary();
          expect(s.myStatus, 'going');
          expect(s.myGroupId, 'new-uuid');
          expect(s.myLeading, isTrue);
          expect(s.goingCount, 1);
          // The server's group already counted the leader: no double count.
          expect((await groups()).single.goingCount, 1);
        });

        test('a leaderless group (lead: false) changes nothing', () async {
          await seedSession(db, 'a', groups: [], summary: summaryJson());
          await setup({
            'POST /app/clubs/1/sessions/a/groups': FakeResponse(
              201,
              groupJson('new-uuid', status: 'needs_leader'),
            ),
          });
          await repo.createGroup('a', lead: false);
          expect(await attendance(), isNull);
          expect((await summary()).myStatus, isNull);
        });

        test(
          'joinAsLeader moves me from another group, keeps my pace',
          () async {
            await seedSession(
              db,
              'a',
              groups: [
                groupJson('g1', goingCount: 2),
                groupJson('g2', goingCount: 1),
              ],
              summary: summaryJson(
                groupCount: 2,
                goingCount: 3,
                myStatus: 'going',
                myGroupId: 'g1',
              ),
            );
            await setup({
              'POST /app/clubs/1/groups/g2/leaders': FakeResponse(
                200,
                groupJson('g2', leaders: [leaderJson('me')], goingCount: 2),
              ),
            });
            await db
                .into(db.myAttendance)
                .insert(
                  MyAttendanceCompanion.insert(
                    sessionId: 'a',
                    clubId: 1,
                    status: 'going',
                    groupId: const Value('g1'),
                    paceUnit: const Value('km'),
                    paceFromS: const Value(350),
                    updatedAt: DateTime.utc(2026, 10, 6),
                  ),
                );

            await repo.joinAsLeader('a', 'g2');

            final row = (await attendance())!;
            expect(row.groupId, 'g2');
            expect(row.status, 'going');
            expect([row.paceUnit, row.paceFromS], ['km', 350]);
            final s = await summary();
            expect(s.myGroupId, 'g2');
            expect(s.goingCount, 3, reason: 'I was already going');
            final gs = {for (final g in await groups()) g.id: g};
            expect(gs['g1']!.goingCount, 1, reason: 'I left g1');
            expect(gs['g2']!.goingCount, 2, reason: 'server count kept');
          },
        );

        test('a maybe becomes going without changing the total', () async {
          await seedSession(
            db,
            'a',
            groups: [groupJson('g1', maybeCount: 1)],
            summary: summaryJson(
              groupCount: 1,
              maybeCount: 1,
              myStatus: 'maybe',
              myGroupId: 'g1',
            ),
          );
          await setup({
            'POST /app/clubs/1/groups/g1/leaders': FakeResponse(
              200,
              groupJson('g1', leaders: [leaderJson('me')], goingCount: 1),
            ),
          });
          await repo.joinAsLeader('a', 'g1');
          final s = await summary();
          expect([s.goingCount, s.maybeCount, s.myStatus], [1, 0, 'going']);
        });

        group('stepping down (D109)', () {
          Future<void> seedLed({int goingCount = 2}) async {
            await seedSession(
              db,
              'a',
              groups: [
                groupJson(
                  'g1',
                  leaders: [leaderJson('me')],
                  goingCount: goingCount,
                ),
                groupJson('g2', goingCount: 1),
              ],
              summary: summaryJson(
                groupCount: 2,
                leaderCount: 1,
                goingCount: goingCount + 1,
                myStatus: 'going',
                myGroupId: 'g1',
                myLeading: true,
              ),
            );
            await db
                .into(db.myAttendance)
                .insert(
                  MyAttendanceCompanion.insert(
                    sessionId: 'a',
                    clubId: 1,
                    status: 'going',
                    groupId: const Value('g1'),
                    paceUnit: const Value('km'),
                    paceFromS: const Value(350),
                    updatedAt: DateTime.utc(2026, 10, 6),
                  ),
                );
          }

          test(
            'removes me from the group, still going, keeps my pace',
            () async {
              await seedLed();
              await setup({
                'DELETE /app/clubs/1/groups/g1/leaders/me': FakeResponse(
                  200,
                  groupJson('g1', status: 'needs_leader', goingCount: 1),
                ),
              });
              final g = await repo.withdrawAsLeader('a', 'g1');
              expect(g.isDeleted, isFalse);
              expect(adapter.requests.single.data, {'notGoing': false});

              final row = (await attendance())!;
              expect(row.status, 'going');
              expect(row.groupId, isNull);
              expect([row.paceUnit, row.paceFromS], ['km', 350]);
              final s = await summary();
              expect(s.myLeading, isFalse);
              expect(
                [s.myStatus, s.myGroupId, s.goingCount],
                ['going', null, 3],
              );
              final gs = {for (final g in await groups()) g.id: g};
              expect(
                gs['g1']!.goingCount,
                1,
                reason: "the server's count is kept",
              );
              expect(gs['g1']!.needsLeader, isTrue);
            },
          );

          test('notGoing sends true and marks me not going', () async {
            await seedLed();
            await setup({
              'DELETE /app/clubs/1/groups/g1/leaders/me': FakeResponse(
                200,
                groupJson('g1', status: 'needs_leader', goingCount: 1),
              ),
            });
            await repo.withdrawAsLeader('a', 'g1', notGoing: true);
            expect(adapter.requests.single.data, {'notGoing': true});

            final row = (await attendance())!;
            expect([row.status, row.groupId], ['not_going', null]);
            final s = await summary();
            expect([s.myStatus, s.myGroupId], ['not_going', null]);
            expect(s.goingCount, 2, reason: 'one fewer going');
          });

          test('a deleted group is removed and my group cleared', () async {
            await seedLed(goingCount: 1);
            await setup({
              'DELETE /app/clubs/1/groups/g1/leaders/me': FakeResponse(200, () {
                final g = groupJson('g1', goingCount: 0);
                g['deletedAt'] = '2026-10-07T10:00:00.000Z';
                return g;
              }()),
            });
            final g = await repo.withdrawAsLeader('a', 'g1');
            expect(g.isDeleted, isTrue);

            expect([for (final g in await groups()) g.id], ['g2']);
            final row = (await attendance())!;
            expect([row.status, row.groupId], ['going', null]);
            final s = await summary();
            expect(s.groupCount, 1);
            expect(s.myLeading, isFalse);
            expect([s.myStatus, s.myGroupId], ['going', null]);
          });

          test('with no local answer nothing is invented', () async {
            await seedSession(
              db,
              'a',
              groups: [
                groupJson('g1', leaders: [leaderJson('me')]),
              ],
              summary: summaryJson(groupCount: 1, myLeading: true),
            );
            await setup({
              'DELETE /app/clubs/1/groups/g1/leaders/me': FakeResponse(
                200,
                groupJson('g1', status: 'needs_leader'),
              ),
            });
            await repo.withdrawAsLeader('a', 'g1');
            expect(await attendance(), isNull);
            expect((await summary()).myStatus, isNull);
          });

          test('errors leave the cache alone', () async {
            await seedLed();
            await setup({
              'DELETE /app/clubs/1/groups/g1/leaders/me': const FakeResponse(
                409,
                {'error': 'session_past', 'message': 'Finished'},
              ),
            });
            await expectLater(
              repo.withdrawAsLeader('a', 'g1'),
              throwsA(isA<ApiException>()),
            );
            expect((await attendance())!.groupId, 'g1');
            expect((await summary()).myGroupId, 'g1');
          });
        });
      },
    );

    test('updateGroup patches every field and replaces the group', () async {
      await seedSession(
        db,
        'a',
        groups: [groupJson('g1', label: 'Old')],
        summary: summaryJson(groupCount: 1),
      );
      await setup({
        'PATCH /app/clubs/1/groups/g1': FakeResponse(
          200,
          groupJson('g1', label: 'New', paceUnit: null, paceFromS: null),
        ),
      });
      await repo.updateGroup('a', 'g1', label: 'New');
      final body = adapter.requests.single.data as Map;
      expect(body['paceFromS'], isNull);
      expect(body.containsKey('paceFromS'), isTrue, reason: 'null clears');
      final gs = await groups();
      expect(gs, hasLength(1));
      expect(gs.single.label, 'New');
      expect(gs.single.pace.isNone, isTrue);
    });

    test('deleteGroup removes it and unassigns my attendance', () async {
      await seedSession(
        db,
        'a',
        groups: [groupJson('g1'), groupJson('g2')],
        summary: summaryJson(
          groupCount: 2,
          goingCount: 1,
          myStatus: 'going',
          myGroupId: 'g1',
        ),
      );
      await db
          .into(db.myAttendance)
          .insert(
            MyAttendanceCompanion.insert(
              sessionId: 'a',
              clubId: 1,
              status: 'going',
              groupId: const Value('g1'),
              updatedAt: DateTime.utc(2026, 10, 7),
            ),
          );
      await setup({'DELETE /app/clubs/1/groups/g1': const FakeResponse(204)});
      await repo.deleteGroup('a', 'g1');
      expect([for (final g in await groups()) g.id], ['g2']);
      final s = await summary();
      expect(s.groupCount, 1);
      expect(s.myGroupId, isNull);
      expect(s.myStatus, 'going');
      expect((await db.select(db.myAttendance).getSingle()).groupId, isNull);
    });

    test('join and withdraw as leader update leaders and myLeading', () async {
      await seedSession(
        db,
        'a',
        groups: [groupJson('g1', status: 'needs_leader')],
        summary: summaryJson(groupCount: 1),
      );
      await setup({
        'POST /app/clubs/1/groups/g1/leaders': FakeResponse(
          200,
          groupJson('g1', leaders: [leaderJson('me', role: 'backmarker')]),
        ),
        'DELETE /app/clubs/1/groups/g1/leaders/me': FakeResponse(
          200,
          groupJson('g1', status: 'needs_leader'),
        ),
      });
      final joined = await repo.joinAsLeader('a', 'g1', role: 'backmarker');
      expect(adapter.requests.single.data, {'role': 'backmarker'});
      expect(joined.status, 'active');
      expect((await groups()).single.leaders.single.role, 'backmarker');
      var s = await summary();
      expect(s.leaderCount, 1);
      expect(s.myLeading, isTrue);

      final left = await repo.withdrawAsLeader('a', 'g1');
      expect(left.needsLeader, isTrue);
      s = await summary();
      expect(s.leaderCount, 0);
      expect(s.myLeading, isFalse);
      expect((await groups()).single.needsLeader, isTrue);
    });

    test('errors propagate and leave the cache alone', () async {
      await seedSession(db, 'a', groups: [], summary: summaryJson());
      await setup({
        'POST /app/clubs/1/sessions/a/groups': const FakeResponse(409, {
          'error': 'session_cancelled',
          'message': 'Cancelled',
        }),
      });
      await expectLater(
        repo.createGroup('a'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'session_cancelled',
          ),
        ),
      );
      expect(await groups(), isEmpty);
    });

    test('offline create throws a network error', () async {
      await seedSession(db, 'a');
      await setup({});
      await expectLater(
        repo.createGroup('a'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
        ),
      );
    });
  });

  group('PlanRepository', () {
    final planBody = {
      'sessionId': 'a',
      'groups': [
        {
          'groupId': 'g1',
          'paces': [
            {'fromSPerKm': 354, 'toSPerKm': null},
          ],
        },
      ],
      'unassigned': {'goingCount': 2, 'maybeCount': 0, 'paces': <Object?>[]},
    };

    test('fetch caches, and offline returns the cached plan', () async {
      await seedSession(db, 'a');
      var online = FakeAdapter({
        'GET /app/clubs/1/sessions/a/plan': FakeResponse(200, planBody),
      });
      var repo = PlanRepository(
        db,
        fakeDio(online),
        clock: () => DateTime.utc(2026, 10, 7, 12),
      );
      expect(await repo.cachedAt('a'), isNull);
      final fresh = await repo.fetchPlan('a');
      expect(fresh?.groups.single.groupId, 'g1');
      expect(
        (await repo.cachedAt('a'))?.toUtc(),
        DateTime.utc(2026, 10, 7, 12),
      );

      online = FakeAdapter({});
      repo = PlanRepository(db, fakeDio(online));
      final cached = await repo.fetchPlan('a');
      expect(cached?.unassigned.goingCount, 2);
      expect((await repo.watchPlan('a').first)?.groups, hasLength(1));
    });

    test('offline with nothing cached returns null', () async {
      await seedSession(db, 'a');
      final repo = PlanRepository(db, fakeDio(FakeAdapter({})));
      expect(await repo.fetchPlan('a'), isNull);
      expect(await repo.watchPlan('a').first, isNull);
    });

    test('a 403 is thrown, not hidden by the cache', () async {
      await seedSession(db, 'a');
      final repo = PlanRepository(
        db,
        fakeDio(
          FakeAdapter({
            'GET /app/clubs/1/sessions/a/plan': const FakeResponse(403, {
              'error': 'forbidden',
            }),
          }),
        ),
      );
      await expectLater(repo.fetchPlan('a'), throwsA(isA<ApiException>()));
    });
  });

  group('RunPreferencesRepository', () {
    RunPreferencesRepository make(Map<String, Object> routes) =>
        RunPreferencesRepository(
          db,
          fakeDio(FakeAdapter(routes)),
          clock: () => DateTime.utc(2026, 10, 7),
        );

    test('defaults to mi / mi with no range when nothing is stored', () async {
      final prefs = await make({}).watch(1).first;
      expect(prefs.paceUnit, DistUnit.mi);
      expect(prefs.distanceUnit, DistUnit.mi);
      expect(prefs.usualPace.isNone, isTrue);
    });

    test('refresh stores the server copy', () async {
      final repo = make({
        'GET /app/clubs/1/preferences': const FakeResponse(200, {
          'paceUnit': 'km',
          'distanceUnit': 'mi',
          'paceFromS': 330,
          'paceToS': 360,
          'updatedAt': '2026-10-01T10:00:00.000Z',
        }),
      });
      await repo.refresh(1);
      final p = await repo.watch(1).first;
      expect(p.paceUnit, DistUnit.km);
      expect(p.distanceUnit, DistUnit.mi);
      expect(p.paceFromS, 330);
      expect(p.paceToS, 360);
    });

    test('save PUTs the full set and caches the response', () async {
      final adapter = FakeAdapter({
        'PUT /app/clubs/1/preferences': const FakeResponse(200, {
          'paceUnit': 'mi',
          'distanceUnit': 'km',
          'paceFromS': 540,
          'paceToS': 600,
          'updatedAt': '2026-10-07T10:00:00.000Z',
        }),
      });
      final repo = RunPreferencesRepository(db, fakeDio(adapter));
      await repo.save(
        1,
        paceUnit: DistUnit.mi,
        distanceUnit: DistUnit.km,
        usualPace: PaceRange(
          const Pace(540, DistUnit.mi),
          const Pace(600, DistUnit.mi),
        ),
      );
      expect(adapter.requests.single.data, {
        'paceUnit': 'mi',
        'distanceUnit': 'km',
        'paceFromS': 540,
        'paceToS': 600,
      });
      final p = await repo.watch(1).first;
      expect(p.distanceUnit, DistUnit.km);
      expect(p.usualPace.display(DistUnit.mi), '9:00-10:00/mi');
    });

    test('clearing sends null and stores the cleared range', () async {
      final adapter = FakeAdapter({
        'PUT /app/clubs/1/preferences': const FakeResponse(200, {
          'paceUnit': 'km',
          'distanceUnit': 'mi',
          'paceFromS': null,
          'paceToS': null,
        }),
      });
      final repo = RunPreferencesRepository(db, fakeDio(adapter));
      await repo.save(1, paceUnit: DistUnit.km, distanceUnit: DistUnit.mi);
      expect(adapter.requests.single.data, {
        'paceUnit': 'km',
        'distanceUnit': 'mi',
        'paceFromS': null,
        'paceToS': null,
      });
      expect((await repo.watch(1).first).usualPace.isNone, isTrue);
    });

    test('save offline throws and keeps the cache', () async {
      final repo = make({});
      await expectLater(
        repo.save(1, paceUnit: DistUnit.km, distanceUnit: DistUnit.km),
        throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'n', true)),
      );
      expect((await repo.watch(1).first).paceUnit, DistUnit.mi);
    });

    group('leadDays (D107)', () {
      const body = {'paceUnit': 'mi', 'distanceUnit': 'mi'};

      test('null (never chosen), [] (none) and a list round-trip', () async {
        final repo = make({
          'GET /app/clubs/1/preferences': const FakeResponse(200, {
            ...body,
            'leadDays': null,
          }),
        });
        await repo.refresh(1);
        expect((await repo.watch(1).first).leadDays, isNull);

        for (final days in [
          <int>[],
          [2, 4],
        ]) {
          final r = make({
            'PUT /app/clubs/1/preferences': FakeResponse(200, {
              ...body,
              'leadDays': days,
            }),
          });
          await r.saveDays(1, DayKind.lead, days);
          expect((await r.watch(1).first).leadDays, days);
        }
      });

      test('saveDays sends only leadDays, sorted; null resets', () async {
        final adapter = FakeAdapter({
          'PUT /app/clubs/1/preferences': const FakeResponse(200, {
            ...body,
            'leadDays': [2, 4],
          }),
        });
        final repo = RunPreferencesRepository(db, fakeDio(adapter));
        await repo.saveDays(1, DayKind.lead, [4, 2]);
        expect(adapter.requests.single.data, {
          'leadDays': [2, 4],
        });
        await repo.saveDays(1, DayKind.lead, null);
        expect(adapter.requests.last.data, {'leadDays': null});
      });

      test(
        'saving units keeps the cached leadDays (the server echoes it)',
        () async {
          final adapter = FakeAdapter({
            'PUT /app/clubs/1/preferences': const FakeResponse(200, {
              'paceUnit': 'km',
              'distanceUnit': 'km',
              'leadDays': [3],
            }),
          });
          final repo = RunPreferencesRepository(db, fakeDio(adapter));
          await repo.save(1, paceUnit: DistUnit.km, distanceUnit: DistUnit.km);
          expect((await repo.watch(1).first).leadDays, [3]);
          expect(adapter.requests.single.data, isNot(contains('leadDays')));
        },
      );

      test('runDays: sends only runDays and caches both lists back', () async {
        final adapter = FakeAdapter({
          'PUT /app/clubs/1/preferences': const FakeResponse(200, {
            ...body,
            // The server dropped Wednesday from the lead days (D115).
            'runDays': [1, 3],
            'leadDays': [1],
          }),
        });
        final repo = RunPreferencesRepository(db, fakeDio(adapter));
        await repo.saveDays(1, DayKind.run, [3, 1]);
        expect(adapter.requests.single.data, {
          'runDays': [1, 3],
        });
        final cached = await repo.watch(1).first;
        expect(cached.runDays, [1, 3]);
        expect(cached.leadDays, [1]);
        expect(cached.daysOf(DayKind.run), [1, 3]);
        expect(cached.daysOf(DayKind.lead), [1]);
      });

      test('offline throws and keeps the cache', () async {
        final repo = make({});
        await expectLater(
          repo.saveDays(1, DayKind.lead, [1]),
          throwsA(
            isA<ApiException>().having((e) => e.isNetworkError, 'n', true),
          ),
        );
        expect((await repo.watch(1).first).leadDays, isNull);
      });
    });
  });

  group('MembersRepository', () {
    test('search and setRoles', () async {
      final adapter = FakeAdapter({
        'GET /app/clubs/1/members': const FakeResponse(200, {
          'items': [
            {
              'memberId': 'm1',
              'displayName': 'Jo Bloggs',
              'status': 'active',
              'roles': ['leader'],
            },
          ],
        }),
        'PATCH /app/clubs/1/members/m1/roles': const FakeResponse(200, {
          'memberId': 'm1',
          'displayName': 'Jo Bloggs',
          'status': 'active',
          'roles': <String>[],
        }),
      });
      final repo = MembersRepository(fakeDio(adapter));
      final found = await repo.search(1, 'jo');
      expect(adapter.requests.first.queryParameters, {'q': 'jo', 'limit': 50});
      expect(found.single.isLeader, isTrue);
      final updated = await repo.setRoles(1, 'm1', const []);
      expect(adapter.requests.last.data, {'roles': <String>[]});
      expect(updated.isLeader, isFalse);
    });

    test('403 is an ApiException', () async {
      final repo = MembersRepository(
        fakeDio(
          FakeAdapter({
            'GET /app/clubs/1/members': const FakeResponse(403, {
              'error': 'forbidden',
            }),
          }),
        ),
      );
      await expectLater(
        repo.search(1, ''),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 403)),
      );
    });
  });
}
