import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/safety_repository.dart';

// Hand-written (not @riverpod), like the other providers over Drift streams.

/// The members the signed-in person has blocked in the active club, as
/// id -> display name. Empty until the saved list loads.
final blockedMembersProvider = StreamProvider<Map<String, String>>((ref) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  return ref
      .watch(safetyRepositoryProvider)
      .watchBlocked(ref.watch(activeClubIdProvider));
});

/// Just the blocked ids, for filtering lists.
final blockedIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(blockedMembersProvider).value?.keys.toSet() ?? const {},
);
