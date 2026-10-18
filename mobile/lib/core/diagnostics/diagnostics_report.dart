import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/ui/profile_providers.dart';
import '../auth/accounts_controller.dart';
import '../config/club_config.dart';
import '../db/app_database.dart';
import 'diagnostics.dart';
import 'redaction.dart';

/// Gathers the facts a report needs from the rest of the app. Every lookup is
/// guarded: a broken database or a missing platform answer must not stop the
/// report, which is exactly what people send when things are broken.
Future<ReportInfo> collectReportInfo(
  Ref ref, {
  bool touchDatabase = true,
}) async {
  String? version;
  try {
    version = await ref.read(appVersionProvider.future);
  } on Object {
    // Platform channel unavailable (tests) or failed: "unknown".
  }

  final accounts = ref.read(accountsControllerProvider).value;
  final signedIn = accounts?.activeSub != null;

  int? schema;
  var lastSync = <String, String>{};
  if (signedIn) {
    try {
      final db = ref.read(appDatabaseProvider);
      // A constant: reading it does not open the file.
      schema = db.schemaVersion;
      if (touchDatabase) lastSync = await _lastSyncTimes(db);
    } on Object catch (e) {
      lastSync = {'(unavailable)': describeError(e)};
    }
  }

  return ReportInfo(
    appName: ref.read(clubConfigProvider).shortName,
    version: version,
    // e.g. "android Linux 6.1.99 #1 SMP PREEMPT". The model needs a plugin, so
    // it is left out.
    platform: redact(
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    ),
    schemaVersion: schema,
    signedIn: signedIn,
    clubId: accounts?.activeClubId,
    lastSync: lastSync,
  );
}

/// `SyncCursors` is also a tiny key/value store (last group choice, ...), so only
/// rows whose value is a timestamp count as "last sync", and ids in keys are masked.
Future<Map<String, String>> _lastSyncTimes(AppDatabase db) async {
  final rows = await db.select(db.syncCursors).get();
  final out = <String, String>{};
  for (final r in rows) {
    if (DateTime.tryParse(r.serverTime) == null) continue;
    if (out.length >= 15) break;
    out[safePath(r.key)] = r.serverTime;
  }
  return out;
}

/// Builds the report text. A provider so any screen (including `/recover`, which
/// passes `touchDatabase: false`) can call it with its own `ref`.
final reportTextProvider =
    Provider<Future<String> Function({bool touchDatabase})>(
      (ref) => ({bool touchDatabase = true}) async {
        final info = await collectReportInfo(ref, touchDatabase: touchDatabase);
        return ref.read(diagnosticsProvider).report(info);
      },
    );

/// The report as shown on the diagnostics screen; invalidate to rebuild it.
final diagnosticsReportProvider = FutureProvider.autoDispose<String>(
  (ref) => ref.read(reportTextProvider)(),
);
