import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../data/profile_repository.dart';

part 'profile_providers.g.dart';

/// Live cached profile for a club (null until the first successful refresh).
/// `.family` makes one instance per argument, like a React Query key
/// `['profile', clubId]`. Hand-written because riverpod_generator can't reference
/// Drift's generated `Profile` class.
final profileProvider = StreamProvider.family<Profile?, int>(
  (ref, clubId) => ref.watch(profileRepositoryProvider).watchProfile(clubId),
);

/// "1.0.0 (1)" for the footer. A provider so tests can skip the platform channel.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}
