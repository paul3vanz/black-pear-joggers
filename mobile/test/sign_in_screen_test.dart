import 'package:bpj/app/app.dart';
import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in so tests never touch the real keystore. Dart lets you
/// `implement` any class as an interface, like a hand-written mock object in TS.
class _FakeAccountStore implements AccountStore {
  @override
  Future<List<Account>> readAccounts() async => const [];
  @override
  Future<String?> readActiveSub() async => null;
  @override
  Future<void> writeActiveSub(String? sub) async {}
  @override
  Future<int?> readActiveClubId(String sub) async => null;

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void main() {
  testWidgets('shows the sign-in screen when nobody is signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStoreProvider.overrideWithValue(_FakeAccountStore()),
        ],
        child: const BpjApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Black Pear Joggers'), findsOneWidget);
    // AUTH0_CLIENT_ID is empty in tests, so the friendly "not set up" notice shows
    // instead of the Sign in button.
    expect(
      find.textContaining("isn't available in this build"),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    // Tests run in debug mode, so the developer token sign-in is present.
    expect(find.text('Developer: sign in with access token'), findsOneWidget);
  });
}
