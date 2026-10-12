import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/config/env.dart';
import '../../../core/db/app_database.dart';
import 'member_dtos.dart';

part 'member_profile_repository.g.dart';

/// Joins the API base URL and a server-relative [path] such as
/// `/app/clubs/1/members/<id>/photo?v=ab&sig=cd`. Plain string joining on
/// purpose: the base has a path segment (`/api/public/index.php`) that
/// `Uri.resolve` would drop for a path starting with `/`. Null or empty -> null;
/// an absolute `http(s)` URL is returned unchanged.
String? joinApiUrl(String base, String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return path.startsWith('/') ? '$b$path' : '$b/$path';
}

/// The full URL of a member photo, or null when there is none.
String? memberPhotoUrl(String? photoPath) =>
    joinApiUrl(Env.apiBaseUrl, photoPath);

/// Member profile cards (Phase 6.5, D59-D63). Same shape as the other
/// repositories: the UI watches Drift streams. [refreshCards] keeps the small
/// cards table fresh (D61); profile pages and the caller's own card are fetched
/// online and cached, so they still open offline. Writes need a connection.
class MemberProfileRepository {
  MemberProfileRepository(
    this._db,
    this._dio, {
    DateTime Function()? clock,
    this.apiBaseUrl = Env.apiBaseUrl,
  }) : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// Prepended to a card's `photoPath` by [photoUrl].
  final String apiBaseUrl;

  /// Key of the caller's own card in the profiles table.
  static const ownKey = 'me';

  String _base(int clubId) => '/app/clubs/$clubId';

  /// Full URL for a server-relative photo path (null-safe).
  String? photoUrl(String? photoPath) => joinApiUrl(apiBaseUrl, photoPath);

  // --- Cards (D61) -------------------------------------------------------

  /// Replaces the club's cards with `GET …/member-cards` in one transaction.
  Future<void> refreshCards(int clubId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('${_base(clubId)}/member-cards'),
    );
    final items = jsonObject(response)['items'] as List<Object?>? ?? const [];
    final rows = <MemberCardsCompanion>[];
    for (final item in items) {
      final json = Map<String, Object?>.from(item! as Map);
      final roles = json['roles'] as List<Object?>? ?? const [];
      rows.add(
        MemberCardsCompanion.insert(
          memberId: json['memberId']! as String,
          clubId: clubId,
          displayName: json['displayName']! as String,
          photoPath: Value(json['photoPath'] as String?),
          rolesCsv: Value(roles.join(',')),
          hasBio: Value(json['hasBio'] as bool? ?? false),
        ),
      );
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.memberCards,
      )..where((c) => c.clubId.equals(clubId))).go();
      await _db.batch(
        (b) => b.insertAll(_db.memberCards, rows, mode: InsertMode.replace),
      );
    });
  }

  /// [refreshCards] where cards only decorate the screen: every failure but an
  /// expired session is ignored.
  Future<void> refreshCardsQuietly(int clubId) async {
    try {
      await refreshCards(clubId);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow;
    }
  }

  Stream<MemberCard?> watchCard(String memberId) => (_db.select(
    _db.memberCards,
  )..where((c) => c.memberId.equals(memberId))).watchSingleOrNull();

  /// Every cached card of the club by member id.
  Stream<Map<String, MemberCard>> watchCards(int clubId) =>
      (_db.select(_db.memberCards)..where((c) => c.clubId.equals(clubId)))
          .watch()
          .map((rows) => {for (final r in rows) r.memberId: r});

  // --- Other members' profiles -------------------------------------------

  Future<MemberProfileRow?> _cachedRow(int clubId, String key) =>
      (_db.select(_db.memberProfiles)
            ..where((p) => p.clubId.equals(clubId) & p.memberId.equals(key)))
          .getSingleOrNull();

  Future<void> _storeRow(int clubId, String key, Map<String, Object?> body) =>
      _db
          .into(_db.memberProfiles)
          .insertOnConflictUpdate(
            MemberProfilesCompanion.insert(
              memberId: key,
              clubId: clubId,
              json: jsonEncode(body),
              fetchedAt: _now(),
            ),
          );

  Map<String, Object?> _decode(MemberProfileRow row) =>
      Map<String, Object?>.from(jsonDecode(row.json) as Map);

  /// The cached profile of [memberId] as a stream (null until fetched once).
  Stream<MemberProfile?> watchProfile(int clubId, String memberId) =>
      (_db.select(_db.memberProfiles)..where(
            (p) => p.clubId.equals(clubId) & p.memberId.equals(memberId),
          ))
          .watchSingleOrNull()
          .map(
            (row) => row == null ? null : MemberProfile.fromJson(_decode(row)),
          );

  /// Fetches a member's profile and caches it. When the network is unreachable
  /// it returns the cached copy (`fromCache`), or throws
  /// [MemberOfflineException] if there is none. Other failures propagate as
  /// [ApiException]; a 404 also drops the cached copy (they are no longer an
  /// active member).
  Future<Fetched<MemberProfile>> fetchProfile(
    int clubId,
    String memberId,
  ) async {
    try {
      final response = await guardApi(
        () => _dio.get<Object?>('${_base(clubId)}/members/$memberId/profile'),
      );
      final body = jsonObject(response);
      await _storeRow(clubId, memberId, body);
      return Fetched(MemberProfile.fromJson(body), fetchedAt: _now());
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _dropRow(clubId, memberId);
      }
      if (!e.isNetworkError) rethrow;
      final row = await _cachedRow(clubId, memberId);
      if (row == null) throw const MemberOfflineException();
      return Fetched(
        MemberProfile.fromJson(_decode(row)),
        fromCache: true,
        fetchedAt: row.fetchedAt,
      );
    }
  }

  Future<void> _dropRow(int clubId, String key) => (_db.delete(
    _db.memberProfiles,
  )..where((p) => p.clubId.equals(clubId) & p.memberId.equals(key))).go();

  /// Committee/admin moderation (D63): clears the member's photo, bio and goals.
  Future<void> clearMemberProfile(int clubId, String memberId) async {
    await guardApi(
      () => _dio.delete<Object?>('${_base(clubId)}/members/$memberId/profile'),
    );
    await _dropRow(clubId, memberId);
    await refreshCardsQuietly(clubId);
  }

  // --- My own card ---------------------------------------------------------

  Stream<MyCard?> watchMine(int clubId) =>
      (_db.select(_db.memberProfiles)
            ..where((p) => p.clubId.equals(clubId) & p.memberId.equals(ownKey)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : MyCard.fromJson(_decode(row)));

  Future<MyCard> _storeMine(int clubId, Response<Object?> response) async {
    final body = jsonObject(response);
    await _storeRow(clubId, ownKey, body);
    return MyCard.fromJson(body);
  }

  /// Fetches the caller's own card and caches it; offline falls back to the
  /// cached copy like [fetchProfile].
  Future<Fetched<MyCard>> fetchMine(int clubId) async {
    try {
      final response = await guardApi(
        () => _dio.get<Object?>('${_base(clubId)}/member-profile'),
      );
      return Fetched(await _storeMine(clubId, response), fetchedAt: _now());
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      final row = await _cachedRow(clubId, ownKey);
      if (row == null) throw const MemberOfflineException();
      return Fetched(
        MyCard.fromJson(_decode(row)),
        fromCache: true,
        fetchedAt: row.fetchedAt,
      );
    }
  }

  /// Saves text fields. A `null` argument is left out of the request (left
  /// alone on the server); an empty string clears the field. Throws
  /// [ApiException] (`fieldErrors` for a 422, `isNetworkError` when offline).
  Future<MyCard> saveMine(
    int clubId, {
    String? bio,
    String? goals,
    bool? goalsVisible,
  }) async {
    final response = await guardApi(
      () => _dio.put<Object?>(
        '${_base(clubId)}/member-profile',
        // `?x` in a map literal = "include only when non-null" (like spreading
        // `...(bio != null && { bio })` in JS).
        data: {'bio': ?bio, 'goals': ?goals, 'goalsVisible': ?goalsVisible},
      ),
    );
    final card = await _storeMine(clubId, response);
    await refreshCardsQuietly(clubId);
    return card;
  }

  /// Uploads the already cropped and compressed JPEG (see `processProfilePhoto`).
  Future<MyCard> uploadPhoto(int clubId, Uint8List jpegBytes) async {
    final form = FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        jpegBytes,
        filename: 'photo.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });
    final response = await guardApi(
      () => _dio.put<Object?>(
        '${_base(clubId)}/member-profile/photo',
        data: form,
      ),
    );
    final card = await _storeMine(clubId, response);
    await refreshCardsQuietly(clubId);
    return card;
  }

  Future<MyCard> removePhoto(int clubId) async {
    final response = await guardApi(
      () => _dio.delete<Object?>('${_base(clubId)}/member-profile/photo'),
    );
    final card = await _storeMine(clubId, response);
    await refreshCardsQuietly(clubId);
    return card;
  }
}

@Riverpod(keepAlive: true)
MemberProfileRepository memberProfileRepository(Ref ref) =>
    MemberProfileRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(apiClientProvider),
    );
