import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/diagnostics/diagnostics.dart';
import 'core/diagnostics/error_capture.dart';

/// Entry point, roughly `createRoot(...).render(<Providers><App /></Providers>)`.
/// `ProviderScope` holds all Riverpod state for the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Built by hand (instead of a plain ProviderScope) so the error handlers can
  // reach the diagnostics log before the first frame (D100).
  final container = ProviderContainer(observers: const [DiagnosticsObserver()]);
  final diagnostics = container.read(diagnosticsProvider);
  installGlobalErrorHandlers(diagnostics);
  installDatabaseHook(diagnostics);
  unawaited(recordStartup(diagnostics));
  runApp(
    UncontrolledProviderScope(container: container, child: const BpjApp()),
  );
}
