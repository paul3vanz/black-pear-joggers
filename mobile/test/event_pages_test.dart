import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/events/data/event_dtos.dart';
import 'package:bpj/features/groups/ui/respond_card.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase6.dart';
import 'support/fake_api_phase8.dart';
import 'support/groups_test_support.dart';

/// Phase 8c: the run page for `events` (a card per event, add an event, notes)
/// and for `race` (one "Who's going?" card). D79, D84, D85.
void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final worcester = eventGroupJson(
    'g1',
    label: 'Worcester parkrun',
    locationId: 'l-worcester',
    description: 'Meet at 8:15 by the cafe',
    goingCount: 3,
    createdByMemberId: 'creator',
  );
  final bromsgrove = eventGroupJson(
    'g2',
    label: 'Bromsgrove parkrun',
    locationId: 'l-bromsgrove',
    goingCount: 1,
    createdByMemberId: 'other',
  );

  Map<String, Object?> planWithNames() => planJson(
    'a',
    groups: [
      groupPlanJson(
        'g1',
        attendees: [
          attendeeJson('me', 'Me M.', paceUnit: null, paceFromS: null),
          attendeeJson('m2', 'Sam B.', paceUnit: null, paceFromS: null),
          attendeeJson('m3', 'Jo L.', paceUnit: null, paceFromS: null),
        ],
      ),
      groupPlanJson('g2'),
    ],
  );

  /// Pumps the run page. [mode] `events` or `race`; [myStatus] / [myGroupId]
  /// are the summary the server sent for the caller.
  Future<void> pump(
    WidgetTester tester, {
    String mode = 'events',
    List<Map<String, Object?>>? groups,
    List<String> roles = const [],
    String memberId = 'me',
    String? coordinator,
    String? myStatus,
    String? myGroupId,
    int goingTotal = 4,
    String status = 'scheduled',
    Map<String, Object> routes = const {},
    int unread = 0,
    GoRouter? router,
    bool withLocations = false,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      memberId: memberId,
      routes: {
        'GET /app/clubs/1/sessions/a/plan': FakeResponse(200, planWithNames()),
        'PUT /app/clubs/1/sessions/a/attendance': FakeResponse(
          200,
          attendanceJson('a', groupId: myGroupId),
        ),
        ...routes,
      },
    );
    final list = groups ?? [worcester, bromsgrove];
    await tester.runAsync(() async {
      await seedUnits(db);
      await seedSession(
        db,
        'a',
        groupMode: mode,
        groups: list,
        status: status,
        coordinatorMemberId: coordinator,
        summary: summaryJson(
          groupCount: list.length,
          goingCount: goingTotal,
          myStatus: myStatus,
          myGroupId: myGroupId,
        ),
      );
      if (unread > 0 && list.isNotEmpty) {
        await seedThread(db, list.first['id']! as String, unreadCount: unread);
      }
      if (withLocations) {
        for (final j in [
          eventLocationJson(
            'l-worcester',
            name: 'Worcester parkrun',
            slug: 'worcester',
          ),
          eventLocationJson(
            'l-bromsgrove',
            name: 'Bromsgrove parkrun',
            slug: 'bromsgrove',
          ),
          eventLocationJson(
            'l-cannon',
            name: 'Cannon Hill parkrun',
            slug: 'cannon',
          ),
        ]) {
          await db
              .into(db.eventLocations)
              .insert(EventLocationDto.fromJson(j).toCompanion(1));
        }
      }
    });
    if (router != null) {
      await pumpGroupsRouter(tester, db, adapter, router);
    } else {
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const SessionDetailScreen(sessionId: 'a'),
      );
    }
  }

  Map<String, Object?> body(RequestOptions r) =>
      (r.data! as Map<Object?, Object?>).cast<String, Object?>();

  RequestOptions lastRequest(String method, String path) =>
      sent(adapter, method, path).last;

  Finder card(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(Card));

  Finder within(String title, Finder inner) =>
      find.descendant(of: card(title), matching: inner);

  const attendancePath = '/app/clubs/1/sessions/a/attendance';
  const groupsPath = '/app/clubs/1/sessions/a/groups';

  group('events page', () {
    testWidgets('shows the heading, intro and a card per event', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Where are you running?'), findsOneWidget);
      expect(
        find.text(
          "Pick the parkrun you're going to, or add one. Each has its own "
          'chat for sharing lifts.',
        ),
        findsOneWidget,
      );
      expect(find.text('Worcester parkrun'), findsOneWidget);
      expect(find.text('Bromsgrove parkrun'), findsOneWidget);
      expect(find.text('3 going'), findsOneWidget);
      expect(find.text('1 going'), findsOneWidget);
      expect(find.text('Meet at 8:15 by the cafe'), findsOneWidget);
      expect(find.text('Add a parkrun / event'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no pace, leader or coverage machinery', (tester) async {
      await pump(tester, roles: const ['committee'], coordinator: 'me');
      for (final text in [
        'Set pace for this run',
        'No usual pace set',
        'Set your usual pace',
        'Change for this run',
        'Group coverage',
        'Lead a group',
        "I'll lead this group too",
        'Step down',
        'Needs a leader',
        "Who's coming",
        'Coming, no group yet',
      ]) {
        expect(find.text(text), findsNothing, reason: text);
      }
      expect(
        find.textContaining('Other pace groups will be confirmed'),
        findsNothing,
      );
      expect(find.textContaining('Pick your pace group'), findsNothing);
      await unmount(tester);
    });

    testWidgets('empty state', (tester) async {
      await pump(tester, groups: const [], goingTotal: 0);
      expect(find.text('Nobody has picked a parkrun yet.'), findsOneWidget);
      expect(find.text('Add a parkrun / event'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('going without an event says so under the cards', (
      tester,
    ) async {
      await pump(tester, goingTotal: 6);
      expect(find.text('2 going, event not chosen yet'), findsOneWidget);
      await unmount(tester);
    });

    group('I\'m going and Leave', () {
      testWidgets('I\'m going sends going with that event\'s id', (
        tester,
      ) async {
        await pump(tester);
        await tester.tap(within('Bromsgrove parkrun', find.text("I'm going")));
        await settle(tester);
        final b = body(lastRequest('PUT', attendancePath));
        expect(b['status'], 'going');
        expect(b['groupId'], 'g2');
        await unmount(tester);
      });

      testWidgets('in an event the card says so and offers Leave', (
        tester,
      ) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g1');
        expect(
          within('Worcester parkrun', find.text("You're going")),
          findsOneWidget,
        );
        expect(
          within('Worcester parkrun', find.text("I'm going")),
          findsNothing,
        );
        expect(
          within('Bromsgrove parkrun', find.text("I'm going")),
          findsOneWidget,
        );
        expect(find.text('Leave'), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('Leave goes back to going with no event (D85)', (
        tester,
      ) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g1');
        await tester.tap(find.text('Leave'));
        await settle(tester);
        final b = body(lastRequest('PUT', attendancePath));
        expect(b['status'], 'going');
        expect(b.containsKey('groupId'), isFalse);
        await unmount(tester);
      });

      testWidgets('"Can\'t come" at run level sends not_going', (tester) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g1');
        await tester.tap(find.text("Can't come"));
        await settle(tester);
        final b = body(lastRequest('PUT', attendancePath));
        expect(b['status'], 'not_going');
        expect(b.containsKey('groupId'), isFalse);
        await unmount(tester);
      });

      testWidgets('a cancelled run has no buttons and no add', (tester) async {
        await pump(tester, status: 'cancelled');
        expect(find.text("I'm going"), findsNothing);
        expect(find.text('Add a parkrun / event'), findsNothing);
        expect(
          find.text(
            'This run has been cancelled. '
            "You can't respond to it any more.",
          ),
          findsOneWidget,
        );
        await unmount(tester);
      });
    });

    group('fellow attendees', () {
      testWidgets('shown with names (not mine) when I am in the event', (
        tester,
      ) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g1');
        expect(
          within('Worcester parkrun', find.text('Also going')),
          findsOneWidget,
        );
        expect(find.text('Sam B.'), findsOneWidget);
        expect(find.text('Jo L.'), findsOneWidget);
        expect(find.text('Me M.'), findsNothing);
        await unmount(tester);
      });

      testWidgets('not shown for an event I am not in', (tester) async {
        // The cached plan still has Worcester's names, but I am in Bromsgrove.
        await pump(tester, myStatus: 'going', myGroupId: 'g2');
        expect(find.text('Sam B.'), findsNothing);
        expect(find.text('Also going'), findsNothing);
        await unmount(tester);
      });

      testWidgets('not shown when I am not going to anything', (tester) async {
        await pump(tester);
        expect(find.text('Sam B.'), findsNothing);
        await unmount(tester);
      });

      testWidgets('hidden quietly when the plan is unavailable', (
        tester,
      ) async {
        await pump(
          tester,
          myStatus: 'going',
          myGroupId: 'g1',
          routes: {
            'GET /app/clubs/1/sessions/a/plan': FakeResponse(500, {
              'error': 'boom',
            }),
          },
        );
        expect(find.text('Worcester parkrun'), findsOneWidget);
        expect(find.text('Also going'), findsNothing);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });

      testWidgets('committee see names without being in the event', (
        tester,
      ) async {
        await pump(tester, roles: const ['committee']);
        expect(find.text('Sam B.'), findsOneWidget);
        await unmount(tester);
      });
    });

    group('chat', () {
      Finder chat() => find.text('Chat');

      testWidgets('only on the event I am in', (tester) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g2');
        expect(chat(), findsOneWidget);
        expect(within('Bromsgrove parkrun', chat()), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('not for someone who is not in an event', (tester) async {
        await pump(tester);
        expect(chat(), findsNothing);
        await unmount(tester);
      });

      testWidgets('not after saying "can\'t come"', (tester) async {
        await pump(tester, myStatus: 'not_going', myGroupId: 'g1');
        expect(chat(), findsNothing);
        await unmount(tester);
      });

      testWidgets('committee see it on every event', (tester) async {
        await pump(tester, roles: const ['committee']);
        expect(chat(), findsNWidgets(2));
        await unmount(tester);
      });

      bool dot(WidgetTester tester) => tester
          .widget<Badge>(find.byKey(const ValueKey('chat-unread')))
          .isLabelVisible;

      testWidgets('unread dot', (tester) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g1', unread: 2);
        expect(dot(tester), isTrue);
        await unmount(tester);
      });

      testWidgets('no dot when read', (tester) async {
        await pump(tester, myStatus: 'going', myGroupId: 'g1');
        expect(dot(tester), isFalse);
        await unmount(tester);
      });

      testWidgets('opens the chat route (also the push target)', (
        tester,
      ) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const SessionDetailScreen(sessionId: 'a'),
            ),
            GoRoute(
              path: '/runs/:id/groups/:groupId/chat',
              builder: (_, state) => Scaffold(
                body: Text(
                  'chat ${state.pathParameters['id']} '
                  '${state.pathParameters['groupId']}',
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await pump(tester, myStatus: 'going', myGroupId: 'g1', router: router);
        await tester.tap(find.text('Chat'));
        await settle(tester);
        expect(find.text('chat a g1'), findsOneWidget);
        await unmount(tester);
      });
    });

    group('notes and removing', () {
      Finder menu() => find.byTooltip('Event options');

      // (who, member id, roles, coordinator, how many cards get a menu)
      for (final c in [
        ('the creator of one event', 'creator', <String>[], null, 1),
        ('committee', 'me', ['committee'], null, 2),
        ('the run coordinator', 'me', <String>[], 'me', 2),
        ('a plain member', 'me', <String>[], null, 0),
        ('a leader (the role alone)', 'me', ['leader'], null, 0),
      ]) {
        testWidgets('${c.$1}: ${c.$5} event menus', (tester) async {
          await pump(tester, memberId: c.$2, roles: c.$3, coordinator: c.$4);
          expect(menu(), c.$5 == 0 ? findsNothing : findsNWidgets(c.$5));
          if (c.$5 == 1) {
            expect(within('Worcester parkrun', menu()), findsOneWidget);
          }
          await unmount(tester);
        });
      }

      testWidgets('no menu on a finished run', (tester) async {
        await pump(tester, roles: const ['committee'], status: 'cancelled');
        expect(menu(), findsNothing);
        await unmount(tester);
      });

      testWidgets('Edit note saves the description with a PATCH', (
        tester,
      ) async {
        await pump(
          tester,
          memberId: 'creator',
          routes: {
            'PATCH /app/clubs/1/groups/g1': FakeResponse(
              200,
              eventGroupJson(
                'g1',
                label: 'Worcester parkrun',
                locationId: 'l-worcester',
                description: 'Meeting at 8:15, 2 seats spare',
                goingCount: 3,
                createdByMemberId: 'creator',
              ),
            ),
          },
        );
        await tester.tap(menu());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit note'));
        await tester.pumpAndSettle();
        // The dialog starts with the current note and shows the hint text.
        expect(
          find.widgetWithText(TextField, 'Meet at 8:15 by the cafe'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(TextField),
          '  Meeting at 8:15, 2 seats spare ',
        );
        await tester.tap(find.text('Save'));
        await settle(tester);
        final b = body(lastRequest('PATCH', '/app/clubs/1/groups/g1'));
        expect(b['description'], 'Meeting at 8:15, 2 seats spare');
        expect(b['kind'], 'event');
        expect(b['label'], 'Worcester parkrun');
        expect(b['paceFromS'], isNull);
        expect(find.text('Meeting at 8:15, 2 seats spare'), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('the note field has the hint and a 1000 character limit', (
        tester,
      ) async {
        await pump(tester, roles: const ['committee']);
        await tester.tap(within('Bromsgrove parkrun', menu()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit note'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'e.g. Meeting at 8:15 at the Co-op car park, 2 seats spare',
          ),
          findsOneWidget,
        );
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.maxLength, 1000);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(sent(adapter, 'PATCH', '/app/clubs/1/groups/g2'), isEmpty);
        await unmount(tester);
      });

      testWidgets('Remove event asks first, then DELETEs', (tester) async {
        await pump(
          tester,
          roles: const ['committee'],
          routes: {'DELETE /app/clubs/1/groups/g2': const FakeResponse(204)},
        );
        await tester.tap(within('Bromsgrove parkrun', menu()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove event'));
        await tester.pumpAndSettle();
        expect(find.text('Remove this event?'), findsOneWidget);
        // Keep: nothing is sent.
        await tester.tap(find.text('Keep'));
        await tester.pumpAndSettle();
        expect(sent(adapter, 'DELETE', '/app/clubs/1/groups/g2'), isEmpty);

        await tester.tap(within('Bromsgrove parkrun', menu()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove event'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await settle(tester);
        expect(sent(adapter, 'DELETE', '/app/clubs/1/groups/g2'), hasLength(1));
        expect(find.text('Bromsgrove parkrun'), findsNothing);
        await unmount(tester);
      });
    });

    group('add an event', () {
      Future<void> open(WidgetTester tester) async {
        await tester.tap(find.text('Add a parkrun / event'));
        await settle(tester);
      }

      Finder inSheet(String text) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(text),
      );

      testWidgets('a location pick creates the group with its locationId', (
        tester,
      ) async {
        await pump(
          tester,
          withLocations: true,
          routes: {
            'POST $groupsPath': FakeResponse(
              201,
              eventGroupJson(
                'new1',
                label: 'Cannon Hill parkrun',
                locationId: 'l-cannon',
                goingCount: 1,
                createdByMemberId: 'me',
              ),
            ),
          },
        );
        await open(tester);
        await tester.tap(inSheet('Cannon Hill parkrun'));
        await settle(tester);
        final b = body(lastRequest('POST', groupsPath));
        expect(b['kind'], 'event');
        expect(b['locationId'], 'l-cannon');
        expect(b.containsKey('label'), isFalse);
        expect(b.containsKey('lead'), isFalse);
        expect(b.containsKey('paceFromS'), isFalse);
        expect(b['id'], isA<String>());
        // The new card is there and I am in it, so the chat is offered.
        expect(card('Cannon Hill parkrun'), findsOneWidget);
        expect(
          within('Cannon Hill parkrun', find.text("You're going")),
          findsOneWidget,
        );
        expect(
          within('Cannon Hill parkrun', find.text('Chat')),
          findsOneWidget,
        );
        // The snackbar offers a note for car sharing.
        expect(
          find.text('Added Cannon Hill parkrun. You are going.'),
          findsOneWidget,
        );
        expect(find.text('Add a note for car sharing'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        await unmount(tester);
      });

      testWidgets('the snackbar action opens the note editor', (tester) async {
        await pump(
          tester,
          withLocations: true,
          routes: {
            'POST $groupsPath': FakeResponse(
              201,
              eventGroupJson(
                'new1',
                label: 'Cannon Hill parkrun',
                locationId: 'l-cannon',
                goingCount: 1,
                createdByMemberId: 'me',
              ),
            ),
          },
        );
        await open(tester);
        await tester.tap(inSheet('Cannon Hill parkrun'));
        await settle(tester);
        await tester.tap(find.text('Add a note for car sharing'));
        await tester.pumpAndSettle();
        expect(find.text('Note for this event'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));
        await unmount(tester);
      });

      testWidgets('a typed name is sent as the label with no location', (
        tester,
      ) async {
        await pump(
          tester,
          withLocations: true,
          routes: {
            'POST $groupsPath': FakeResponse(
              201,
              eventGroupJson(
                'new2',
                label: 'Hereford parkrun',
                goingCount: 1,
                createdByMemberId: 'me',
              ),
            ),
          },
        );
        await open(tester);
        await tester.tap(find.text('Other...'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Event name'),
          'Hereford parkrun',
        );
        await tester.pump();
        await tester.tap(find.text('Use this name'));
        await settle(tester);
        final b = body(lastRequest('POST', groupsPath));
        expect(b['kind'], 'event');
        expect(b['label'], 'Hereford parkrun');
        expect(b.containsKey('locationId'), isFalse);
        // Not saved as a club location (the box was left unticked).
        expect(sent(adapter, 'POST', '/app/clubs/1/event-locations'), isEmpty);
        expect(card('Hereford parkrun'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        await unmount(tester);
      });

      testWidgets('an event that already exists (200) is simply joined', (
        tester,
      ) async {
        await pump(
          tester,
          withLocations: true,
          routes: {
            'POST $groupsPath': FakeResponse(
              200,
              eventGroupJson(
                'g2',
                label: 'Bromsgrove parkrun',
                locationId: 'l-bromsgrove',
                goingCount: 2,
                createdByMemberId: 'other',
              ),
            ),
          },
        );
        await open(tester);
        // Already on the run: greyed but selectable.
        expect(find.text('Already added'), findsWidgets);
        await tester.tap(inSheet('Bromsgrove parkrun').first);
        await settle(tester);
        expect(find.text("You're going to Bromsgrove parkrun"), findsOneWidget);
        expect(find.text('Add a note for car sharing'), findsNothing);
        // Still two cards, and I am in the existing one.
        expect(card('Bromsgrove parkrun'), findsOneWidget);
        expect(
          within('Bromsgrove parkrun', find.text("You're going")),
          findsOneWidget,
        );
        expect(find.text('2 going'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        await unmount(tester);
      });

      testWidgets('a refused add shows the reason and adds nothing', (
        tester,
      ) async {
        await pump(
          tester,
          withLocations: true,
          routes: {
            'POST $groupsPath': FakeResponse(409, {
              'error': 'session_past',
              'message': 'This run has finished.',
            }),
          },
        );
        await open(tester);
        await tester.tap(inSheet('Cannon Hill parkrun'));
        await settle(tester);
        expect(find.text('This run has finished.'), findsOneWidget);
        expect(card('Cannon Hill parkrun'), findsNothing);
        await tester.pump(const Duration(seconds: 6));
        await unmount(tester);
      });

      testWidgets('dismissing the picker adds nothing', (tester) async {
        await pump(tester, withLocations: true);
        await open(tester);
        await tester.tapAt(const Offset(10, 10)); // the barrier
        await settle(tester);
        expect(sent(adapter, 'POST', groupsPath), isEmpty);
        await unmount(tester);
      });
    });

    testWidgets('unlinked members cannot add', (tester) async {
      // Not linked: no membership row, so no member id.
      adapter = FakeAdapter({
        'GET /app/clubs/1/sessions/a/plan': FakeResponse(200, planWithNames()),
      });
      await tester.runAsync(() async {
        await seedUnits(db);
        await seedSession(
          db,
          'a',
          groupMode: 'events',
          groups: [worcester],
          summary: summaryJson(groupCount: 1, goingCount: 3),
        );
      });
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const SessionDetailScreen(sessionId: 'a'),
      );
      expect(find.text('Add a parkrun / event'), findsNothing);
      await unmount(tester);
    });

    testWidgets('no overflow on a 320 px wide screen', (tester) async {
      final long = eventGroupJson(
        'g1',
        label: 'Newcastle-under-Lyme Wolstanton Marsh parkrun',
        locationId: 'l1',
        description:
            'Meeting at the Co-op car park at 8:15, we have two seats spare '
            'and can pick up from Worcester Foregate Street station if you '
            'let us know in the chat beforehand.',
        goingCount: 12,
        maybeCount: 3,
        createdByMemberId: 'me',
      );
      final plan = planJson(
        'a',
        groups: [
          groupPlanJson(
            'g1',
            attendees: [
              for (var i = 0; i < 6; i++)
                attendeeJson(
                  'm$i',
                  'Bartholomew Featherstonehaugh-$i',
                  paceUnit: null,
                  paceFromS: null,
                ),
            ],
          ),
        ],
      );
      await pump(
        tester,
        groups: [long],
        myStatus: 'going',
        myGroupId: 'g1',
        routes: {'GET /app/clubs/1/sessions/a/plan': FakeResponse(200, plan)},
        unread: 1,
      );
      tester.view.physicalSize = const Size(320, 2400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpAndSettle();
      expect(find.textContaining('Bartholomew'), findsWidgets);
      expect(find.text('Chat'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });

  group('race page', () {
    final race = eventGroupJson(
      'r1',
      label: 'Droitwich 10k',
      goingCount: 2,
      createdByMemberId: 'committee1',
    );

    Map<String, Object?> racePlan() => planJson(
      'a',
      groups: [
        groupPlanJson(
          'r1',
          attendees: [
            attendeeJson('me', 'Me M.', paceUnit: null, paceFromS: null),
            attendeeJson('m2', 'Sam B.', paceUnit: null, paceFromS: null),
          ],
        ),
      ],
    );

    Future<void> pumpRace(
      WidgetTester tester, {
      List<Map<String, Object?>>? groups,
      String? myStatus,
      String? myGroupId,
      List<String> roles = const [],
      String status = 'scheduled',
      int unread = 0,
    }) => pump(
      tester,
      mode: 'race',
      groups: groups ?? [race],
      myStatus: myStatus,
      myGroupId: myGroupId,
      roles: roles,
      status: status,
      unread: unread,
      goingTotal: 2,
      routes: {
        'GET /app/clubs/1/sessions/a/plan': FakeResponse(200, racePlan()),
      },
    );

    testWidgets('one "Who\'s going?" card with the count', (tester) async {
      await pumpRace(tester);
      expect(find.text("Who's going?"), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
      expect(find.text('2 going'), findsOneWidget);
      expect(find.text("I'm going"), findsOneWidget);
      expect(find.text("Can't go"), findsOneWidget);
      // No add button, no event menu, no run-level card, no pace machinery.
      expect(find.text('Add a parkrun / event'), findsNothing);
      expect(find.byTooltip('Event options'), findsNothing);
      expect(find.text('Are you coming?'), findsNothing);
      expect(find.byType(RespondCard), findsNothing);
      expect(find.text('Set pace for this run'), findsNothing);
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Sam B.'), findsNothing);
      await unmount(tester);
    });

    testWidgets('no remove even for the committee', (tester) async {
      await pumpRace(tester, roles: const ['committee']);
      expect(find.byTooltip('Event options'), findsNothing);
      expect(find.text('Add a parkrun / event'), findsNothing);
      await unmount(tester);
    });

    testWidgets('I\'m going uses the race group\'s id', (tester) async {
      await pumpRace(tester);
      await tester.tap(find.text("I'm going"));
      await settle(tester);
      final b = body(lastRequest('PUT', attendancePath));
      expect(b['status'], 'going');
      expect(b['groupId'], 'r1');
      await unmount(tester);
    });

    testWidgets('Can\'t go sends not_going', (tester) async {
      await pumpRace(tester, myStatus: 'going', myGroupId: 'r1');
      await tester.tap(find.text("Can't go"));
      await settle(tester);
      final b = body(lastRequest('PUT', attendancePath));
      expect(b['status'], 'not_going');
      expect(b.containsKey('groupId'), isFalse);
      await unmount(tester);
    });

    testWidgets('going: names, chat and the unread dot', (tester) async {
      await pumpRace(tester, myStatus: 'going', myGroupId: 'r1', unread: 3);
      expect(find.text("You're going"), findsOneWidget);
      expect(find.text("I'm going"), findsNothing);
      expect(find.text('Also going'), findsOneWidget);
      expect(find.text('Sam B.'), findsOneWidget);
      expect(find.text('Me M.'), findsNothing);
      expect(find.text('Chat'), findsOneWidget);
      expect(
        tester
            .widget<Badge>(find.byKey(const ValueKey('chat-unread')))
            .isLabelVisible,
        isTrue,
      );
      await unmount(tester);
    });

    testWidgets('after Can\'t go the card says so and offers I\'m going', (
      tester,
    ) async {
      await pumpRace(tester, myStatus: 'not_going');
      expect(find.text("You can't make it."), findsOneWidget);
      expect(find.text("I'm going"), findsOneWidget);
      expect(find.text("Can't go"), findsNothing);
      expect(find.text('Chat'), findsNothing);
      await unmount(tester);
    });

    testWidgets('a missing group falls back to plain going / not going', (
      tester,
    ) async {
      await pumpRace(tester, groups: const []);
      expect(find.text('2 going'), findsOneWidget);
      await tester.tap(find.text("I'm going"));
      await settle(tester);
      var b = body(lastRequest('PUT', attendancePath));
      expect(b['status'], 'going');
      expect(b.containsKey('groupId'), isFalse);
      await tester.tap(find.text("Can't go"));
      await settle(tester);
      b = body(lastRequest('PUT', attendancePath));
      expect(b['status'], 'not_going');
      expect(find.text('Chat'), findsNothing);
      await unmount(tester);
    });

    testWidgets('a finished race shows the closed explanation only', (
      tester,
    ) async {
      await pumpRace(tester, status: 'cancelled');
      expect(find.textContaining('This run has been cancelled.'), findsWidgets);
      expect(find.text("I'm going"), findsNothing);
      expect(find.text("Can't go"), findsNothing);
      await unmount(tester);
    });
  });

  group('pace runs are unchanged', () {
    testWidgets('a paced run still has the pace tile and Groups', (
      tester,
    ) async {
      await pump(
        tester,
        mode: 'paced',
        groups: [groupJson('p1', label: 'Tempo', goingCount: 2)],
      );
      expect(find.text('Set pace for this run'), findsOneWidget);
      expect(find.text('Pace groups'), findsOneWidget);
      expect(find.text('Join this group'), findsOneWidget);
      expect(find.text('Add a parkrun / event'), findsNothing);
      expect(find.text('Where are you running?'), findsNothing);
      await unmount(tester);
    });
  });
}
