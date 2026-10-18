import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_exception.dart';
import '../db/app_database.dart';
import 'diagnostics.dart';
import 'redaction.dart';

/// Errors that are about the network or the server's answer. They are logged by
/// the API interceptor, so the other capture points skip them.
bool _isApiFailure(Object error) =>
    error is ApiException || error is DioException;

/// Records uncaught errors (Flutter framework + async) and then does exactly what
/// would have happened anyway (React: `window.onerror` + `unhandledrejection`, but
/// chaining the previous handler instead of replacing it).
void installGlobalErrorHandlers(Diagnostics diagnostics) {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    _recordLocal(diagnostics, 'ui', details.exception);
    // Keep the old behaviour: it prints in debug and reports in release.
    (previousFlutter ?? FlutterError.presentError)(details);
  };

  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    _recordLocal(diagnostics, 'async', error);
    // `false` = not handled here, so the engine reports it as before.
    return previousPlatform?.call(error, stack) ?? false;
  };
}

void _recordLocal(Diagnostics diagnostics, String where, Object error) {
  if (_isApiFailure(error)) return;
  diagnostics
    ..record(
      DiagArea.ui,
      'uncaught $where error: ${describeError(error)}',
      level: DiagLevel.error,
    )
    ..health.reportLocalError();
}

/// Also hear about providers that fail (a Drift stream that throws, a repository
/// that can't decode its data): that is where "every screen fails" shows up,
/// because screens catch the error and show a message instead of throwing it.
base class DiagnosticsObserver extends ProviderObserver {
  const DiagnosticsObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (_isApiFailure(error)) return;
    final diagnostics = context.container.read(diagnosticsProvider);
    _recordLocal(diagnostics, 'provider', error);
  }
}

/// The cold-start line: version, build and time (D100).
Future<void> recordStartup(Diagnostics diagnostics) async {
  String version;
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } on Object {
    version = 'unknown';
  }
  diagnostics.record(
    DiagArea.startup,
    'cold start, version $version${kDebugMode ? ' (debug)' : ''}',
  );
}

/// Routes the database's open/upgrade events into the log. The hook lives on
/// [AppDatabase] because the database has no access to providers.
void installDatabaseHook(Diagnostics diagnostics) {
  AppDatabase.onOpened = (details) {
    diagnostics.record(
      DiagArea.db,
      details.hadUpgrade
          ? 'db upgraded from ${details.versionBefore} to ${details.versionNow}'
          : details.wasCreated
          ? 'db created at version ${details.versionNow}'
          : 'db opened, version ${details.versionNow}',
    );
    diagnostics.health.reportLocalOk();
  };
}
