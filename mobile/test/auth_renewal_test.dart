import 'package:bpj/app/app.dart';
import 'package:bpj/core/api/api_client.dart';
import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/auth/auth_service.dart';
import 'package:bpj/core/auth/session_expiry.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/memory_account_store.dart';

/// What the app does when the stored access token is expired and renewing it
/// fails: the answer must be a clear state (sign in again, or a retryable
/// error), and the account must not be lost for a mere network failure.
const _auth0Channel = MethodChannel('auth0.com/auth0_flutter/auth');
const _alice = Account(sub: 'auth0|alice', name: 'Alice');

/// Store with an EXPIRED access token and a refresh token.
class _Store extends MemoryAccountStore {
  _Store() : super([_alice]) {
    credentials[_alice.sub] = StoredCredentials(
      accessToken: 'old',
      refreshToken: 'refresh-1',
      expiresAt: DateTime.utc(2020),
    );
  }

  bool failWrites = false;

  @override
  Future<void> writeCredentials(String sub, StoredCredentials c) async {
    if (failWrites) throw PlatformException(code: 'Exception encountered');
    credentials[sub] = c;
  }
}

/// A `PlatformException` as the auth0_flutter Android side sends it.
PlatformException _auth0Error({
  required int status,
  String code = 'invalid_grant',
  Map<String, Object?> flags = const {},
}) => PlatformException(
  code: code,
  message: 'auth0 said no',
  details: {'_statusCode': status, '_errorFlags': flags},
);

Map<String, Object?> _renewed() => {
  'accessToken': 'new-access',
  'idToken': 'id',
  'refreshToken': 'refresh-2',
  'expiresAt': '2099-01-01T00:00:00.000Z',
  'scopes': ['openid'],
  'userProfile': {'sub': 'auth0|alice'},
  'tokenType': 'Bearer',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // A renewal that never completes is the bug under test: fail fast, not at 30s.

  late _Store store;
  late AuthService auth;
  var renewCalls = 0;
  Object? Function()? renewResult;

  setUp(() {
    store = _Store();
    auth = AuthService(store, isConfigured: true);
    renewCalls = 0;
    renewResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_auth0Channel, (call) async {
          if (call.method == 'auth#renew') {
            renewCalls++;
            return renewResult!();
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_auth0Channel, null);
  });

  test(
    'ROOT CAUSE: a renewal settles (it used to wait on its own future)',
    () async {
      // Both outcomes must complete. The old code awaited
      // `_renew(..).whenComplete(() => _renewals.remove(sub))`: the callback
      // returned the map entry, i.e. the very future whenComplete was about to
      // complete, so the future waited for itself and every request needing a
      // renewal hung forever, before reaching the network.
      renewResult = _renewed;
      expect(
        (await auth
            .getValidAccessToken(_alice.sub)
            .timeout(const Duration(seconds: 3))),
        'new-access',
      );
      store.credentials[_alice.sub] = StoredCredentials(
        accessToken: 'old',
        refreshToken: 'refresh-1',
        expiresAt: DateTime.utc(2020),
      );
      renewResult = () => throw _auth0Error(status: 403);
      await expectLater(
        auth
            .getValidAccessToken(_alice.sub)
            .timeout(const Duration(seconds: 3)),
        throwsA(isA<SessionExpiredException>()),
      );
    },
  );

  test('parallel requests share one renewal and all settle', () async {
    renewResult = _renewed;
    final tokens = await Future.wait([
      for (var i = 0; i < 5; i++) auth.getValidAccessToken(_alice.sub),
    ]).timeout(const Duration(seconds: 3));
    expect(tokens, everyElement('new-access'));
    expect(renewCalls, 1);
  });

  /// dio wired exactly like the app's, answering `GET /app/me` from [adapter].
  Dio api(FakeAdapter adapter) {
    final dio = buildApiClient(auth: auth, sub: _alice.sub);
    dio.httpClientAdapter = adapter;
    return dio;
  }

  Future<ApiException> failureOf(Dio dio) async {
    try {
      await dio.get<Object?>('/app/me');
    } on DioException catch (e) {
      return ApiException.from(e);
    }
    fail('expected the request to fail');
  }

  test(
    'expired token and a refused refresh: session_expired, no API call',
    () async {
      renewResult = () => throw _auth0Error(
        status: 403,
        flags: {'isRefreshTokenDeleted': true},
      );
      final adapter = FakeAdapter({'GET /app/me': FakeResponse(200, {})});
      final error = await failureOf(api(adapter));
      expect(error.isSessionExpired, isTrue);
      expect(renewCalls, 1);
      expect(adapter.requests, isEmpty, reason: 'nothing reaches the server');

      // ...and the standard handler turns that into "back to sign-in".
      final container = ProviderContainer(
        overrides: [accountStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(accountsControllerProvider.future);
      final handled = await container.read(sessionExpiryHandlerProvider)(
        _alice.sub,
        error,
      );
      expect(handled, isTrue);
      expect(
        container.read(accountsControllerProvider).value!.activeSub,
        isNull,
      );
      expect(store.credentials, isEmpty);
    },
  );

  test(
    'expired token and no network: retryable offline error, account kept',
    () async {
      renewResult = () => throw _auth0Error(
        status: 0,
        code: 'a0.network_error',
        flags: {'isNetworkError': true},
      );
      final adapter = FakeAdapter({});
      final error = await failureOf(api(adapter));
      expect(error.isSessionExpired, isFalse);
      expect(error.isNetworkError, isTrue);
      expect(adapter.requests, isEmpty);
      expect(store.credentials, contains(_alice.sub));
    },
  );

  test('Auth0 outage (5xx) and rate limiting (429) keep the account', () async {
    for (final status in [500, 503, 429]) {
      renewResult = () => throw _auth0Error(status: status, code: 'server');
      final error = await failureOf(api(FakeAdapter({})));
      expect(error.isSessionExpired, isFalse, reason: '$status');
      expect(store.credentials, contains(_alice.sub), reason: '$status');
    }
  });

  test('an unexpected local failure while renewing is retryable, not fatal', () async {
    // e.g. the plugin is missing/crashing: the channel answers nothing useful.
    renewResult = () => throw StateError('boom');
    final error = await failureOf(api(FakeAdapter({})));
    expect(error.isSessionExpired, isFalse);
    expect(error.message, isNot(contains('Instance of')));
    expect(store.credentials, contains(_alice.sub));
  });

  test(
    'a good renewal stores the new tokens and the request goes out',
    () async {
      renewResult = _renewed;
      final adapter = FakeAdapter({
        'GET /app/me': FakeResponse(200, {'ok': 1}),
      });
      final response = await api(adapter).get<Object?>('/app/me');
      expect(response.statusCode, 200);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer new-access',
      );
      expect(store.credentials[_alice.sub]!.refreshToken, 'refresh-2');
    },
  );

  test(
    'a renewal that cannot be saved still lets the request through',
    () async {
      renewResult = _renewed;
      store.failWrites = true;
      final adapter = FakeAdapter({
        'GET /app/me': FakeResponse(200, {'ok': 1}),
      });
      final response = await api(adapter).get<Object?>('/app/me');
      expect(response.statusCode, 200);
    },
  );

  test('a 401 whose renewal is refused becomes session_expired', () async {
    // Valid-looking token the server rejects (e.g. wrong audience).
    store.credentials[_alice.sub] = StoredCredentials(
      accessToken: 'stale',
      refreshToken: 'refresh-1',
      expiresAt: DateTime.utc(2099),
    );
    renewResult = () => throw _auth0Error(status: 403);
    final adapter = FakeAdapter({
      'GET /app/me': FakeResponse(401, {'error': 'unauthorized'}),
    });
    final error = await failureOf(api(adapter));
    expect(error.isSessionExpired, isTrue);
    expect(adapter.requests, hasLength(1));
  });

  test('a 401 followed by a good renewal replays the request once', () async {
    store.credentials[_alice.sub] = StoredCredentials(
      accessToken: 'stale',
      refreshToken: 'refresh-1',
      expiresAt: DateTime.utc(2099),
    );
    renewResult = _renewed;
    var calls = 0;
    final adapter = FakeAdapter({
      'GET /app/me': () => ++calls == 1
          ? const FakeResponse(401, {})
          : const FakeResponse(200, {'ok': 1}),
    });
    final response = await api(adapter).get<Object?>('/app/me');
    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(2));
  });

  test(
    'no refresh token (or Auth0 not configured) is a dead session',
    () async {
      store.credentials[_alice.sub] = StoredCredentials(
        accessToken: 'old',
        expiresAt: DateTime.utc(2020),
      );
      await expectLater(
        auth.getValidAccessToken(_alice.sub),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(renewCalls, 0);
    },
  );

  test('expired token and NO refresh token: session_expired at once', () async {
    // The case that hung every request before the fix: no Auth0 call is even
    // possible, and nothing was ever told to send the user to sign-in.
    store.credentials[_alice.sub] = StoredCredentials(
      accessToken: 'old',
      expiresAt: DateTime.utc(2020),
    );
    final adapter = FakeAdapter({});
    final error = await failureOf(api(adapter));
    expect(error.isSessionExpired, isTrue);
    expect(adapter.requests, isEmpty);
    expect(renewCalls, 0);
  });

  testWidgets('app start with a dead stored session lands on sign-in', (
    tester,
  ) async {
    // Signed in locally, access token expired, nothing to renew it with.
    store.credentials[_alice.sub] = StoredCredentials(
      accessToken: 'old',
      expiresAt: DateTime.utc(2020),
    );
    final db = memoryDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const BpjApp(),
      ),
    );
    // Not pumpAndSettle: a spinner on the splash screen never settles.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(store.accounts, isEmpty, reason: 'the dead account was dropped');
    expect(find.text('Black Pear Joggers'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
