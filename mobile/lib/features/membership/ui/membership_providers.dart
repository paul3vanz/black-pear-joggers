import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/config/env.dart';
import '../../../core/db/app_database.dart';
import '../data/membership_repository.dart';

part 'membership_providers.g.dart';

/// The club the active account is looking at (defaults to this build's club).
@Riverpod(keepAlive: true)
int activeClubId(Ref ref) =>
    ref.watch(accountsControllerProvider).value?.activeClubId ?? Env.clubId;

/// All cached memberships as a live stream. Stays in the loading state while signed
/// out (there is no database then). Switching account rebuilds it, because the
/// repository depends on the per-account database.
///
/// Hand-written (not `@riverpod`): riverpod_generator can't see Drift's generated
/// row classes (`Membership`) while it runs, so it can't emit code mentioning them.
final membershipsProvider = StreamProvider<List<Membership>>((ref) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  return ref.watch(membershipRepositoryProvider).watchMemberships();
});

/// The membership for the active club, or null if the account isn't linked to it
/// (or the cache hasn't loaded yet; use [linkStatus] to tell the difference).
final activeMembershipProvider = Provider<Membership?>((ref) {
  final clubId = ref.watch(activeClubIdProvider);
  final list = ref.watch(membershipsProvider).value;
  if (list == null) return null;
  for (final m in list) {
    if (m.clubId == clubId) return m;
  }
  return null;
});

/// Progress of the `/app/me` refresh for the active account.
enum MeSyncStatus { idle, loading, done, failed }

/// Runs `refreshMe()` once at app start and again whenever the active account
/// changes (it watches [activeSubProvider], so Riverpod rebuilds it, which re-runs
/// `build`). `state` is the status of that refresh. React equivalent: a
/// `useEffect(() => { refetch() }, [sub])` kept in a global store.
@Riverpod(keepAlive: true)
class MeSync extends _$MeSync {
  @override
  MeSyncStatus build() {
    final sub = ref.watch(activeSubProvider);
    if (sub == null) return MeSyncStatus.idle;
    // Start after build returns: a provider can't change its own state mid-build.
    unawaited(Future.microtask(() => _run(sub)));
    return MeSyncStatus.loading;
  }

  /// Retry (e.g. the "try again" button on the offline screen).
  Future<void> retry() async {
    final sub = ref.read(activeSubProvider);
    if (sub == null) return;
    state = MeSyncStatus.loading;
    await _run(sub);
  }

  /// Call after something other than `refreshMe` has told us the true state of
  /// the memberships (unlink, or a 403 `not_a_member` from the profile endpoint).
  void markSynced() {
    if (state != MeSyncStatus.idle) state = MeSyncStatus.done;
  }

  /// False once this notifier was disposed or the active account moved on.
  bool _isCurrent(String sub) =>
      ref.mounted && ref.read(activeSubProvider) == sub;

  Future<void> _run(String sub) async {
    // Capture before awaiting: after a rebuild `ref` belongs to a newer run.
    final repo = ref.read(membershipRepositoryProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await repo.refreshMe();
      if (_isCurrent(sub)) state = MeSyncStatus.done;
    } on Object catch (e) {
      if (await handleExpiry(sub, e)) return;
      // Offline or server trouble: cached data (if any) keeps working.
      if (_isCurrent(sub)) state = MeSyncStatus.failed;
    }
  }
}

/// Where the router should send a signed-in user.
enum LinkStatus {
  /// Not enough information yet: show the splash screen.
  unknown,

  /// The active club has a membership.
  linked,

  /// No membership for the active club: show the link flow.
  needsLink,

  /// First load failed and there is no cache, so we can't tell. Offer a retry.
  unavailable,
}

/// "Does this account need to link its membership?" Answered from the cache as soon
/// as it has rows, otherwise once the first `/app/me` refresh has finished.
@Riverpod(keepAlive: true)
LinkStatus linkStatus(Ref ref) {
  if (ref.watch(activeSubProvider) == null) return LinkStatus.unknown;
  // Always watched, so the refresh starts at app start even when the cache is full.
  final sync = ref.watch(meSyncProvider);
  final list = ref.watch(membershipsProvider).value;
  if (list == null) return LinkStatus.unknown;
  final clubId = ref.watch(activeClubIdProvider);
  if (list.any((m) => m.clubId == clubId)) return LinkStatus.linked;
  // Cached memberships exist, but none for this club.
  if (list.isNotEmpty) return LinkStatus.needsLink;
  return switch (sync) {
    MeSyncStatus.done => LinkStatus.needsLink,
    MeSyncStatus.failed => LinkStatus.unavailable,
    MeSyncStatus.idle || MeSyncStatus.loading => LinkStatus.unknown,
  };
}
