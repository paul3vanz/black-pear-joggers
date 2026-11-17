import 'package:bpj/core/notifications/refresh_coordinator.dart';
import 'package:bpj/core/notifications/refresh_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('refreshTargetFor', () {
    test('new group push refreshes the run named in the payload', () {
      expect(
        refreshTargetFor({
          'category': 'group_matches',
          'route': '/runs/s1',
          'sessionId': 's1',
          'groupId': 'g1',
        }),
        const RefreshTarget(sessionId: 's1', sessions: true),
      );
    });

    test('falls back to the id in the route when sessionId is missing', () {
      expect(
        refreshTargetFor({'category': 'leaders_needed', 'route': '/runs/s2'}),
        const RefreshTarget(sessionId: 's2', sessions: true),
      );
      expect(
        refreshTargetFor({'route': '/runs/s3/groups/new?x=1'}).sessionId,
        's3',
      );
    });

    test('updates refresh posts, chats refresh threads only', () {
      expect(
        refreshTargetFor({'category': 'club_updates', 'route': '/updates/p1'}),
        const RefreshTarget(posts: true),
      );
      expect(
        refreshTargetFor({
          'category': 'group_messages',
          'route': '/runs/s1/groups/g1/chat',
          'sessionId': 's1',
        }),
        const RefreshTarget(sessionId: 's1', threads: true),
      );
      expect(
        refreshTargetFor({'route': '/updates/p1/comments'}),
        const RefreshTarget(posts: true, threads: true),
      );
    });

    test('non-run routes and reserved segments refresh nothing special', () {
      expect(refreshTargetFor({'route': '/inbox'}), const RefreshTarget());
      expect(sessionIdFromRoute('/runs/new'), isNull);
      expect(sessionIdFromRoute('/runs'), isNull);
      expect(sessionIdFromRoute('/runs/series/abc'), isNull);
      expect(openSessionIdFromLocation('/runs/abc/edit'), 'abc');
    });
  });

  group('RefreshCoordinator', () {
    late DateTime now;
    late List<String> calls;
    late RefreshCoordinator coordinator;

    setUp(() {
      now = DateTime(2026, 1, 1, 12);
      calls = [];
      coordinator = RefreshCoordinator(
        now: () => now,
        fetchSessions: (club) async => calls.add('sessions:$club'),
        fetchPlan: (id) async => calls.add('plan:$id'),
      );
    });

    test('non-forced refreshes are throttled to once a minute', () async {
      expect(await coordinator.refreshSessions(1), isTrue);
      expect(await coordinator.refreshSessions(1), isFalse);
      now = now.add(const Duration(seconds: 59));
      expect(await coordinator.refreshSessions(1), isFalse);
      now = now.add(const Duration(seconds: 2));
      expect(await coordinator.refreshSessions(1), isTrue);
      expect(calls, ['sessions:1', 'sessions:1']);
    });

    test('forced refreshes (push, tap) always fetch', () async {
      await coordinator.refreshSessions(1);
      await coordinator.refreshSession(1, 's1', force: true);
      expect(calls, ['sessions:1', 'sessions:1', 'plan:s1']);
    });

    test('throttle is per club and per session', () async {
      await coordinator.refreshSession(1, 's1');
      await coordinator.refreshSession(2, 's2');
      expect(calls, ['sessions:1', 'plan:s1', 'sessions:2', 'plan:s2']);
    });

    test(
      'a failing fetch is reported, not thrown, and not retried at once',
      () async {
        final errors = <Object>[];
        final failing = RefreshCoordinator(
          now: () => now,
          fetchSessions: (_) async => throw StateError('offline'),
          fetchPlan: (_) async {},
          onError: (e) async => errors.add(e),
        );
        await failing.refreshSessions(1);
        expect(await failing.refreshSessions(1), isFalse);
        expect(errors, hasLength(1));
      },
    );
  });
}
