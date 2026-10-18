import 'dart:convert';

import 'package:bpj/app/app.dart';
import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A secure storage that misbehaves the way the Android plugin does when it
/// cannot decrypt what it holds (Keystore key gone after a restore or an OS
/// change): reads throw a [PlatformException], or return the literal text
/// "Data has been reset" (see AccountStore._resetSentinel).
class _BrokenStorage implements FlutterSecureStorage {
  _BrokenStorage({this.readThrows = false, Map<String, String>? initial})
    : data = {...?initial};

  final bool readThrows;
  final Map<String, String> data;
  final deleted = <String>[];
  String? readAlwaysReturns;

  /// Only read, write and delete are used by AccountStore. Handled through
  /// noSuchMethod so the fake does not repeat the plugin's long option lists.
  @override
  Object? noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        if (readThrows) {
          return Future<String?>.error(
            PlatformException(
              code: 'Exception encountered',
              message: 'javax.crypto.BadPaddingException: error:1e000065',
            ),
          );
        }
        return Future<String?>.value(readAlwaysReturns ?? data[key]);
      case #write:
        data[key!] = invocation.namedArguments[#value]! as String;
        return Future<void>.value();
      case #delete:
        deleted.add(key!);
        data.remove(key);
        return Future<void>.value();
    }
    throw UnimplementedError('${invocation.memberName} is not faked');
  }
}

const _alice = Account(sub: 'auth0|alice', name: 'Alice');

void main() {
  group('AccountStore on storage that cannot be read', () {
    test('PlatformException on read is treated as nothing stored', () async {
      final store = AccountStore(_BrokenStorage(readThrows: true));
      expect(await store.readAccounts(), isEmpty);
      expect(await store.readActiveSub(), isNull);
      expect(await store.readCredentials('auth0|alice'), isNull);
      expect(await store.readActiveClubId('auth0|alice'), isNull);
      expect(await store.readFlag('asked'), isFalse);
    });

    test(
      'the "Data has been reset" text is not mistaken for a value',
      () async {
        final storage = _BrokenStorage()
          ..readAlwaysReturns = 'Data has been reset';
        final store = AccountStore(storage);
        expect(await store.readAccounts(), isEmpty);
        expect(await store.readActiveSub(), isNull);
        expect(await store.readCredentials('auth0|alice'), isNull);
      },
    );

    test('credentials that are JSON of the wrong shape are dropped', () async {
      for (final bad in [
        '[]', // a list, not a map: TypeError, not FormatException
        '{}', // keys missing
        '{"accessToken": 5, "expiresAt": "2099-01-01T00:00:00Z"}', // wrong type
        '{"accessToken": "a", "expiresAt": "not a date"}', // FormatException
        'not json at all',
      ]) {
        final storage = _BrokenStorage(initial: {'cred_auth0|alice': bad});
        final store = AccountStore(storage);
        expect(await store.readCredentials('auth0|alice'), isNull, reason: bad);
        expect(storage.deleted, contains('cred_auth0|alice'), reason: bad);
      }
    });

    test(
      'a damaged accounts list is dropped, one bad entry is skipped',
      () async {
        var storage = _BrokenStorage(initial: {'accounts': '{"sub": "x"}'});
        expect(await AccountStore(storage).readAccounts(), isEmpty);
        expect(storage.deleted, contains('accounts'));

        storage = _BrokenStorage(
          initial: {
            'accounts': jsonEncode([
              {'name': 'no sub'},
              _alice.toJson(),
              null,
            ]),
          },
        );
        final accounts = await AccountStore(storage).readAccounts();
        expect(accounts.map((a) => a.sub), ['auth0|alice']);
      },
    );

    test('good data still round-trips', () async {
      final store = AccountStore(_BrokenStorage());
      await store.upsertAccount(_alice);
      await store.writeActiveSub(_alice.sub);
      await store.writeCredentials(
        _alice.sub,
        StoredCredentials(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2099),
        ),
      );
      expect((await store.readAccounts()).single.sub, _alice.sub);
      expect(await store.readActiveSub(), _alice.sub);
      expect((await store.readCredentials(_alice.sub))!.accessToken, 'a');
    });

    test('unreadable credentials mean a dead session, not a failure', () async {
      final store = AccountStore(
        _BrokenStorage(initial: {'cred_auth0|alice': '[]'}),
      );
      final auth = AuthService(store, isConfigured: true);
      await expectLater(
        auth.getValidAccessToken('auth0|alice'),
        throwsA(isA<SessionExpiredException>()),
      );
    });
  });

  group('app start with unreadable secure storage', () {
    test(
      'AccountsController ends up signed out instead of in an error',
      () async {
        final container = ProviderContainer(
          overrides: [
            accountStoreProvider.overrideWithValue(
              AccountStore(_BrokenStorage(readThrows: true)),
            ),
          ],
        );
        addTearDown(container.dispose);
        final state = await container.read(accountsControllerProvider.future);
        expect(state.activeSub, isNull);
        expect(state.accounts, isEmpty);
        expect(container.read(accountsControllerProvider).hasValue, isTrue);
      },
    );

    test(
      'even a store that throws outright gives a signed-out state',
      () async {
        final container = ProviderContainer(
          overrides: [accountStoreProvider.overrideWithValue(_ThrowingStore())],
        );
        addTearDown(container.dispose);
        final state = await container.read(accountsControllerProvider.future);
        expect(state.activeSub, isNull);
      },
    );

    testWidgets('the app lands on the sign-in screen, not the splash', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountStoreProvider.overrideWithValue(
              AccountStore(_BrokenStorage(readThrows: true)),
            ),
          ],
          child: const BpjApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Black Pear Joggers'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

class _ThrowingStore implements AccountStore {
  @override
  Future<List<Account>> readAccounts() async =>
      throw PlatformException(code: 'Exception encountered');

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw PlatformException(code: 'Exception encountered');
}
