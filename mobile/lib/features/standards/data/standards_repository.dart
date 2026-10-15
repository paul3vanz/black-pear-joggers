import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import 'standards_dtos.dart';

part 'standards_repository.g.dart';

/// The cached standards document and when the server last confirmed it.
class CachedStandards {
  const CachedStandards({required this.data, required this.fetchedAt});

  final StandardsData data;
  final DateTime fetchedAt;
}

/// Cache-first club standards (Phase 9b, D90). The screen watches [watch];
/// [refresh] revalidates with the stored ETag, so an unchanged table costs a
/// body-less 304. The whole response is kept as JSON text in one row, because
/// the table is read as a whole and never queried by column.
class StandardsRepository {
  StandardsRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// The cached document, or null until the first successful refresh. A row
  /// that no longer parses (should not happen) counts as no cache.
  Stream<CachedStandards?> watch(int clubId) => (_db.select(
    _db.standardsCache,
  )..where((c) => c.clubId.equals(clubId))).watchSingleOrNull().map(_decode);

  CachedStandards? _decode(StandardsCacheRow? row) {
    if (row == null) return null;
    try {
      final json = jsonDecode(row.bodyJson);
      if (json is! Map) return null;
      return CachedStandards(
        data: StandardsData.fromJson(Map<String, Object?>.from(json)),
        fetchedAt: row.fetchedAt,
      );
    } on FormatException {
      return null;
    }
  }

  /// Pulls the document. Sends `If-None-Match` when a tag is stored: a 304
  /// keeps the cached body and only moves `fetchedAt`; a 200 replaces both body
  /// and tag. Throws `ApiException` (network errors included) and leaves the
  /// cache untouched.
  Future<void> refresh(int clubId) async {
    final cached = await (_db.select(
      _db.standardsCache,
    )..where((c) => c.clubId.equals(clubId))).getSingleOrNull();
    final etag = cached?.etag;
    final response = await guardApi(
      () => _dio.get<Object?>(
        '/app/clubs/$clubId/standards',
        options: Options(
          headers: {'If-None-Match': ?etag},
          // dio treats 304 as an error unless told otherwise.
          validateStatus: (s) =>
              s != null && ((s >= 200 && s < 300) || s == 304),
        ),
      ),
    );
    final now = _now();
    if (response.statusCode == 304) {
      if (cached != null) {
        await (_db.update(_db.standardsCache)
              ..where((c) => c.clubId.equals(clubId)))
            .write(StandardsCacheCompanion(fetchedAt: Value(now)));
      }
      return;
    }
    final body = jsonObject(response);
    await _db
        .into(_db.standardsCache)
        .insertOnConflictUpdate(
          StandardsCacheCompanion.insert(
            clubId: Value(clubId),
            bodyJson: jsonEncode(body),
            etag: Value(response.headers.value('etag')),
            fetchedAt: now,
          ),
        );
  }
}

@Riverpod(keepAlive: true)
StandardsRepository standardsRepository(Ref ref) => StandardsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
