import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:typed_data';

import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/runs/data/run_dtos.dart';
import 'package:bpj/features/runs/data/follows_repository.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/runs/ui/runs_screen.dart';
import 'package:bpj/features/runs/ui/series_image.dart';
import 'package:bpj/features/runs/ui/series_screens.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:bpj/features/runs/ui/session_edit_screen.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';
import 'support/groups_test_support.dart';

/// A valid 1x1 PNG, decoded for real by the test engine (no network).
final _pngBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

/// An image that always fails to load (a dead link).
class _BrokenImage extends ImageProvider<_BrokenImage> {
  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration c) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _BrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Future.error(Exception('404')));
}

/// Images whose URL contains "broken" fail, everything else is the 1x1 PNG.
ImageProvider _fakeImage(String url) =>
    url.contains('broken') ? _BrokenImage() : MemoryImage(_pngBytes);

final _imageOverride = seriesImageFactoryProvider.overrideWithValue(_fakeImage);

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  String day(int offset) =>
      localDateString(DateTime.now().add(Duration(days: offset)));

  // Works around Drift's stream-cleanup timer outliving the test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> settleReal(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  group('parsing nullable fields', () {
    test('a run with no end time keeps endsAt as start + 3 h', () {
      final dto = SessionDto.fromJson(
        sessionJson('a', localDate: '2026-10-12', end: null),
      );
      expect(dto.localEndTime, isNull);
      expect(dto.endsAt, dto.startsAt.add(const Duration(hours: 3)));
      expect(dto.imageUrl, isNull);
    });

    test('a run with an end time and image keeps both', () {
      final dto = SessionDto.fromJson(
        sessionJson(
          'a',
          localDate: '2026-10-12',
          imageUrl: 'https://bpj.org.uk/a.jpg',
        ),
      );
      expect(dto.localEndTime, '20:30');
      expect(dto.imageUrl, 'https://bpj.org.uk/a.jpg');
      expect(dto.endsAt, DateTime.utc(2026, 10, 12, 19, 30));
    });

    test('an empty localEndTime counts as no end', () {
      final dto = SessionDto.fromJson({
        ...sessionJson('a', localDate: '2026-10-12'),
        'localEndTime': '',
      });
      expect(dto.localEndTime, isNull);
    });

    test('series durationMin and imageUrl are nullable and stored', () async {
      final dto = SeriesDto.fromJson(seriesJson('s1', durationMin: null));
      expect(dto.durationMin, isNull);
      expect(dto.imageUrl, isNull);
      await db.into(db.sessionSeries).insert(dto.toCompanion(1));
      final row = await db.select(db.sessionSeries).getSingle();
      expect(row.durationMin, isNull);

      final withImage = SeriesDto.fromJson(
        seriesJson('s2', imageUrl: 'https://bpj.org.uk/b.jpg'),
      );
      expect(withImage.durationMin, 90);
      expect(withImage.imageUrl, 'https://bpj.org.uk/b.jpg');
    });
  });

  group('Runs list', () {
    Future<void> pumpRuns(WidgetTester tester) async {
      final adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
        'GET /app/clubs/1/sessions': FakeResponse(200, {
          'items': [
            sessionJson(
              'a',
              localDate: day(1),
              title: 'With end and image',
              imageUrl: 'https://bpj.org.uk/ok.jpg',
            ),
            sessionJson('b', localDate: day(2), title: 'No end', end: null),
            sessionJson(
              'c',
              localDate: day(3),
              title: 'Broken image',
              start: '11:00',
              end: '13:00',
              imageUrl: 'https://bpj.org.uk/broken.jpg',
            ),
          ],
          'serverTime': '2026-10-07T12:00:00.000Z',
        }),
        'GET /app/clubs/1/venues': FakeResponse(200, {
          'items': [venueJson('v1')],
          'serverTime': '2026-10-07T12:00:00.000Z',
        }),
        'GET /app/clubs/1/series': FakeResponse(200, {
          'items': [seriesJson('s1')],
          'serverTime': '2026-10-07T12:00:00.000Z',
        }),
      });
      final dio = fakeDio(adapter);
      await tester.runAsync(
        () => MembershipRepository(
          db,
          dio,
        ).link(1, urn: 1, dob: DateTime(1990, 1, 1)),
      );
      tallSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _imageOverride,
            appDatabaseProvider.overrideWithValue(db),
            runPreferencesRepositoryProvider.overrideWithValue(
              RunPreferencesRepository(db, dio),
            ),
            membershipRepositoryProvider.overrideWithValue(
              MembershipRepository(db, dio),
            ),
            followsRepositoryProvider.overrideWithValue(
              FollowsRepository(db, dio),
            ),
            runsRepositoryProvider.overrideWithValue(RunsRepository(db, dio)),
            messagesRepositoryProvider.overrideWithValue(
              MessagesRepository(db, dio),
            ),
            activeClubIdProvider.overrideWithValue(1),
            activeSubProvider.overrideWithValue('test|sub'),
          ],
          child: const MaterialApp(home: RunsScreen()),
        ),
      );
      await settleReal(tester);
    }

    Finder cardOf(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(Card));

    testWidgets(
      'shows 12-hour times, and only the start when there is no end',
      (tester) async {
        await pumpRuns(tester);
        expect(find.text('7-8:30pm'), findsOneWidget); // run a
        expect(find.text('7pm'), findsOneWidget); // run b: start only
        expect(find.text('11am-1pm'), findsOneWidget); // run c
        expect(find.textContaining('19:00'), findsNothing);
        expect(find.textContaining('–'), findsNothing);
        await unmount(tester);
      },
    );

    testWidgets('shows the banner only for a run whose image loaded', (
      tester,
    ) async {
      await pumpRuns(tester);
      // One banner (run a): half height, as wide as the card.
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.descendant(
          of: cardOf('With end and image'),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      final image = tester.getSize(find.byType(Image));
      expect(image.height, runCardImageHeight);
      expect(image.width, tester.getSize(cardOf('With end and image')).width);

      // No image: nothing. Broken image: nothing either (no error icon).
      for (final title in ['No end', 'Broken image']) {
        expect(
          find.descendant(of: cardOf(title), matching: find.byType(Image)),
          findsNothing,
        );
      }
      expect(find.byIcon(Icons.broken_image), findsNothing);
      // A failing image takes no space: the card is as tall as one with no image.
      expect(
        tester.getSize(cardOf('Broken image')).height,
        tester.getSize(cardOf('No end')).height,
      );
      await unmount(tester);
    });
  });

  group('Run detail', () {
    Future<void> pumpDetail(
      WidgetTester tester, {
      String? end,
      String? imageUrl,
    }) async {
      final adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
      });
      final dio = fakeDio(adapter);
      await tester.runAsync(() async {
        await MembershipRepository(
          db,
          dio,
        ).link(1, urn: 1, dob: DateTime(1990, 1, 1));
        await db
            .into(db.sessions)
            .insert(
              SessionDto.fromJson(
                sessionJson(
                  'a',
                  localDate: '2026-10-12',
                  end: end,
                  imageUrl: imageUrl,
                ),
              ).toCompanion(1),
            );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_imageOverride, ...groupsOverrides(db, dio)],
          child: const MaterialApp(home: SessionDetailScreen(sessionId: 'a')),
        ),
      );
      await settleReal(tester);
    }

    testWidgets('start only and no image', (tester) async {
      await pumpDetail(tester);
      expect(find.text('Monday 12 October, 7pm'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await unmount(tester);
    });

    testWidgets('range and image at the top', (tester) async {
      await pumpDetail(
        tester,
        end: '20:30',
        imageUrl: 'https://bpj.org.uk/ok.jpg',
      );
      expect(find.text('Monday 12 October, 7-8:30pm'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // At the very top of the page content.
      expect(tester.getTopLeft(find.byType(Image)).dy, lessThan(80));
      await unmount(tester);
    });

    testWidgets('a broken image link shows nothing', (tester) async {
      await pumpDetail(
        tester,
        end: '20:30',
        imageUrl: 'https://bpj.org.uk/broken.jpg',
      );
      expect(find.byType(Image), findsNothing);
      expect(find.text('Monday 12 October, 7-8:30pm'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('image URL validation', () {
    test('empty is fine; http(s) only; at most 500 characters', () {
      expect(validateImageUrl(''), isNull);
      expect(validateImageUrl('  '), isNull);
      expect(validateImageUrl('https://bpj.org.uk/a.jpg'), isNull);
      expect(validateImageUrl('http://bpj.org.uk/a.jpg'), isNull);
      expect(validateImageUrl('ftp://bpj.org.uk/a.jpg'), isNotNull);
      expect(validateImageUrl('bpj.org.uk/a.jpg'), isNotNull);
      expect(validateImageUrl('https://'), isNotNull);
      expect(validateImageUrl('https://x.org/${'a' * 500}'), isNotNull);
    });
  });

  group('editors', () {
    late FakeAdapter adapter;

    Future<void> pumpEditor(
      WidgetTester tester,
      Widget editor, {
      Map<String, Object> routes = const {},
    }) async {
      adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
        'GET /app/clubs/1/sessions': FakeResponse(200, {
          'items': <Object>[],
          'serverTime': '2026-10-07T12:00:00.000Z',
        }),
        ...routes,
      });
      final dio = fakeDio(adapter);
      await tester.runAsync(
        () => MembershipRepository(
          db,
          dio,
        ).link(1, urn: 1, dob: DateTime(1990, 1, 1)),
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/edit', builder: (_, _) => editor),
        ],
      );
      tallSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_imageOverride, ...groupsOverrides(db, dio)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settleReal(tester);
      unawaited(router.push('/edit'));
      await settleReal(tester);
    }

    Map<String, Object?> lastBody(String method) =>
        (adapter.requests.lastWhere((r) => r.method == method).data!
                as Map<Object?, Object?>)
            .cast<String, Object?>();

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    Finder durationField() => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Duration (minutes)',
    );

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Save'));
      await settleReal(tester);
    }

    testWidgets('new series: 90 minutes by default, can be saved with no end', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        const SeriesEditScreen(),
        routes: {
          'POST /app/clubs/1/series': FakeResponse(
            201,
            seriesJson('new', durationMin: null),
          ),
        },
      );
      expect(tester.widget<TextField>(durationField()).controller!.text, '90');
      // The time field shows 12-hour time.
      expect(find.text('7pm'), findsOneWidget);

      await tester.enterText(field('Title'), 'Saturday social');
      await tester.tap(find.byTooltip('No end time'));
      await tester.pump();
      expect(tester.widget<TextField>(durationField()).controller!.text, '');

      await save(tester);
      final body = lastBody('POST');
      expect(body.containsKey('durationMin'), isTrue);
      expect(body['durationMin'], isNull);
      expect(body['imageUrl'], isNull);
      await unmount(tester);
    });

    testWidgets(
      'existing series: clearing the duration sends null, image URL is sent',
      (tester) async {
        await tester.runAsync(
          () => db
              .into(db.sessionSeries)
              .insert(SeriesDto.fromJson(seriesJson('s1')).toCompanion(1)),
        );
        await pumpEditor(
          tester,
          const SeriesEditScreen(seriesId: 's1'),
          routes: {
            'PATCH /app/clubs/1/series/s1': FakeResponse(
              200,
              seriesJson(
                's1',
                durationMin: null,
                imageUrl: 'https://bpj.org.uk/a.jpg',
              ),
            ),
          },
        );
        expect(
          tester.widget<TextField>(durationField()).controller!.text,
          '90',
        );
        await tester.tap(find.byTooltip('No end time'));
        await tester.pump();
        await tester.enterText(
          field('Image URL (optional)'),
          'https://bpj.org.uk/a.jpg',
        );
        await save(tester);
        final body = lastBody('PATCH');
        expect(body['durationMin'], isNull);
        expect(body['imageUrl'], 'https://bpj.org.uk/a.jpg');
        await unmount(tester);
      },
    );

    testWidgets('a bad duration or image URL blocks saving', (tester) async {
      await pumpEditor(tester, const SeriesEditScreen());
      await tester.enterText(field('Title'), 'Run');
      await tester.enterText(durationField(), '5');
      await tester.enterText(
        field('Image URL (optional)'),
        'ftp://example.com/x.png',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter 15 to 600 minutes'), findsOneWidget);
      expect(find.textContaining('http:// or https://'), findsOneWidget);
      expect(
        adapter.requests.where(
          (r) => r.method == 'POST' && r.path.endsWith('/series'),
        ),
        isEmpty,
      );
      await unmount(tester);
    });

    testWidgets('ad-hoc run: duration optional, saved as null', (tester) async {
      await pumpEditor(
        tester,
        const SessionEditScreen(),
        routes: {
          'POST /app/clubs/1/sessions': FakeResponse(
            201,
            sessionJson('x', localDate: day(1), seriesId: null, end: null),
          ),
        },
      );
      await tester.enterText(field('Title'), 'Pub run');
      await tester.enterText(durationField(), '');
      await save(tester);
      expect(lastBody('POST')['durationMin'], isNull);
      await unmount(tester);
    });

    testWidgets(
      'editing a run with no end shows an empty duration and keeps it empty',
      (tester) async {
        await tester.runAsync(() async {
          await db
              .into(db.sessions)
              .insert(
                SessionDto.fromJson(
                  sessionJson(
                    'a',
                    localDate: day(1),
                    seriesId: null,
                    end: null,
                  ),
                ).toCompanion(1),
              );
        });
        await pumpEditor(
          tester,
          const SessionEditScreen(sessionId: 'a'),
          routes: {
            'PATCH /app/clubs/1/sessions/a': FakeResponse(
              200,
              sessionJson('a', localDate: day(1), seriesId: null, end: null),
            ),
          },
        );
        expect(tester.widget<TextField>(durationField()).controller!.text, '');
        await save(tester);
        expect(lastBody('PATCH')['durationMin'], isNull);
        await unmount(tester);
      },
    );

    testWidgets('editing a run with an end: clearing it sends null', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await db
            .into(db.sessions)
            .insert(
              SessionDto.fromJson(
                sessionJson('a', localDate: day(1), seriesId: null),
              ).toCompanion(1),
            );
      });
      await pumpEditor(
        tester,
        const SessionEditScreen(sessionId: 'a'),
        routes: {
          'PATCH /app/clubs/1/sessions/a': FakeResponse(
            200,
            sessionJson('a', localDate: day(1), seriesId: null, end: null),
          ),
        },
      );
      expect(tester.widget<TextField>(durationField()).controller!.text, '90');
      await tester.tap(find.byTooltip('No end time'));
      await tester.pump();
      await save(tester);
      expect(lastBody('PATCH')['durationMin'], isNull);
      await unmount(tester);
    });
  });
}
