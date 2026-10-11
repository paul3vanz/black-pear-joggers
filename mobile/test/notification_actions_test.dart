import 'dart:convert';

import 'package:bpj/core/notifications/notification_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, Object?> _push({
  String? actions = 'going,not_going',
  String? tag = 'reminder:s1',
}) => {
  'title': 'Tuesday run',
  'body': 'Are you coming?',
  'notificationId': 'n-1',
  'actionToken': 'abc123',
  'sessionId': 's1',
  'category': 'run_reminders',
  'route': '/runs/s1',
  'actions': ?actions,
  'tag': ?tag,
};

void main() {
  group('parseActionNotification', () {
    test('a data-only message with actions is an action notification', () {
      final n = parseActionNotification(_push(), hasNotificationBlock: false)!;
      expect(n.title, 'Tuesday run');
      expect(n.body, 'Are you coming?');
      expect(n.notificationId, 'n-1');
      expect(n.actionToken, 'abc123');
      expect(n.actions, ['going', 'not_going']);
      expect(n.category, 'run_reminders');
      expect(n.localId, localNotificationId('reminder:s1'));
    });

    test('a message with a notification block is left to the OS', () {
      expect(
        parseActionNotification(_push(), hasNotificationBlock: true),
        isNull,
      );
    });

    test('no actions, or only unknown ones, is not an action notification', () {
      expect(
        parseActionNotification(
          _push(actions: null),
          hasNotificationBlock: false,
        ),
        isNull,
      );
      expect(
        parseActionNotification(
          _push(actions: 'snooze'),
          hasNotificationBlock: false,
        ),
        isNull,
      );
    });

    test('parses a single action and ignores unknown ones and spaces', () {
      final n = parseActionNotification(
        _push(actions: 'going, snooze'),
        hasNotificationBlock: false,
      )!;
      expect(n.actions, ['going']);
    });

    test('needs title, body, notification id and token', () {
      for (final key in ['title', 'body', 'notificationId', 'actionToken']) {
        final data = _push()..remove(key);
        expect(
          parseActionNotification(data, hasNotificationBlock: false),
          isNull,
          reason: 'missing $key',
        );
      }
    });

    test(
      'local id comes from the tag, falling back to the notification id',
      () {
        final withTag = parseActionNotification(
          _push(),
          hasNotificationBlock: false,
        )!;
        final noTag = parseActionNotification(
          _push(tag: null),
          hasNotificationBlock: false,
        )!;
        expect(noTag.localId, localNotificationId('n-1'));
        expect(withTag.localId, isNot(noTag.localId));
      },
    );
  });

  test('localNotificationId is stable and a positive 31-bit int', () {
    // Fixed values: the id must not change between runs or isolates.
    expect(
      localNotificationId('reminder:s1'),
      localNotificationId('reminder:s1'),
    );
    expect(localNotificationId(''), 0x811c9dc5 & 0x7fffffff);
    expect(localNotificationId('a'), 0xe40c292c & 0x7fffffff);
    expect(
      localNotificationId('some long dedupe key' * 5),
      inInclusiveRange(0, 0x7fffffff),
    );
  });

  group('postNotificationAction', () {
    Future<ActionOutcome> post(
      FakeAdapter adapter, {
      String action = 'going',
    }) => postNotificationAction(
      baseUrl: 'http://test.invalid',
      notificationId: 'n-1',
      token: 'abc123',
      action: action,
      dio: fakeDio(adapter),
    );

    test('200 sends the body and is a success', () async {
      final adapter = FakeAdapter({
        'POST /app/notification-actions': const FakeResponse(200, {
          'status': 'going',
          'sessionId': 's1',
        }),
      });
      expect(await post(adapter), ActionOutcome.sent);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(jsonEncode(request.data)), {
        'notificationId': 'n-1',
        'token': 'abc123',
        'action': 'going',
      });
    });

    test('404 and 409 mean the run has changed', () async {
      for (final status in [404, 409]) {
        final adapter = FakeAdapter({
          'POST /app/notification-actions': FakeResponse(status, {
            'error': 'not_found',
          }),
        });
        expect(await post(adapter), ActionOutcome.changed, reason: '$status');
      }
    });

    test('a network error or a server error is a failure', () async {
      expect(await post(FakeAdapter({})), ActionOutcome.failed);
      final adapter = FakeAdapter({
        'POST /app/notification-actions': const FakeResponse(500, {
          'error': 'x',
        }),
      });
      expect(await post(adapter), ActionOutcome.failed);
    });
  });

  test('confirmation text per outcome', () {
    expect(
      confirmationText('going', ActionOutcome.sent),
      "Thanks, you're down as coming",
    );
    expect(
      confirmationText('not_going', ActionOutcome.sent),
      "Thanks, we've noted you can't make it",
    );
    expect(
      confirmationText('going', ActionOutcome.changed),
      'That run has changed - open the app',
    );
    expect(
      confirmationText('going', ActionOutcome.failed),
      "Couldn't send - open the app to answer",
    );
  });

  test('decodePayload tolerates junk', () {
    expect(decodePayload(null), isEmpty);
    expect(decodePayload('nope'), isEmpty);
    expect(decodePayload('[1]'), isEmpty);
    expect(decodePayload('{"a":1}'), {'a': 1});
  });
}
