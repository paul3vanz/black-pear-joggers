import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Entry point, roughly `createRoot(...).render(<Providers><App /></Providers>)`.
/// `ProviderScope` holds all Riverpod state for the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BpjApp()));
}
