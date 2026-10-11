import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_expiry.dart';
import '../core/config/club_config.dart';
import '../core/notifications/push_service.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget: the router plus light and dark themes.
class BpjApp extends ConsumerWidget {
  const BpjApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instantiates push (a no-op unless Firebase is configured).
    ref.watch(pushServiceProvider);
    return MaterialApp.router(
      title: ref.watch(clubConfigProvider).shortName,
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
      theme: BpjTheme.light,
      darkTheme: BpjTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
