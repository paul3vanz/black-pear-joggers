import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/events/ui/event_locations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase8.dart';
import 'support/groups_test_support.dart';

const _path = '/app/clubs/1/event-locations';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final items = [
    eventLocationJson(
      'p1',
      name: 'Worcester parkrun',
      slug: 'worcester',
      region: 'Worcestershire',
    ),
    eventLocationJson('p2', name: 'Bromsgrove parkrun', slug: 'bromsgrove'),
    eventLocationJson(
      'r1',
      kind: 'race',
      name: 'Droitwich 10k',
      source: 'manual',
    ),
    eventLocationJson('o1', kind: 'other', name: 'Fell run', source: 'manual'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    List<String> roles = const ['committee'],
    Map<String, Object> routes = const {},
    bool online = true,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      routes: {
        if (online)
          'GET $_path': FakeResponse(200, eventLocationsResponse(items)),
        ...routes,
      },
    );
    await pumpGroupsApp(tester, db, adapter, const EventLocationsScreen());
  }

  Map<String, Object?> body(String method) =>
      (adapter.requests.lastWhere((r) => r.method == method).data
              as Map<Object?, Object?>)
          .cast<String, Object?>();

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
  }

  testWidgets('lists locations with the count and the import hint', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Bromsgrove parkrun'), findsOneWidget);
    expect(find.text('Droitwich 10k'), findsOneWidget);
    expect(find.text('4 locations'), findsOneWidget);
    expect(find.text(eventLocationsImportHint), findsOneWidget);
    // Name order, with the kind and region as the subtitle.
    expect(
      tester.getTopLeft(find.text('Bromsgrove parkrun')).dy,
      lessThan(tester.getTopLeft(find.text('Worcester parkrun')).dy),
    );
    expect(find.text('parkrun · Worcestershire'), findsOneWidget);
    expect(find.text('Race'), findsWidgets); // chip + row subtitle
    await unmount(tester);
  });

  testWidgets('search and kind chips filter the list', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'DROIT');
    await tester.pump();
    expect(find.text('Droitwich 10k'), findsOneWidget);
    expect(find.text('Worcester parkrun'), findsNothing);
    expect(find.text('Showing 1 of 4'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'parkrun'));
    await tester.pump();
    expect(find.text('Worcester parkrun'), findsOneWidget);
    expect(find.text('Droitwich 10k'), findsNothing);
    expect(find.text('Showing 2 of 4'), findsOneWidget);

    // Two kinds together; then clear the filter again.
    await tester.tap(find.widgetWithText(FilterChip, 'Other'));
    await tester.pump();
    expect(find.text('Fell run'), findsOneWidget);
    expect(find.text('Droitwich 10k'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'parkrun'));
    await tester.tap(find.widgetWithText(FilterChip, 'Other'));
    await tester.pump();
    expect(find.text('4 locations'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('members get a message and no list or add button', (
    tester,
  ) async {
    await pump(tester, roles: const []);
    expect(
      find.text('Only the committee can manage event locations.'),
      findsOneWidget,
    );
    expect(find.text('Add location'), findsNothing);
    expect(find.text('Worcester parkrun'), findsNothing);
    await unmount(tester);
  });

  testWidgets('add: posts a race location and closes the form', (tester) async {
    await pump(
      tester,
      routes: {
        'POST $_path': FakeResponse(
          201,
          eventLocationJson(
            'new',
            kind: 'race',
            name: 'Malvern Hills 10',
            region: 'Worcestershire',
            source: 'manual',
          ),
        ),
      },
    );
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Malvern Hills 10');
    await tester.enterText(field('Region (optional)'), 'Worcestershire');
    await tester.enterText(field('Latitude'), '52.1');
    await tester.enterText(field('Longitude'), '-2.3');
    await tester.enterText(
      field('Website (optional)'),
      'https://example.org/malvern',
    );
    await tapSave(tester);

    final sent = body('POST');
    expect(sent['kind'], 'race'); // the default for a new one
    expect(sent['name'], 'Malvern Hills 10');
    expect(sent['region'], 'Worcestershire');
    expect(sent['lat'], 52.1);
    expect(sent['lng'], -2.3);
    expect(sent['url'], 'https://example.org/malvern');
    expect(find.text('Location added'), findsOneWidget);
    expect(find.text('Add location'), findsOneWidget); // only the button
    expect(find.text('Malvern Hills 10'), findsOneWidget);
    expect(find.text('5 locations'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('add: the kind can be parkrun and empty fields send null', (
    tester,
  ) async {
    await pump(
      tester,
      routes: {
        'POST $_path': FakeResponse(
          201,
          eventLocationJson('new', name: 'Redditch parkrun'),
        ),
      },
    );
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Redditch parkrun');
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<String>),
        matching: find.text('parkrun'),
      ),
    );
    await tapSave(tester);
    final sent = body('POST');
    expect(sent['kind'], 'parkrun');
    expect(sent['region'], isNull);
    expect(sent['lat'], isNull);
    expect(sent['url'], isNull);
    await unmount(tester);
  });

  testWidgets('validation blocks a missing name, lone latitude, bad link', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Latitude'), '52.1');
    await tester.enterText(field('Website (optional)'), 'ftp://x.org');
    await tapSave(tester);
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter both latitude and longitude'), findsOneWidget);
    expect(find.textContaining('http:// or https://'), findsOneWidget);
    expect(sent(adapter, 'POST', _path), isEmpty);
    await unmount(tester);
  });

  testWidgets('edit: the form is filled in and PATCH sends the changes', (
    tester,
  ) async {
    await pump(
      tester,
      routes: {
        'PATCH $_path/p1': FakeResponse(
          200,
          eventLocationJson(
            'p1',
            name: 'Worcester Woods parkrun',
            slug: 'worcester',
            region: 'Worcestershire',
          ),
        ),
      },
    );
    await tester.tap(find.text('Worcester parkrun'));
    await tester.pumpAndSettle();
    expect(find.text('Edit location'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(field('Name')).controller!.text,
      'Worcester parkrun',
    );
    await tester.enterText(field('Name'), 'Worcester Woods parkrun');
    await tapSave(tester);
    final sent = body('PATCH');
    expect(sent['name'], 'Worcester Woods parkrun');
    expect(sent['kind'], 'parkrun');
    expect(sent['region'], 'Worcestershire');
    expect(find.text('Worcester Woods parkrun'), findsOneWidget);
    expect(find.text('Worcester parkrun'), findsNothing);
    await unmount(tester);
  });

  testWidgets('delete asks first and removes the row', (tester) async {
    await pump(tester, routes: {'DELETE $_path/r1': const FakeResponse(204)});
    await tester.tap(find.text('Droitwich 10k'));
    await tester.pumpAndSettle();

    // Keep: nothing is sent.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Droitwich 10k?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(adapter.requests.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(find.text('Location deleted'), findsOneWidget);
    expect(find.text('Droitwich 10k'), findsNothing);
    expect(find.text('3 locations'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a 403 from the server is explained and keeps the form', (
    tester,
  ) async {
    await pump(
      tester,
      routes: {
        'POST $_path': const FakeResponse(403, {
          'code': 'forbidden',
          'message': 'no',
        }),
      },
    );
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'X parkrun');
    await tapSave(tester);
    expect(find.text('Only the committee can do that.'), findsOneWidget);
    expect(find.text('Add location'), findsNWidgets(2)); // form title + button
    await unmount(tester);
  });

  testWidgets('offline writes say a connection is needed', (tester) async {
    await pump(tester, online: false);
    expect(find.text('No event locations yet.'), findsOneWidget);
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'X');
    await tapSave(tester);
    expect(find.text('You need a connection to do that.'), findsOneWidget);
    await unmount(tester);
  });
}
