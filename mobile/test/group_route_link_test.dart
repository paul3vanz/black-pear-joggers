import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/ui/group_card.dart';
import 'package:bpj/features/groups/ui/group_format.dart';
import 'package:bpj/features/groups/ui/groups_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = 'https://www.plotaroute.com/route/403075';

void main() {
  test('routeUrl survives JSON and copyWith', () {
    final g = Group.fromJson({'id': 'g1', 'routeUrl': _url});
    expect(g.routeUrl, _url);
    expect(Group.fromJson(g.toJson()).routeUrl, _url);
    expect(g.copyWith(goingCount: 3).routeUrl, _url);
    expect(Group.fromJson({'id': 'g1', 'routeUrl': ''}).routeUrl, isNull);
  });

  test('only http(s) links are valid routes', () {
    expect(routeUri(_url), isNotNull);
    expect(routeUri('http://example.com/a.gpx'), isNotNull);
    expect(routeUri('  $_url  '), isNotNull);
    expect(routeUri('javascript:alert(1)'), isNull);
    expect(routeUri('plotaroute.com/route/1'), isNull);
    expect(routeUri(null), isNull);
    expect(checkRouteUrl(''), isNull);
    expect(checkRouteUrl(_url), isNull);
    expect(checkRouteUrl('not a link'), isNotNull);
  });

  testWidgets('the card shows View route only when a handler is given', (
    tester,
  ) async {
    var opened = 0;
    Future<void> pump(VoidCallback? onOpenRoute) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupCard(
            group: Group.fromJson({'id': 'g1', 'label': 'Route A'}),
            units: const UnitPrefs(),
            onOpenRoute: onOpenRoute,
          ),
        ),
      ),
    );

    await pump(null);
    expect(find.text('View route'), findsNothing);

    await pump(() => opened++);
    await tester.tap(find.text('View route'));
    expect(opened, 1);
  });
}
