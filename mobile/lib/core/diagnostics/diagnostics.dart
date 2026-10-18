import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'health.dart';
import 'redaction.dart';

/// Where an event came from.
enum DiagArea { api, auth, db, startup, ui, push }

enum DiagLevel { info, warn, error }

/// One line of the diagnostics log. Only ever holds scrubbed text (see
/// `redaction.dart`): a short message, an optional HTTP status and a path with no
/// query string. Never a body, token, email or name.
class DiagEntry {
  const DiagEntry({
    required this.time,
    required this.level,
    required this.area,
    required this.message,
    this.status,
    this.path,
    this.count = 1,
    this._lastTime,
  });

  /// First time this event happened (UTC).
  final DateTime time;

  /// Last time, when [count] > 1 (same event repeated).
  DateTime get lastTime => _lastTime ?? time;
  final DateTime? _lastTime;

  final DiagLevel level;
  final DiagArea area;
  final String message;
  final int? status;
  final String? path;
  final int count;

  DiagEntry repeated(DateTime at) => DiagEntry(
    time: time,
    lastTime: at,
    level: level,
    area: area,
    message: message,
    status: status,
    path: path,
    count: count + 1,
  );

  Map<String, Object?> toJson() => {
    't': time.toUtc().toIso8601String(),
    if (_lastTime != null) 'l': _lastTime.toUtc().toIso8601String(),
    'lv': level.name,
    'a': area.name,
    'm': message,
    if (status != null) 's': status,
    if (path != null) 'p': path,
    if (count > 1) 'n': count,
  };

  /// Throws on anything malformed; [Diagnostics] drops the whole log then.
  factory DiagEntry.fromJson(Map<String, Object?> j) => DiagEntry(
    time: DateTime.parse(j['t']! as String).toUtc(),
    lastTime: j['l'] == null ? null : DateTime.parse(j['l']! as String).toUtc(),
    level: DiagLevel.values.byName(j['lv']! as String),
    area: DiagArea.values.byName(j['a']! as String),
    message: j['m']! as String,
    status: j['s'] as int?,
    path: j['p'] as String?,
    count: (j['n'] as int?) ?? 1,
  );

  /// `2026-10-17T09:30:00Z  WARN   api      GET /app/me -> 500  request failed (x3)`
  String format() {
    final t = '${time.toIso8601String().split('.').first}Z';
    final what = [?path, if (status != null) '-> $status'].join(' ');
    return '$t  ${level.name.toUpperCase().padRight(5)}  '
        '${area.name.padRight(7)}  '
        '${what.isEmpty ? '' : '$what  '}$message'
        '${count > 1 ? '  (x$count)' : ''}';
  }
}

/// Where the log is kept between launches. A seam so tests don't touch disk.
abstract class DiagnosticsStorage {
  Future<String?> read();
  Future<void> write(String contents);
  Future<void> delete();
}

/// One small JSON file in the app's support directory.
class FileDiagnosticsStorage implements DiagnosticsStorage {
  FileDiagnosticsStorage([this._override]);

  final Future<File> Function()? _override;

  Future<File> _file() async {
    final override = _override;
    if (override != null) return override();
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'diagnostics.json'));
  }

  @override
  Future<String?> read() async {
    final f = await _file();
    return f.existsSync() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async =>
      (await _file()).writeAsString(contents, flush: true);

  @override
  Future<void> delete() async {
    final f = await _file();
    if (f.existsSync()) await f.delete();
  }
}

/// A persistent ring buffer of the last [capacity] app events, plus the plain-text
/// report built from it (D100).
///
/// * `record()` is synchronous and never throws, so it is safe to call from a
///   `catch` or an error handler.
/// * The log is loaded lazily from [storage] and written back a couple of seconds
///   after the last change (debounced), so a burst of failures costs one write.
/// * A corrupt or unreadable file is discarded silently.
class Diagnostics {
  Diagnostics({
    this._storage,
    DateTime Function()? now,
    this.capacity = 100,
    this.debounce = const Duration(seconds: 2),
    this.collapseWindow = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now {
    health = HealthTracker(now: _now);
  }

  final DiagnosticsStorage? _storage;
  final DateTime Function() _now;
  final int capacity;
  final Duration debounce;
  final Duration collapseWindow;

  /// "Is everything failing?" state, fed by the API interceptor and error handlers.
  late final HealthTracker health;

  /// Oldest first.
  final List<DiagEntry> _entries = [];
  Timer? _timer;
  Future<void>? _loading;
  bool _dirty = false;

  /// Small facts for the report header (e.g. `Database schema`), set as learnt.
  final Map<String, String> facts = {};

  List<DiagEntry> get entries => List.unmodifiable(_entries);

  /// Loads the saved log (once). Entries recorded before it finished are kept
  /// after the loaded ones.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final storage = _storage;
    if (storage == null) return;
    try {
      final raw = await storage.read();
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<Object?>;
      final loaded = [
        for (final item in list)
          DiagEntry.fromJson(Map<String, Object?>.from(item! as Map)),
      ];
      _entries.insertAll(0, loaded);
      _trim();
    } on Object {
      // Corrupt or unreadable: start again with an empty log.
      try {
        await storage.delete();
      } on Object {
        // Nothing more we can do.
      }
    }
  }

  /// Adds an event. [message] and [path] are scrubbed here, so callers can't
  /// forget. Repeats of the same event (area, level, message, status, path)
  /// within [collapseWindow] become a counter on the existing line.
  void record(
    DiagArea area,
    String message, {
    DiagLevel level = DiagLevel.info,
    int? status,
    String? path,
  }) {
    try {
      final now = _now().toUtc();
      final cleanMessage = redact(message);
      final cleanPath = path == null ? null : safePath(path);
      for (var i = _entries.length - 1; i >= 0; i--) {
        final e = _entries[i];
        if (now.difference(e.lastTime) > collapseWindow) break;
        if (e.area == area &&
            e.level == level &&
            e.message == cleanMessage &&
            e.status == status &&
            e.path == cleanPath) {
          _entries[i] = e.repeated(now);
          _schedule();
          return;
        }
      }
      _entries.add(
        DiagEntry(
          time: now,
          level: level,
          area: area,
          message: cleanMessage,
          status: status,
          path: cleanPath,
        ),
      );
      _trim();
      _schedule();
    } on Object {
      // The log must never be the thing that breaks the app.
    }
  }

  void _trim() {
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
  }

  void _schedule() {
    if (_storage == null) return;
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Writes the log now (also what the debounce timer calls).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final storage = _storage;
    if (storage == null || !_dirty) return;
    _dirty = false;
    try {
      await load();
      await storage.write(jsonEncode([for (final e in _entries) e.toJson()]));
    } on Object {
      // Disk full or similar: keep going in memory.
    }
  }

  void clear() {
    _entries.clear();
    _timer?.cancel();
    _timer = null;
    _dirty = false;
    final storage = _storage;
    if (storage != null) {
      unawaited(storage.delete().then((_) {}, onError: (Object _) {}));
    }
  }

  void dispose() => _timer?.cancel();

  /// The plain-text report. [info] carries what lives in other providers.
  String report(ReportInfo info) {
    final b = StringBuffer()
      ..writeln('${info.appName} diagnostics report')
      ..writeln('Generated: ${_now().toUtc().toIso8601String()}')
      ..writeln('App version: ${info.version ?? 'unknown'}')
      ..writeln('Platform: ${info.platform}')
      ..writeln('Database schema: ${info.schemaVersion ?? 'unknown'}')
      ..writeln('Signed in: ${info.signedIn ? 'yes' : 'no'}')
      ..writeln('Active club: ${info.clubId ?? 'none'}');
    for (final f in {...facts, ...info.extra}.entries) {
      b.writeln('${f.key}: ${f.value}');
    }
    if (info.lastSync.isNotEmpty) {
      b.writeln('Last successful sync:');
      for (final s in info.lastSync.entries) {
        b.writeln('  ${s.key}: ${s.value}');
      }
    }
    b
      ..writeln()
      ..writeln('Events (newest first, times in UTC):');
    if (_entries.isEmpty) b.writeln('  (none)');
    for (final e in _entries.reversed) {
      b.writeln(e.format());
    }
    return b.toString();
  }
}

/// What a report needs that lives in other providers.
class ReportInfo {
  const ReportInfo({
    required this.appName,
    this.version,
    required this.platform,
    this.schemaVersion,
    this.signedIn = false,
    this.clubId,
    this.lastSync = const {},
    this.extra = const {},
  });

  final String appName;
  final String? version;
  final String platform;
  final int? schemaVersion;
  final bool signedIn;
  final int? clubId;

  /// Repository name -> last cursor value (the server time of its last sync).
  final Map<String, String> lastSync;
  final Map<String, String> extra;
}

/// The one log for the app. Process-wide, so it is kept alive and survives
/// account switches. `flutter test` sets `FLUTTER_TEST`, and then the log stays
/// in memory (no disk, and no Timer left pending at the end of a widget test).
final diagnosticsProvider = Provider<Diagnostics>((ref) {
  final inTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  final d = Diagnostics(storage: inTest ? null : FileDiagnosticsStorage());
  unawaited(d.load());
  ref.onDispose(d.dispose);
  return d;
});

/// The health state for the "Something's not working" banner.
final healthProvider = Provider<ValueListenable<HealthState>>(
  (ref) => ref.watch(diagnosticsProvider).health.listenable,
);
