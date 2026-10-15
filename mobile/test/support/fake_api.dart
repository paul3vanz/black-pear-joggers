import 'dart:convert';
import 'dart:typed_data';

import 'package:bpj/core/db/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';

/// A canned response for the fake HTTP layer.
class FakeResponse {
  const FakeResponse(this.status, [this.body, this.headers = const {}]);

  final int status;
  final Object? body;

  /// Extra response headers, e.g. `{"etag": "\"abc\""}`.
  final Map<String, String> headers;
}

/// Stands in for the network: dio's `HttpClientAdapter` is the lowest layer, so
/// everything above it (interceptors, JSON decoding, error mapping) runs for real.
/// TS equivalent: msw / nock.
///
/// Routes are keyed `"GET /app/me"`. A value may be a [FakeResponse], or a
/// `FakeResponse Function()` for responses that change between calls.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);

  final Map<String, Object> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = routes['${options.method} ${options.path}'];
    if (route == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'no fake route for ${options.method} ${options.path}',
      );
    }
    final response = route is FakeResponse
        ? route
        : (route as FakeResponse Function())();
    final body = response.body;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final h in response.headers.entries) h.key: [h.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A dio with the fake adapter. No auth interceptor: repositories turn
/// `DioException`s into `ApiException` themselves.
Dio fakeDio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://test.invalid'))
      ..httpClientAdapter = adapter;

/// A fresh in-memory SQLite database with the app schema.
AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

/// Fixtures matching docs/api-contract.md.
Map<String, Object?> membershipJson({
  String memberId = 'member-1',
  String status = 'active',
  List<String> roles = const [],
  String firstName = 'Jo',
}) => {
  'memberId': memberId,
  'club': {
    'id': 1,
    'name': 'Black Pear Joggers',
    'slug': 'bpj',
    'joinUrl': 'https://bpj.org.uk/membership',
  },
  'status': status,
  'roles': roles,
  'athlete': {
    'id': 123,
    'firstName': firstName,
    'lastName': 'Bloggs',
    'gender': 'W',
    'category': 'V40',
  },
};

Map<String, Object?> meJson(List<Map<String, Object?>> memberships) => {
  'userId': 'google-oauth2|1234',
  'memberships': memberships,
  'clubs': <Object?>[],
};

Map<String, Object?> profileJson({
  String memberId = 'member-1',
  String status = 'active',
}) => {
  'memberId': memberId,
  'status': status,
  'roles': <String>['leader'],
  'athlete': {
    'id': 123,
    'athleteId': 450606,
    'po10Guid': null,
    'firstName': 'Jo',
    'lastName': 'Bloggs',
    'gender': 'W',
    'category': 'V40',
    'active': true,
    'affiliated': true,
  },
  'membership': {
    'competitiveRegStatus': 'Registered',
    'firstClaimClubName': 'Black Pear Joggers',
  },
  'links': {
    'results': 'https://apps.bpj.org.uk/race-results/#/athlete/450606',
    'powerOf10': null,
    'claimAward': 'https://bpj.org.uk/claim-award',
  },
};
