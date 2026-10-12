import 'package:bpj/core/notifications/notification_routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const known = {'user|a', 'user|b'};

  TapDecision decide(
    Map<String, Object?> data, {
    String? activeSub = 'user|a',
    int? activeClubId = 1,
    Set<String> knownSubs = known,
  }) => decideTapRoute(
    data: data,
    activeSub: activeSub,
    activeClubId: activeClubId,
    knownSubs: knownSubs,
  );

  test('same account and club: just go to the route', () {
    expect(
      decide({'userId': 'user|a', 'clubId': '1', 'route': '/updates/p1'}),
      const TapDecision(route: '/updates/p1'),
    );
  });

  test('another account on the device: switch account (and set its club)', () {
    expect(
      decide({'userId': 'user|b', 'clubId': '1', 'route': '/updates/p1'}),
      const TapDecision(
        switchToSub: 'user|b',
        setClubId: 1,
        route: '/updates/p1',
      ),
    );
  });

  test('another club: switch club only', () {
    expect(
      decide({'userId': 'user|a', 'clubId': '2', 'route': '/inbox'}),
      const TapDecision(setClubId: 2, route: '/inbox'),
    );
  });

  test('missing or non-local route falls back to /inbox', () {
    expect(decide({'userId': 'user|a'}).route, '/inbox');
    expect(
      decide({'userId': 'user|a', 'route': 'https://evil.example'}).route,
      '/inbox',
    );
  });

  test('account not on this device: no switching, open the inbox', () {
    expect(
      decide({'userId': 'user|zzz', 'clubId': '2', 'route': '/updates/p1'}),
      const TapDecision(route: '/inbox'),
    );
  });

  group('group chat pushes', () {
    const chatRoute = '/runs/s1/groups/g1/chat';
    final chatPush = <String, Object?>{
      'userId': 'user|a',
      'clubId': '1',
      'route': chatRoute,
      'sessionId': 's1',
      'groupId': 'g1',
      'category': 'group_messages',
    };

    test('a tap goes straight to the chat route', () {
      expect(decide(chatPush), const TapDecision(route: chatRoute));
    });

    test('a tap for another account switches first, then opens the chat', () {
      expect(
        decide({...chatPush, 'userId': 'user|b'}),
        const TapDecision(
          switchToSub: 'user|b',
          setClubId: 1,
          route: chatRoute,
        ),
      );
    });

    test('a push for the open chat is not shown', () {
      expect(isForOpenChat(chatPush, 'g1', activeSub: 'user|a'), isTrue);
    });

    test('a push for another chat, or with no chat open, is shown', () {
      expect(isForOpenChat(chatPush, 'g2', activeSub: 'user|a'), isFalse);
      expect(isForOpenChat(chatPush, null, activeSub: 'user|a'), isFalse);
    });

    test('a push for another account is shown even for the open group', () {
      expect(
        isForOpenChat(
          {...chatPush, 'userId': 'user|b'},
          'g1',
          activeSub: 'user|a',
        ),
        isFalse,
      );
    });

    test('recognises group message pushes', () {
      expect(isGroupMessagePush(chatPush), isTrue);
      expect(isGroupMessagePush({'category': 'group_messages'}), isTrue);
      expect(isGroupMessagePush({'route': '/updates/p1'}), isFalse);
    });
  });
}
