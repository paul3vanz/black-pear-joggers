import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/link_screen.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() {
    db = memoryDb();
    adapter = FakeAdapter({});
  });
  tearDown(() => db.close());

  Future<void> pumpLinkScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(
            MembershipRepository(db, fakeDio(adapter)),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          activeAccountProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: LinkScreen()),
      ),
    );
  }

  /// Fills the form like a user would: type a URN, pick a date, tap "Find me".
  Future<void> submitForm(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'England Athletics URN'),
      '1234567',
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Date of birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find me'));
    // The link call hits sqlite for real: let real async work finish.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('always shows the join card and the URN help text', (
    tester,
  ) async {
    await pumpLinkScreen(tester);

    expect(find.text('Not a member yet?'), findsOneWidget);
    expect(find.text('Join Black Pear Joggers'), findsOneWidget);
    expect(find.textContaining('membership card'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('shows the not-found state on 404 and can go back to the form', (
    tester,
  ) async {
    adapter.routes['POST /app/clubs/1/link'] = const FakeResponse(404, {
      'error': 'not_found',
    });
    await pumpLinkScreen(tester);
    await submitForm(tester);

    expect(find.textContaining("couldn't find a member"), findsOneWidget);
    expect(find.textContaining('up to a day'), findsOneWidget);
    expect(find.text('Not a member yet?'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Find me'), findsOneWidget);
  });

  testWidgets('shows a friendly message when rate limited', (tester) async {
    adapter.routes['POST /app/clubs/1/link'] = const FakeResponse(429, {
      'error': 'too_many_attempts',
    });
    await pumpLinkScreen(tester);
    await submitForm(tester);

    expect(
      find.textContaining('Too many attempts, try again in an hour'),
      findsOneWidget,
    );
  });

  testWidgets('shows the confirmation after a successful link', (tester) async {
    adapter.routes['POST /app/clubs/1/link'] = FakeResponse(
      200,
      membershipJson(),
    );
    await pumpLinkScreen(tester);
    await submitForm(tester);

    expect(find.text('We think we found you!'), findsOneWidget);
    expect(find.text('Jo Bloggs'), findsOneWidget);
    expect(find.text('V40'), findsOneWidget);
    expect(find.text('Black Pear Joggers'), findsOneWidget);
    expect(find.text("That's me"), findsOneWidget);
    expect(find.text('Not me'), findsOneWidget);
  });
}
