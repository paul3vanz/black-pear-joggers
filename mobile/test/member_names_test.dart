import 'dart:convert';
import 'dart:typed_data';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/data/plan_dtos.dart';
import 'package:bpj/features/groups/ui/attendee_list.dart';
import 'package:bpj/features/groups/ui/group_card.dart';
import 'package:bpj/features/groups/ui/groups_providers.dart';
import 'package:bpj/features/members/ui/member_avatar.dart';
import 'package:bpj/features/members/ui/member_providers.dart';
import 'package:bpj/features/messages/ui/chat_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api_phase4.dart';

// Phase 6.5c: avatars and tappable names on the group card, attendee rows and
// chat bubbles. (The run page coordinator row is in session_detail_screen_test,
// committee lists in members_roles_test.)

final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

const _photoKey = ValueKey('member-avatar-photo');

MemberCard _card(String id, {String? photoPath}) => MemberCard(
  memberId: id,
  clubId: 1,
  displayName: id,
  photoPath: photoPath,
  rolesCsv: '',
  hasBio: false,
);

GroupMessage _msg(
  String id,
  String memberId,
  String name, {
  DateTime? at,
  String role = 'member',
  String sendState = 'sent',
}) => GroupMessage(
  id: id,
  clubId: 1,
  groupId: 'g1',
  memberId: memberId,
  authorName: name,
  authorRole: role,
  body: 'body $id',
  createdAt: at ?? DateTime(2026, 10, 7, 10),
  sendState: sendState,
);

void main() {
  /// Pumps [child] at [width] px under a router with a profile route.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 400,
    Map<String, MemberCard> cards = const {},
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              Scaffold(body: SingleChildScrollView(child: child)),
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
        overrides: [
          memberCardsProvider.overrideWith((ref) => Stream.value(cards)),
          avatarImageFactoryProvider.overrideWithValue(
            (url) => MemoryImage(_png),
          ),
          memberPhotoUrlProvider.overrideWithValue(
            (path) => path == null ? null : 'https://img.test$path',
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    // Let the in-memory photo decode (real async, like member_avatar_test).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNameAndBack(
    WidgetTester tester,
    String name,
    String id,
  ) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(find.text('Profile $id'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Profile $id'), findsNothing);
    expect(find.text(name), findsOneWidget);
  }

  group('group card leaders', () {
    Group group(List<Map<String, Object?>> leaders) =>
        Group.fromJson(groupJson('g', leaders: leaders));

    Widget card(Group g) => GroupCard(group: g, units: const UnitPrefs());

    testWidgets('avatars with photo and initials, role tag kept', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          group([
            leaderJson('sam', name: 'Sam B.'),
            leaderJson('pat', name: 'Pat C.', role: 'co_leader'),
          ]),
        ),
        cards: {'sam': _card('sam', photoPath: '/p/sam')},
      );
      expect(find.text('Led by'), findsOneWidget);
      expect(find.text('Sam B.'), findsOneWidget);
      expect(find.text('Pat C.'), findsOneWidget);
      expect(find.text('(co-leader)'), findsOneWidget);
      // Sam has a photo; Pat shows initials.
      expect(find.byKey(_photoKey), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MemberAvatar).first),
        const Size(24, 24),
      );
    });

    testWidgets('tapping a leader pushes the profile and Back returns', (
      tester,
    ) async {
      await pump(tester, card(group([leaderJson('sam', name: 'Sam B.')])));
      await tapNameAndBack(tester, 'Sam B.', 'sam');
    });

    testWidgets('a leader with no member id is plain, not tappable', (
      tester,
    ) async {
      await pump(tester, card(group([leaderJson('', name: 'Sam B.')])));
      expect(find.text('Sam B.'), findsOneWidget);
      await tester.tap(find.text('Sam B.'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Profile'), findsNothing);
    });

    testWidgets('no leaders: plain "No leader yet"', (tester) async {
      await pump(tester, card(group([])));
      expect(find.text('No leader yet'), findsOneWidget);
      expect(find.byType(MemberAvatar), findsNothing);
    });

    testWidgets('three leaders wrap on a 320 px phone without overflow', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          group([
            leaderJson('a', name: 'Alexandra Featherstone'),
            leaderJson('b', name: 'Bartholomew Smythe', role: 'co_leader'),
            leaderJson('c', name: 'Cassandra Pemberton', role: 'backmarker'),
          ]),
        ),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Alexandra Featherstone'), findsOneWidget);
      // The backmarker is not on the card (the who's-going list shows them).
      expect(find.text('Cassandra Pemberton'), findsNothing);
    });

    testWidgets('leader first, then co-leader, whatever order they arrive in', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          group([
            leaderJson('c', name: 'Cy Co', role: 'co_leader'),
            leaderJson('b', name: 'Bea Back', role: 'backmarker'),
            leaderJson('l', name: 'Lee Lead'),
          ]),
        ),
      );
      expect(find.text('Bea Back'), findsNothing);
      expect(find.text('(backmarker)'), findsNothing);
      expect(find.text('(co-leader)'), findsOneWidget);
      // Reading order (the line can wrap on a narrow card).
      double order(String name) {
        final p = tester.getTopLeft(find.text(name));
        return p.dy * 10000 + p.dx;
      }

      expect(order('Lee Lead'), lessThan(order('Cy Co')));
    });
  });

  group('attendee rows', () {
    PlanAttendee attendee(String id, String name, {String status = 'going'}) =>
        PlanAttendee(
          memberId: id,
          displayName: name,
          status: status,
          paceUnit: 'mi',
          paceFromS: 540,
          paceToS: 600,
        );

    Widget list(List<PlanAttendee> a) =>
        AttendeeList(attendees: a, units: const UnitPrefs());

    testWidgets('avatar + name + pace, tap opens the profile', (tester) async {
      await pump(
        tester,
        list([attendee('sam', 'Sam B.'), attendee('pat', 'Pat C.')]),
        cards: {'sam': _card('sam', photoPath: '/p/sam')},
      );
      expect(find.byKey(_photoKey), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.text('9:00-10:00/mi'), findsNWidgets(2));
      await tapNameAndBack(tester, 'Pat C.', 'pat');
    });

    testWidgets('leaders sort first, with role tags (backmarkers show here)', (
      tester,
    ) async {
      await pump(
        tester,
        AttendeeList(
          attendees: [
            attendee('sam', 'Sam B.'),
            attendee('bea', 'Bea K.'),
            attendee('lee', 'Lee L.'),
          ],
          units: const UnitPrefs(),
          roles: const {'bea': 'backmarker', 'lee': 'leader'},
        ),
      );
      expect(find.text('(backmarker)'), findsOneWidget);
      // A plain leader has no tag.
      expect(find.text('(leader)'), findsNothing);
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('Lee L.'), lessThan(y('Bea K.')));
      expect(y('Bea K.'), lessThan(y('Sam B.')));
    });

    testWidgets('maybe label stays; no id is not tappable', (tester) async {
      await pump(tester, list([attendee('', 'Sam B.', status: 'maybe')]));
      expect(find.text('maybe'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('a long name and pace fit on a 320 px phone', (tester) async {
      await pump(
        tester,
        list([
          attendee(
            'a',
            'Bartholomew Featherstonehaugh-Smythe',
            status: 'maybe',
          ),
        ]),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('maybe'), findsOneWidget);
    });
  });

  group('chat bubbles', () {
    testWidgets('others: avatar (when shown) and a tappable author name', (
      tester,
    ) async {
      await pump(
        tester,
        MessageBubble(
          message: _msg('m1', 'sam', 'Sam B.', role: 'leader'),
          isMine: false,
          showAvatar: true,
        ),
        cards: {'sam': _card('sam', photoPath: '/p/sam')},
      );
      expect(find.byKey(const ValueKey('message-avatar-m1')), findsOneWidget);
      expect(find.byKey(_photoKey), findsOneWidget);
      expect(find.text('Leader'), findsOneWidget);
      await tapNameAndBack(tester, 'Sam B.', 'sam');
    });

    testWidgets('no avatar when showAvatar is false, bubbles line up', (
      tester,
    ) async {
      await pump(
        tester,
        Column(
          children: [
            MessageBubble(message: _msg('m1', 'sam', 'Sam B.'), isMine: false),
            MessageBubble(
              message: _msg('m2', 'sam', 'Sam B.'),
              isMine: false,
              showAvatar: true,
            ),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('message-avatar-m1')), findsNothing);
      expect(find.byKey(const ValueKey('message-avatar-m2')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('message-m1'))).dx,
        tester.getTopLeft(find.byKey(const ValueKey('message-m2'))).dx,
      );
    });

    testWidgets('own messages: no avatar, no name', (tester) async {
      await pump(
        tester,
        MessageBubble(
          message: _msg('m1', 'me', 'Jo B.'),
          isMine: true,
          showAvatar: true,
        ),
      );
      expect(find.byType(MemberAvatar), findsNothing);
      expect(find.text('Jo B.'), findsNothing);
    });

    testWidgets('pending and failed bubbles keep their status text', (
      tester,
    ) async {
      await pump(
        tester,
        Column(
          children: [
            MessageBubble(
              message: _msg('m1', 'sam', 'Sam B.', sendState: 'pending'),
              isMine: false,
              showAvatar: true,
            ),
            MessageBubble(
              message: _msg('m2', 'sam', 'Sam B.', sendState: 'failed'),
              isMine: false,
              showAvatar: true,
            ),
          ],
        ),
      );
      expect(find.text('Sending...'), findsOneWidget);
      expect(find.text('Failed - tap to retry or delete'), findsOneWidget);
    });

    testWidgets('a bubble fits a 320 px phone with a long name', (
      tester,
    ) async {
      await pump(
        tester,
        MessageBubble(
          message: _msg(
            'm1',
            'a',
            'Bartholomew Featherstonehaugh',
            role: 'committee',
          ),
          isMine: false,
          showAvatar: true,
        ),
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });

    test('endsAuthorRun: last of a run shows the avatar', () {
      final day1 = DateTime(2026, 10, 6, 12);
      final day2 = DateTime(2026, 10, 7, 10);
      final items = chatItems([
        _msg('a1', 'sam', 'Sam', at: day1),
        _msg('a2', 'sam', 'Sam', at: day2),
        _msg('a3', 'sam', 'Sam', at: day2.add(const Duration(minutes: 1))),
        _msg('b1', 'pat', 'Pat', at: day2.add(const Duration(minutes: 2))),
        _msg('c1', '', 'Kim', at: day2.add(const Duration(minutes: 3))),
        _msg('c2', '', 'Kim', at: day2.add(const Duration(minutes: 4))),
      ], day2);
      final shown = <String>[
        for (var i = 0; i < items.length; i++)
          if (items[i] is MessageItem && endsAuthorRun(items, i))
            (items[i] as MessageItem).message.id,
      ];
      // a1 ends day 1's run (a day heading follows); a3 ends sam's run; b1 is
      // alone; unknown authors (no id) always show one.
      expect(shown, unorderedEquals(['a1', 'a3', 'b1', 'c1', 'c2']));
    });
  });
}
