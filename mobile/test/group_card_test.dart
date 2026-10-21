import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/ui/group_card.dart';
import 'package:bpj/features/groups/ui/groups_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api_phase4.dart';

Group mk(Map<String, Object?> json) => Group.fromJson(json);

Future<void> pumpCard(
  WidgetTester tester,
  Group g, {
  bool isMine = false,
  bool isLeading = false,
  VoidCallback? onJoin,
  VoidCallback? onLeave,
  VoidCallback? onStepDown,
  VoidCallback? onEdit,
  VoidCallback? onChat,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: GroupCard(
          group: g,
          units: const UnitPrefs(),
          isMine: isMine,
          isLeading: isLeading,
          onJoin: onJoin,
          onLeave: onLeave,
          onStepDown: onStepDown,
          onEdit: onEdit,
          onChat: onChat,
        ),
      ),
    ),
  ),
);

void main() {
  group('heading', () {
    testWidgets('run with a pace: pace · distance, label as subtitle', (
      tester,
    ) async {
      await pumpCard(
        tester,
        mk(
          groupJson('g', label: 'Steady', distanceValue: 3, distanceUnit: 'mi'),
        ),
      );
      expect(find.text('9:30-10:00/mi · 3 mi'), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);
      expect(find.text('Pace group'), findsNothing);
      // The label sits under the heading.
      expect(
        tester.getTopLeft(find.text('Steady')).dy,
        greaterThan(tester.getTopLeft(find.text('9:30-10:00/mi · 3 mi')).dy),
      );
    });

    testWidgets('run with a pace and no label has no subtitle', (tester) async {
      await pumpCard(tester, mk(groupJson('g')));
      expect(find.text('9:30-10:00/mi'), findsOneWidget);
      expect(find.text('Pace group'), findsNothing);
    });

    testWidgets('jog/walk with no pace: the label is the heading', (
      tester,
    ) async {
      await pumpCard(
        tester,
        mk(
          groupJson(
            'g',
            kind: 'jog_walk',
            label: 'Jog/walk',
            paceUnit: null,
            paceFromS: null,
            paceToS: null,
          ),
        ),
      );
      expect(find.text('Jog/walk'), findsOneWidget);
      expect(find.text('Pace group'), findsNothing);
    });

    testWidgets('efforts with a pace and a label', (tester) async {
      await pumpCard(
        tester,
        mk(groupJson('g', kind: 'efforts', label: '6 x 3 min', paceToS: null)),
      );
      expect(find.text('9:30/mi'), findsOneWidget);
      expect(find.text('6 x 3 min'), findsOneWidget);
    });

    testWidgets('efforts with a pace and no label names the kind', (
      tester,
    ) async {
      await pumpCard(tester, mk(groupJson('g', kind: 'efforts')));
      expect(find.text('9:30-10:00/mi'), findsOneWidget);
      expect(find.text('Efforts'), findsOneWidget);
    });

    testWidgets('route: the label heads it with the distance', (tester) async {
      await pumpCard(
        tester,
        mk(
          groupJson(
            'g',
            kind: 'route',
            label: 'Canal loop',
            paceUnit: null,
            paceFromS: null,
            paceToS: null,
            distanceValue: 10,
            distanceUnit: 'mi',
          ),
        ),
      );
      expect(find.text('Canal loop · 10 mi'), findsOneWidget);
    });
  });

  group('leading row', () {
    testWidgets('Step down sits on the same row as the leading note', (
      tester,
    ) async {
      var steppedDown = 0;
      await pumpCard(
        tester,
        mk(groupJson('g', label: 'Mine')),
        isLeading: true,
        isMine: true,
        onStepDown: () => steppedDown++,
        onChat: () {},
      );
      final note = find.text("You're leading this group");
      final button = find.widgetWithText(OutlinedButton, 'Step down');
      expect(note, findsOneWidget);
      expect(button, findsOneWidget);
      expect(
        (tester.getCenter(note).dy - tester.getCenter(button).dy).abs(),
        lessThan(8),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(40));
      // Not the same style as the primary Join button.
      expect(find.widgetWithText(FilledButton, 'Step down'), findsNothing);
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
      await tester.tap(button);
      expect(steppedDown, 1);
      // Chat stays.
      expect(find.text('Group chat'), findsOneWidget);
    });

    testWidgets('a member sees the in-group note, Join stays tonal', (
      tester,
    ) async {
      await pumpCard(tester, mk(groupJson('g')), isMine: true, onLeave: () {});
      expect(find.text("You're in this group"), findsOneWidget);
      expect(find.text('Step down'), findsNothing);
      expect(find.text('Leave group'), findsOneWidget);
    });

    testWidgets('committee (edit menu, not leading) gets no Step down', (
      tester,
    ) async {
      await pumpCard(tester, mk(groupJson('g')), onJoin: () {}, onEdit: () {});
      expect(find.text('Join this group'), findsOneWidget);
      expect(find.byTooltip('Group options'), findsOneWidget);
      expect(find.text('Step down'), findsNothing);
      expect(find.text("You're leading this group"), findsNothing);
    });

    testWidgets('Join and Group chat share a row', (tester) async {
      await pumpCard(tester, mk(groupJson('g')), onJoin: () {}, onChat: () {});
      expect(
        tester.getCenter(find.text('Join this group')).dy,
        tester.getCenter(find.text('Group chat')).dy,
      );
      // Leave and chat too.
      await pumpCard(
        tester,
        mk(groupJson('g')),
        isMine: true,
        onLeave: () {},
        onChat: () {},
      );
      expect(
        tester.getCenter(find.text('Leave group')).dy,
        tester.getCenter(find.text('Group chat')).dy,
      );
    });

    testWidgets('buttons are at least 40 px high', (tester) async {
      await pumpCard(tester, mk(groupJson('g')), onJoin: () {}, onChat: () {});
      for (final label in ['Join this group', 'Group chat']) {
        expect(
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byWidgetPredicate(
                    (w) => w is ButtonStyleButton,
                  ),
                ),
              )
              .height,
          greaterThanOrEqualTo(40),
        );
      }
    });
  });
}
