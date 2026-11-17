import 'package:bpj/features/events/logic/event_place.dart';
import 'package:bpj/features/events/ui/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventPlace', () {
    test('uses the stored url, else builds the parkrun UK page', () {
      expect(
        const EventPlace(kind: 'race', url: 'https://x.org/r').pageUri,
        Uri.parse('https://x.org/r'),
      );
      expect(
        const EventPlace(kind: 'parkrun', slug: 'worcester').pageUri,
        Uri.parse('https://www.parkrun.org.uk/worcester/'),
      );
      expect(
        const EventPlace(kind: 'parkrun', slug: 'x', country: 'AU').pageUri,
        isNull,
      );
      expect(const EventPlace(kind: 'race', slug: 'x').pageUri, isNull);
      expect(
        const EventPlace(kind: 'race', url: 'javascript:alert(1)').pageUri,
        isNull,
      );
    });

    test('region line and directions', () {
      const p = EventPlace(
        kind: 'parkrun',
        country: 'GB',
        region: 'Worcestershire',
        lat: 52.19,
        lng: -2.22,
      );
      expect(p.regionLine, 'Worcestershire, United Kingdom');
      expect(p.directionsUri.toString(), contains('destination=52.19%2C-2.22'));
      const none = EventPlace(kind: 'other');
      expect(none.hasDetails, isFalse);
      expect(none.directionsUri, isNull);
    });
  });

  testWidgets('card expands to links that open externally', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventCard(
            title: 'Worcester parkrun',
            going: 1,
            place: const EventPlace(
              kind: 'parkrun',
              slug: 'worcester',
              country: 'GB',
              lat: 52.19,
              lng: -2.22,
            ),
            onOpenLink: opened.add,
          ),
        ),
      ),
    );
    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('parkrun page'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('event-details-toggle')));
    await tester.pump();
    await tester.tap(find.text('parkrun page'));
    await tester.tap(find.text('Open in Maps'));
    expect(opened.length, 2);
    expect(opened.first.host, 'www.parkrun.org.uk');
    expect(opened.last.host, 'www.google.com');
  });
}
