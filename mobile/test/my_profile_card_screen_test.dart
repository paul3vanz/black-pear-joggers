import 'dart:convert';
import 'dart:typed_data';

import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/members/data/member_dtos.dart';
import 'package:bpj/features/members/data/member_profile_repository.dart';
import 'package:bpj/features/members/logic/profile_photo.dart';
import 'package:bpj/features/members/ui/member_avatar.dart';
import 'package:bpj/features/members/ui/member_providers.dart';
import 'package:bpj/features/members/ui/my_profile_card_screen.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase65.dart';

/// A valid 1x1 PNG, so the preview dialog can really decode it.
final _pngBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() {
    db = memoryDb();
    adapter = FakeAdapter({});
  });
  tearDown(() => db.close());

  const mineKey = 'GET /app/clubs/1/member-profile';
  const putKey = 'PUT /app/clubs/1/member-profile';
  const photoKey = 'PUT /app/clubs/1/member-profile/photo';
  const bioField = ValueKey('bio-field');
  const goalsField = ValueKey('goals-field');

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  var pickerCalls = <PhotoSource>[];

  Future<void> pump(
    WidgetTester tester, {
    PhotoPicker? picker,
    Future<Uint8List> Function(Uint8List)? processor,
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    pickerCalls = [];
    final dio = fakeDio(adapter);
    final router = GoRouter(
      initialLocation: '/profile/card',
      routes: [
        GoRoute(
          path: '/profile/card',
          builder: (_, _) => const MyProfileCardScreen(),
        ),
        GoRoute(
          path: '/members/:memberId',
          builder: (_, state) => Scaffold(
            body: Text('Profile ${state.pathParameters['memberId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileRepositoryProvider.overrideWithValue(
            MemberProfileRepository(db, dio),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          ownMemberIdProvider.overrideWithValue('me'),
          activeMembershipProvider.overrideWithValue(null),
          avatarImageFactoryProvider.overrideWithValue(
            (url) => MemoryImage(_pngBytes),
          ),
          photoPickerProvider.overrideWithValue(
            picker ??
                (source) async {
                  pickerCalls.add(source);
                  return Uint8List.fromList([1, 2, 3]);
                },
          ),
          photoProcessorProvider.overrideWithValue(
            processor ?? (bytes) async => _pngBytes,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

  String text(WidgetTester tester, Key key) =>
      tester.widget<TextField>(find.byKey(key)).controller!.text;

  List<RequestOptions> writes() => adapter.requests
      .where((r) => r.method == 'PUT' || r.method == 'DELETE')
      .toList();

  void online({MyCard? card}) {
    adapter.routes[mineKey] = FakeResponse(
      200,
      myCardJson(
        bio: card?.bio ?? 'Hello there',
        goals: card?.goals ?? 'Run a marathon',
        goalsVisible: card?.goalsVisible ?? false,
        photoPath: card?.photoPath,
      ),
    );
    adapter.routes['GET /app/clubs/1/member-cards'] = FakeResponse(
      200,
      memberCardsBody([]),
    );
  }

  testWidgets(
    'shows the consent text and the saved card; Save starts disabled',
    (tester) async {
      online();
      await pump(tester);
      expect(
        find.text(
          'Your photo and bio are visible to other BPJ members in the app. '
          'Goals are private unless you share them.',
        ),
        findsOneWidget,
      );
      expect(text(tester, bioField), 'Hello there');
      expect(text(tester, goalsField), 'Run a marathon');
      expect(saveButton(tester).onPressed, isNull);
      expect(
        find.text('Only you can see your goals unless you tick this.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const ValueKey('share-goals')))
            .value,
        isFalse,
      );
      await unmount(tester);
    },
  );

  testWidgets('an unexpected response body shows an error, not a spinner', (
    tester,
  ) async {
    // e.g. a host that answers an unknown route with a bare "0".
    adapter.routes[mineKey] = FakeResponse(200, '0');
    adapter.routes['GET /app/clubs/1/member-cards'] = FakeResponse(
      200,
      memberCardsBody([]),
    );
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('editing the bio enables Save and sends only the bio', (
    tester,
  ) async {
    online();
    adapter.routes[putKey] = FakeResponse(
      200,
      myCardJson(bio: 'Updated bio', goals: 'Run a marathon'),
    );
    await pump(tester);
    await tester.enterText(find.byKey(bioField), 'Updated bio');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    final put = writes().single;
    expect(put.method, 'PUT');
    expect(put.data, {'bio': 'Updated bio'});
    expect(find.text('Saved'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
    await unmount(tester);
  });

  testWidgets('clearing the goals sends an empty string', (tester) async {
    online();
    adapter.routes[putKey] = FakeResponse(200, myCardJson(bio: 'Hello there'));
    await pump(tester);
    await tester.enterText(find.byKey(goalsField), '');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(writes().single.data, {'goals': ''});
    await unmount(tester);
  });

  testWidgets('ticking share-goals sends only goalsVisible', (tester) async {
    online();
    adapter.routes[putKey] = FakeResponse(
      200,
      myCardJson(
        bio: 'Hello there',
        goals: 'Run a marathon',
        goalsVisible: true,
      ),
    );
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('share-goals')));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(writes().single.data, {'goalsVisible': true});
    // Unticking again is a change from the saved state.
    await tester.tap(find.byKey(const ValueKey('share-goals')));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('character limits and counters: bio 300, goals 1000', (
    tester,
  ) async {
    online();
    await pump(tester);
    await tester.enterText(find.byKey(bioField), 'a' * 400);
    await tester.enterText(find.byKey(goalsField), 'b' * 1200);
    await tester.pump();
    expect(text(tester, bioField).length, 300);
    expect(text(tester, goalsField).length, 1000);
    expect(find.text('300/300'), findsOneWidget);
    expect(find.text('1000/1000'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a 422 shows the message under the field', (tester) async {
    online();
    adapter.routes[putKey] = FakeResponse(
      422,
      validationBody('bio', 'Keep it shorter.'),
    );
    await pump(tester);
    await tester.enterText(find.byKey(bioField), 'x');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(find.text('Keep it shorter.'), findsOneWidget);
    // Typing clears the error again.
    await tester.enterText(find.byKey(bioField), 'xy');
    await tester.pump();
    expect(find.text('Keep it shorter.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('choosing a photo previews it and uploads multipart', (
    tester,
  ) async {
    online();
    adapter.routes[photoKey] = FakeResponse(
      200,
      myCardJson(bio: 'Hello there', photoPath: photoPathJson),
    );
    await pump(tester);
    await tester.tap(find.text('Choose photo'));
    await tester.pumpAndSettle();
    expect(pickerCalls, [PhotoSource.gallery]);
    expect(find.text('Use this photo?'), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-preview')), findsOneWidget);
    await tester.tap(find.text('Use photo'));
    await settle(tester);

    final upload = writes().single;
    expect(upload.path, '/app/clubs/1/member-profile/photo');
    final form = upload.data as FormData;
    expect(form.files.single.key, 'photo');
    expect(form.files.single.value.filename, 'photo.jpg');
    expect(find.text('Photo saved'), findsOneWidget);
    // The card now has a photo, so Remove photo is offered.
    expect(find.text('Remove photo'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'take photo uses the camera; cancelling the preview uploads nothing',
    (tester) async {
      online();
      await pump(tester);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(pickerCalls, [PhotoSource.camera]);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(writes(), isEmpty);
      await unmount(tester);
    },
  );

  testWidgets('a cancelled picker does nothing', (tester) async {
    online();
    await pump(tester, picker: (_) async => null);
    await tester.tap(find.text('Choose photo'));
    await settle(tester);
    expect(find.text('Use this photo?'), findsNothing);
    expect(writes(), isEmpty);
    await unmount(tester);
  });

  testWidgets('a photo that cannot be used shows the reason', (tester) async {
    online();
    await pump(
      tester,
      processor: (_) =>
          throw const ProfilePhotoException('That photo is too small.'),
    );
    await tester.tap(find.text('Choose photo'));
    await settle(tester);
    expect(find.text('That photo is too small.'), findsOneWidget);
    expect(writes(), isEmpty);
    await unmount(tester);
  });

  testWidgets('a denied camera permission explains what to do', (tester) async {
    online();
    await pump(
      tester,
      picker: (_) => throw PlatformException(code: 'camera_access_denied'),
    );
    await tester.tap(find.text('Take photo'));
    await settle(tester);
    expect(find.textContaining('camera permission'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Remove photo is only offered with a photo and deletes it', (
    tester,
  ) async {
    online(
      card: const MyCard(
        bio: 'Hello there',
        goals: 'Run a marathon',
        photoPath: photoPathJson,
      ),
    );
    adapter.routes['DELETE /app/clubs/1/member-profile/photo'] = FakeResponse(
      200,
      myCardJson(bio: 'Hello there', goals: 'Run a marathon'),
    );
    await pump(tester);
    await tester.tap(find.text('Remove photo'));
    await settle(tester);
    expect(writes().single.method, 'DELETE');
    expect(find.text('Photo removed'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);
    await unmount(tester);
  });

  testWidgets('no Remove photo button without a photo', (tester) async {
    online();
    await pump(tester);
    expect(find.text('Remove photo'), findsNothing);
    await unmount(tester);
  });

  testWidgets('See how others see me opens your own profile page', (
    tester,
  ) async {
    online();
    await pump(tester);
    await tester.tap(find.text('See how others see me'));
    await tester.pumpAndSettle();
    expect(find.text('Profile me'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('offline: shows the cached card, saving explains the problem', (
    tester,
  ) async {
    online();
    final dio = fakeDio(adapter);
    await tester.runAsync(() => MemberProfileRepository(db, dio).fetchMine(1));
    adapter.routes.clear(); // now offline
    await pump(tester);
    expect(text(tester, bioField), 'Hello there');
    expect(
      find.textContaining('Offline: showing your last saved card'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(bioField), 'Edited offline');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(find.text('You need a connection to do that.'), findsOneWidget);
    // The edit is kept so it can be saved later.
    expect(text(tester, bioField), 'Edited offline');
    await unmount(tester);
  });

  testWidgets('offline with nothing cached shows a message and retry', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining("You're offline"), findsOneWidget);
    online();
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(text(tester, bioField), 'Hello there');
    await unmount(tester);
  });
}
