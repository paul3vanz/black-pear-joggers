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
}
