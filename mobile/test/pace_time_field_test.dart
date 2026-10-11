import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/ui/pace_input.dart';
import 'package:bpj/features/groups/ui/pace_time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaceTimeController', () {
    test('combines minutes and optional seconds as m:ss', () {
      final c = PaceTimeController();
      addTearDown(c.dispose);
      expect(c.text, '');
      c.minutes.text = '9';
      expect(c.text, '9:00');
      c.seconds.text = '5';
      expect(c.text, '9:05');
      c.seconds.text = '30';
      expect(c.text, '9:30');
    });

    test('the text setter fills both boxes', () {
      final c = PaceTimeController(text: '10:15');
      addTearDown(c.dispose);
      expect([c.minutes.text, c.seconds.text], ['10', '15']);
      c.text = '9:00';
      expect([c.minutes.text, c.seconds.text], ['9', '']);
      c.text = '';
      expect(c.isEmpty, isTrue);
    });

    test('seconds above 59 are flagged', () {
      final c = PaceTimeController(text: '9:30');
      addTearDown(c.dispose);
      expect(c.secondsOutOfRange, isFalse);
      c.seconds.text = '60';
      expect(c.secondsOutOfRange, isTrue);
      expect(
        checkPaceFields(
          mode: PaceMode.single,
          unit: DistUnit.mi,
          fast: c.text,
          slow: '',
        ).isValid,
        isFalse,
      );
    });
  });

  group('PaceInputController', () {
    test('seconds are optional: 9 + empty is 9:00', () {
      final c = PaceInputController(initial: const NoPace());
      addTearDown(c.dispose);
      c.setMode(PaceMode.single);
      c.fast.minutes.text = '9';
      expect(c.check().isValid, isTrue);
      expect(c.spec.display(DistUnit.mi), '9:00/mi');
    });

    test('minutes outside 3 to 30 are rejected', () {
      final c = PaceInputController(initial: const NoPace());
      addTearDown(c.dispose);
      c.setMode(PaceMode.single);
      c.fast.minutes.text = '2';
      expect(c.check().fastError, 'Enter a pace from 3:00 to 30:00');
      c.fast.minutes.text = '31';
      expect(c.check().fastError, 'Enter a pace from 3:00 to 30:00');
      c.fast.minutes.text = '30';
      expect(c.check().isValid, isTrue);
    });

    test('a range must not run slow to fast', () {
      final c = PaceInputController(initial: const NoPace());
      addTearDown(c.dispose);
      c.setMode(PaceMode.range);
      c.fast.text = '10:00';
      c.slow.text = '9:30';
      expect(c.check().slowError, contains('slower end'));
      c.slow.text = '10:30';
      expect(c.check().isValid, isTrue);
    });

    test('the unit toggle converts what is typed', () {
      final c = PaceInputController(initial: const NoPace());
      addTearDown(c.dispose);
      c.setMode(PaceMode.range);
      c.fast.text = '9:00';
      c.slow.text = '10:00';
      c.setUnit(DistUnit.km);
      expect([c.fast.minutes.text, c.fast.seconds.text], ['5', '36']);
      expect([c.slow.minutes.text, c.slow.seconds.text], ['6', '13']);
      expect(c.check().isValid, isTrue);
    });
  });

  group('PaceInput widget', () {
    late PaceInputController controller;

    Future<void> pump(WidgetTester tester) async {
      controller = PaceInputController(initial: const NoPace());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(child: PaceInput(controller: controller)),
            ),
          ),
        ),
      );
    }

    testWidgets('has number-only min and sec fields with a unit suffix', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();

      expect(find.text('Pace'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('sec'), findsOneWidget);
      expect(find.text('optional'), findsOneWidget);
      expect(find.text('/mi'), findsOneWidget);

      final min = tester.widget<TextField>(
        find.byKey(const ValueKey('pace-fast-min')),
      );
      expect(min.keyboardType, TextInputType.number);

      await tester.enterText(
        find.byKey(const ValueKey('pace-fast-min')),
        '1a2b3',
      );
      await tester.enterText(
        find.byKey(const ValueKey('pace-fast-sec')),
        ':4x5',
      );
      expect(controller.fast.minutes.text, '12');
      expect(controller.fast.seconds.text, '45');
    });

    testWidgets('shows range labels and the km suffix', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('min/km'));
      await tester.pumpAndSettle();
      expect(find.text('Faster end'), findsOneWidget);
      expect(find.text('Slower end'), findsOneWidget);
      expect(find.text('/km'), findsNWidgets(2));
    });

    testWidgets('validation shows the seconds message', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('pace-fast-min')), '9');
      await tester.enterText(find.byKey(const ValueKey('pace-fast-sec')), '60');
      await tester.pumpAndSettle();
      expect(find.text('Seconds must be 0 to 59'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('pace-fast-sec')), '59');
      await tester.pumpAndSettle();
      expect(find.text('Seconds must be 0 to 59'), findsNothing);
    });
  });
}
