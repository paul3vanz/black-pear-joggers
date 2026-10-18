import 'dart:convert';

import 'package:bpj/core/api/api_client.dart';
import 'package:bpj/core/auth/auth_service.dart';
import 'package:bpj/core/diagnostics/diagnostics.dart';
import 'package:bpj/core/diagnostics/diagnostics_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Always hands out the same token, or throws what it is told to.
class _FakeAuth implements AuthService {
  _FakeAuth({this.failWith});

  final Object? failWith;

  @override
  Future<String> getValidAccessToken(
    String sub, {
    bool forceRenew = false,
  }) async {
    if (failWith != null) throw failWith!;
    return 'secret-token-value';
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void main() {
  late Diagnostics diag;
  late FakeAdapter adapter;
  late Dio dio;

  setUp(() {
    diag = Diagnostics();
    adapter = FakeAdapter({
      'GET /ok': const FakeResponse(200, {'fine': true}),
      'GET /boom': const FakeResponse(500, {
        'error': 'server_error',
        'message': 'Secret body text for jo@example.com',
      }),
      'GET /missing': const FakeResponse(404, {'error': 'not_found'}),
      'POST /unauthorized': const FakeResponse(401, {'error': 'nope'}),
    });
    dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'))
      ..httpClientAdapter = adapter
      ..interceptors.add(DiagnosticsInterceptor(diag));
  });

  Future<void> hit(String path, {Map<String, Object?>? query}) async {
    try {
      await dio.get<Object?>(path, queryParameters: query);
    } on DioException {
      // expected for failures
    }
  }

  test(
    'a failed request logs method, path and status, never query or body',
    () async {
      await hit('/boom', query: {'token': 'abc123', 'email': 'jo@example.com'});

      final e = diag.entries.single;
      expect(e.area, DiagArea.api);
      expect(e.level, DiagLevel.error);
      expect(e.status, 500);
      expect(e.path, '/boom');
      expect(e.message, 'GET failed: server error');
      final all = diag.report(const ReportInfo(appName: 'BPJ', platform: 'x'));
      expect(all, isNot(contains('abc123')));
      expect(all, isNot(contains('example.com')));
      expect(all, isNot(contains('Secret body')));
    },
  );

  test(
    'network errors are labelled as such (no fake route = connectionError)',
    () async {
      await hit('/nowhere');
      expect(diag.entries.single.message, 'GET failed: network');
      expect(diag.entries.single.status, isNull);
    },
  );

  test('the first success after a failure logs "recovered", once', () async {
    await hit('/boom');
    await hit('/ok');
    await hit('/ok');
    final messages = diag.entries.map((e) => e.message).toList();
    expect(messages, hasLength(2));
    expect(messages.last, startsWith('recovered'));
  });

  test('no failure before means no recovered line', () async {
    await hit('/ok');
    expect(diag.entries, isEmpty);
  });

  test('duplicate failures collapse into a counter', () async {
    for (var i = 0; i < 5; i++) {
      await hit('/boom');
    }
    expect(diag.entries, hasLength(1));
    expect(diag.entries.single.count, 5);
  });

  test(
    '401 is logged but never feeds the health banner; 4xx neither',
    () async {
      for (var i = 0; i < 6; i++) {
        try {
          await dio.post<Object?>('/unauthorized');
        } on DioException {
          // expected
        }
        await hit('/missing');
      }
      expect(diag.health.state.unhealthy, isFalse);
    },
  );

  test('offline never feeds the health banner', () async {
    for (var i = 0; i < 8; i++) {
      await hit('/nowhere');
    }
    expect(diag.health.state.unhealthy, isFalse);
  });

  test(
    'four 5xx in a row trip the health state; a success clears it',
    () async {
      for (var i = 0; i < 4; i++) {
        await hit('/boom');
      }
      expect(diag.health.state.unhealthy, isTrue);
      await hit('/ok');
      expect(diag.health.state.unhealthy, isFalse);
    },
  );

  group('through buildApiClient', () {
    test('session expiry and token failures reach the log', () async {
      final expired = buildApiClient(
        auth: _FakeAuth(failWith: const SessionExpiredException('auth0|x')),
        sub: 'auth0|x',
        diagnostics: diag,
      )..httpClientAdapter = adapter;
      await expectLater(
        expired.get<Object?>('/ok'),
        throwsA(isA<DioException>()),
      );

      final e = diag.entries.single;
      expect(e.area, DiagArea.auth);
      expect(e.message, 'session_expired');
      expect(e.status, 401);
      expect(e.path, '/ok');
    });

    test('the bearer token never appears in the log', () async {
      final client = buildApiClient(
        auth: _FakeAuth(),
        sub: 'auth0|x',
        diagnostics: diag,
      )..httpClientAdapter = adapter;
      await expectLater(
        client.get<Object?>('/boom'),
        throwsA(isA<DioException>()),
      );

      final dump = jsonEncode([for (final e in diag.entries) e.toJson()]);
      expect(dump, isNot(contains('secret-token-value')));
      expect(dump, isNot(contains('auth0|x')));
      expect(diag.entries.single.status, 500);
    });
  });
}
