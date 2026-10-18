import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/diagnostics/diagnostics.dart';
import 'package:bpj/core/diagnostics/error_capture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  test(
    'FlutterError.onError records, then still runs the previous handler',
    () {
      final previous = FlutterError.onError;
      addTearDown(() => FlutterError.onError = previous);
      final seen = <Object>[];
      FlutterError.onError = (details) => seen.add(details.exception);

      final diag = Diagnostics();
      installGlobalErrorHandlers(diag);
      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('bad thing')),
      );

      expect(seen.single, isA<StateError>());
      expect(diag.entries.single.area, DiagArea.ui);
      expect(diag.entries.single.message, contains('StateError'));
      expect(diag.entries.single.level, DiagLevel.error);
    },
  );

  test('an uncaught async error is recorded and left unhandled', () {
    final previous = PlatformDispatcher.instance.onError;
    addTearDown(() => PlatformDispatcher.instance.onError = previous);
    PlatformDispatcher.instance.onError = null;

    final diag = Diagnostics();
    installGlobalErrorHandlers(diag);
    final handled = PlatformDispatcher.instance.onError!(
      TypeError(),
      StackTrace.empty,
    );

    expect(handled, isFalse, reason: 'the engine still reports it as before');
    expect(diag.entries.single.message, contains('TypeError'));
  });

  group('provider observer', () {
    late Diagnostics diag;
    late ProviderContainer container;

    setUp(() {
      diag = Diagnostics();
      container = ProviderContainer(
        observers: const [DiagnosticsObserver()],
        retry: (_, _) =>
            null, // Riverpod 3 retries failing providers by default
        overrides: [diagnosticsProvider.overrideWithValue(diag)],
      );
      addTearDown(container.dispose);
    });

    test(
      'a provider failing with a local error is logged and counted',
      () async {
        final bad = FutureProvider<int>(
          (ref) => throw StateError('cannot read'),
        );
        for (var i = 0; i < 3; i++) {
          container.invalidate(bad);
          await container.read(bad.future).then((_) {}, onError: (Object _) {});
        }
        expect(diag.entries.single.count, 3);
        expect(diag.health.state.unhealthy, isTrue);
      },
    );

    test('API failures are left to the interceptor', () async {
      final api = FutureProvider<int>(
        (ref) => throw const ApiException(message: 'nope', statusCode: 500),
      );
      await container.read(api.future).then((_) {}, onError: (Object _) {});
      expect(diag.entries, isEmpty);
    });
  });

  test('the database hook logs a migration and a plain open', () async {
    addTearDown(() => AppDatabase.onOpened = null);
    final diag = Diagnostics();
    installDatabaseHook(diag);

    final db = memoryDb();
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();

    expect(diag.entries.single.area, DiagArea.db);
    expect(diag.entries.single.message, startsWith('db created at version'));
  });
}
