import 'dart:convert';
import 'dart:typed_data';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/members/ui/member_avatar.dart';
import 'package:bpj/features/members/ui/member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A valid 1x1 PNG, decoded for real by the test engine (no network).
final _pngBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

/// An image that always fails to load (a dead link).
class _BrokenImage extends ImageProvider<_BrokenImage> {
  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration c) => Future.value(this);

  @override
  ImageStreamCompleter loadImage(
    _BrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Future.error(Exception('404')));
}

ImageProvider _fakeImage(String url) =>
    url.contains('broken') ? _BrokenImage() : MemoryImage(_pngBytes);

MemberCard _card(String id, {String name = 'Sam B.', String? photoPath}) =>
    MemberCard(
      memberId: id,
      clubId: 1,
      displayName: name,
      photoPath: photoPath,
      rolesCsv: '',
      hasBio: false,
    );

const _photoKey = ValueKey('member-avatar-photo');

void main() {
  Future<void> settleReal(WidgetTester tester) async {
    await tester.pumpAndSettle(); // the card arrives, the image starts loading
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  List<Override> overrides(Map<String, MemberCard> cards) => [
    memberCardsProvider.overrideWith((ref) => Stream.value(cards)),
    avatarImageFactoryProvider.overrideWithValue(_fakeImage),
    memberPhotoUrlProvider.overrideWithValue(
      (path) => path == null ? null : 'https://img.test$path',
    ),
  ];

  test('initialsOf', () {
    expect(initialsOf('Sam B.'), 'SB');
    expect(initialsOf('Sam'), 'S');
    expect(initialsOf('  sam   b. '), 'SB');
    expect(initialsOf('Mary Ann Smith'), 'MS');
    expect(initialsOf(''), '?');
    expect(initialsOf(' . '), '?');
  });

  group('MemberAvatar', () {
    Future<void> pump(
      WidgetTester tester,
      Map<String, MemberCard> cards, {
      String? memberId = 'sam',
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(cards),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MemberAvatar(memberId: memberId, name: 'Sam B.'),
              ),
            ),
          ),
        ),
      );
      await settleReal(tester);
    }

    testWidgets('shows the cached photo when the card has one', (tester) async {
      await pump(tester, {'sam': _card('sam', photoPath: '/app/photo')});
      expect(find.byKey(_photoKey), findsOneWidget);
      expect(tester.getSize(find.byType(MemberAvatar)), const Size(28, 28));
    });

    testWidgets('falls back to initials without a photo', (tester) async {
      await pump(tester, {'sam': _card('sam')});
      expect(find.byKey(_photoKey), findsNothing);
      expect(find.text('SB'), findsOneWidget);
    });

    testWidgets('initials for a member with no card, or no id', (tester) async {
      await pump(tester, {});
      expect(find.byKey(_photoKey), findsNothing);
      expect(find.text('SB'), findsOneWidget);
      await pump(tester, {
        'sam': _card('sam', photoPath: '/a'),
      }, memberId: null);
      expect(find.byKey(_photoKey), findsNothing);
    });

    testWidgets('a photo that fails to load leaves the initials', (
      tester,
    ) async {
      await pump(tester, {'sam': _card('sam', photoPath: '/broken')});
      expect(find.byKey(_photoKey), findsNothing);
      expect(find.text('SB'), findsOneWidget);
    });

    testWidgets('size is configurable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides({}),
          child: const MaterialApp(
            home: Center(
              child: MemberAvatar(memberId: 'x', name: 'Kim L.', size: 120),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(MemberAvatar)), const Size(120, 120));
    });
  });

  group('MemberLink', () {
    Future<GoRouter> pump(WidgetTester tester, {String? memberId}) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: Center(
                child: MemberLink(memberId: memberId, name: 'Sam B.'),
              ),
            ),
          ),
          GoRoute(
            path: '/members/:memberId',
            builder: (_, state) => Scaffold(
              appBar: AppBar(),
              body: Text('Profile ${state.pathParameters['memberId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides({}),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('tap pushes the profile and Back returns', (tester) async {
      await pump(tester, memberId: 'sam');
      expect(find.text('Sam B.'), findsOneWidget);
      await tester.tap(find.text('Sam B.'));
      await tester.pumpAndSettle();
      expect(find.text('Profile sam'), findsOneWidget);
      // A push: the back arrow is there, and it returns to the origin.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Profile sam'), findsNothing);
      expect(find.text('Sam B.'), findsOneWidget);
    });

    testWidgets('no member id: plain avatar and text, no tap', (tester) async {
      await pump(tester);
      expect(find.text('Sam B.'), findsOneWidget);
      expect(find.text('SB'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      await tester.tap(find.text('Sam B.'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Profile'), findsNothing);
    });
  });
}
