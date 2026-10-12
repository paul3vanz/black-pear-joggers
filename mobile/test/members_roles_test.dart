import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/ui/members_roles_screen.dart';
import 'package:bpj/features/groups/ui/roles_sheet.dart';
import 'package:bpj/features/members/ui/member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _members = '/app/clubs/1/members';
const _roles = '/app/clubs/1/members/m1/roles';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    List<String> roles = const ['committee'],
    String memberId = 'me',
    Map<String, Object> routes = const {},
    List<Map<String, Object?>>? items,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      memberId: memberId,
      routes: {
        'GET $_members': FakeResponse(
          200,
          membersListJson(
            items ??
                [
                  memberItemJson('m1', 'Sam Lead', roles: ['leader']),
                  memberItemJson('m2', 'Pat Lapsed', status: 'lapsed'),
                ],
          ),
        ),
        ...routes,
      },
    );
    await pumpGroupsApp(tester, db, adapter, const MembersRolesScreen());
  }

  Finder sw(String title) => find.widgetWithText(SwitchListTile, title);

  bool enabled(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(sw(title)).onChanged != null;

  Map<String, Object?> patched([int i = 0]) =>
      Map<String, Object?>.from(sent(adapter, 'PATCH', _roles)[i].data as Map);

  Future<void> openSam(WidgetTester tester) async {
    await tester.tap(find.text('Sam Lead'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists members with status and role chips', (tester) async {
    await pump(tester);
    expect(find.text('Sam Lead'), findsOneWidget);
    expect(find.text('Pat Lapsed'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Lapsed'), findsOneWidget);
    expect(find.text('Leader'), findsOneWidget);
    expect(sent(adapter, 'GET', _members).first.queryParameters, {
      'q': '',
      'limit': 50,
    });
    await unmount(tester);
  });

  testWidgets('member rows and the roles sheet show avatars', (tester) async {
    await pump(tester);
    // Initials: no card photos in this test (D65).
    expect(find.text('SL'), findsOneWidget);
    expect(find.text('PL'), findsOneWidget);
    expect(find.byType(MemberAvatar), findsNWidgets(2));
    await openSam(tester);
    // The sheet header repeats Sam's avatar at a larger size.
    expect(find.byType(MemberAvatar), findsNWidgets(3));
    expect(find.text('SL'), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('committee can toggle Leader; Committee and Admin are locked', (
    tester,
  ) async {
    await pump(tester);
    await openSam(tester);
    expect(enabled(tester, 'Leader badge'), isTrue);
    expect(enabled(tester, 'Committee'), isFalse);
    expect(enabled(tester, 'Admin'), isFalse);
    expect(find.text('Only an admin can change this.'), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('Save is off until something changes', (tester) async {
    await pump(tester);
    await openSam(tester);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save roles'))
          .onPressed,
      isNull,
    );
    await unmount(tester);
  });

  testWidgets('removing the leader badge sends the full set', (tester) async {
    await pump(
      tester,
      routes: {
        'PATCH $_roles': FakeResponse(200, memberItemJson('m1', 'Sam Lead')),
      },
    );
    await openSam(tester);
    await tester.tap(sw('Leader badge'));
    await tester.pump();
    await tester.tap(find.text('Save roles'));
    await settle(tester);
    expect(patched(), {'roles': <String>[]});
    // The list shows the new roles (no Leader chip any more).
    expect(find.text('Leader'), findsNothing);
    await unmount(tester);
  });

  testWidgets('an admin can grant committee, keeping the other roles', (
    tester,
  ) async {
    await pump(
      tester,
      roles: ['admin'],
      routes: {
        'PATCH $_roles': FakeResponse(
          200,
          memberItemJson('m1', 'Sam Lead', roles: ['leader', 'committee']),
        ),
      },
    );
    await openSam(tester);
    expect(enabled(tester, 'Committee'), isTrue);
    expect(enabled(tester, 'Admin'), isTrue);
    await tester.tap(sw('Committee'));
    await tester.pump();
    await tester.tap(find.text('Save roles'));
    await settle(tester);
    expect(patched(), {
      'roles': ['leader', 'committee'],
    });
    expect(find.text('Committee'), findsOneWidget); // the chip
    await unmount(tester);
  });

  group('removing your own admin role', () {
    final self = [
      memberItemJson('m1', 'Sam Lead', roles: ['committee', 'admin']),
    ];

    testWidgets('asks first; Keep does nothing', (tester) async {
      await pump(
        tester,
        roles: ['admin'],
        memberId: 'm1',
        items: self,
        routes: {
          'PATCH $_roles': FakeResponse(200, memberItemJson('m1', 'Sam Lead')),
        },
      );
      await openSam(tester);
      await tester.tap(sw('Admin'));
      await tester.pump();
      await tester.tap(find.text('Save roles'));
      await tester.pumpAndSettle();
      expect(
        find.text("You'll lose admin access. Make sure another admin exists."),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(sent(adapter, 'PATCH', _roles), isEmpty);
      await unmount(tester);
    });

    testWidgets('confirming sends the remaining roles', (tester) async {
      await pump(
        tester,
        roles: ['admin'],
        memberId: 'm1',
        items: self,
        routes: {
          'PATCH $_roles': FakeResponse(
            200,
            memberItemJson('m1', 'Sam Lead', roles: ['committee']),
          ),
        },
      );
      await openSam(tester);
      await tester.tap(sw('Admin'));
      await tester.pump();
      await tester.tap(find.text('Save roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await settle(tester);
      expect(patched(), {
        'roles': ['committee'],
      });
      await unmount(tester);
    });

    testWidgets('removing someone else admin role needs no warning', (
      tester,
    ) async {
      await pump(
        tester,
        roles: ['admin'],
        items: self,
        routes: {
          'PATCH $_roles': FakeResponse(200, memberItemJson('m1', 'Sam Lead')),
        },
      );
      await openSam(tester);
      await tester.tap(sw('Admin'));
      await tester.pump();
      await tester.tap(find.text('Save roles'));
      await settle(tester);
      expect(find.textContaining('lose admin access'), findsNothing);
      expect(sent(adapter, 'PATCH', _roles), hasLength(1));
      await unmount(tester);
    });
  });

  testWidgets('a 403 shows a friendly message and keeps the sheet', (
    tester,
  ) async {
    await pump(
      tester,
      routes: {
        'PATCH $_roles': const FakeResponse(403, {
          'error': 'forbidden',
          'message': 'no',
        }),
      },
    );
    await openSam(tester);
    await tester.tap(sw('Leader badge'));
    await tester.pump();
    await tester.tap(find.text('Save roles'));
    await settle(tester);
    expect(
      find.text('Only an admin can change committee or admin roles.'),
      findsOneWidget,
    );
    expect(find.text('Save roles'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('offline shows the friendly connection message', (tester) async {
    await pump(tester); // no PATCH route
    await openSam(tester);
    await tester.tap(sw('Leader badge'));
    await tester.pump();
    await tester.tap(find.text('Save roles'));
    await settle(tester);
    expect(find.text('You need a connection to do that.'), findsOneWidget);
    await unmount(tester);
  });

  test('rolesToSend keeps the server order', () {
    expect(rolesToSend(leader: true, committee: true, admin: true), [
      'leader',
      'committee',
      'admin',
    ]);
    expect(rolesToSend(leader: false, committee: false, admin: false), isEmpty);
  });
}
