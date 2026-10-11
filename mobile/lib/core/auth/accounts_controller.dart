import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';
import '../notifications/push_service.dart';
import 'account.dart';
import 'account_store.dart';
import 'auth_service.dart';

part 'accounts_controller.g.dart';

/// Snapshot of who is signed in on this device.
class AccountsState {
  const AccountsState({
    required this.accounts,
    this.activeSub,
    this.activeClubId,
  });

  final List<Account> accounts;
  final String? activeSub;

  /// The club chosen for the active account (defaults to [Env.clubId]).
  final int? activeClubId;

  Account? get active {
    for (final a in accounts) {
      if (a.sub == activeSub) return a;
    }
    return null;
  }
}

/// Source of truth for accounts. React/TS equivalent: a Zustand store / React Query
/// mutation set. `AsyncNotifier` = state that is loaded asynchronously, exposed to
/// widgets as an `AsyncValue` (`{data, error, isLoading}`).
@Riverpod(keepAlive: true)
class AccountsController extends _$AccountsController {
  AccountStore get _store => ref.read(accountStoreProvider);
  AuthService get _auth => ref.read(authServiceProvider);

  @override
  Future<AccountsState> build() => _load();

  Future<AccountsState> _load() async {
    final accounts = await _store.readAccounts();
    var activeSub = await _store.readActiveSub();
    // Heal inconsistent storage: the active account must be one we actually have.
    if (activeSub == null || !accounts.any((a) => a.sub == activeSub)) {
      activeSub = accounts.isEmpty ? null : accounts.first.sub;
      await _store.writeActiveSub(activeSub);
    }
    final clubId = activeSub == null
        ? null
        : await _store.readActiveClubId(activeSub) ?? Env.clubId;
    return AccountsState(
      accounts: accounts,
      activeSub: activeSub,
      activeClubId: clubId,
    );
  }

  Future<void> _reload() async => state = AsyncData(await _load());

  /// Universal Login. Pass [addAccount] from "Add another account".
  Future<void> signIn({bool addAccount = false}) async {
    await _auth.login(addAccount: addAccount);
    await _reload();
  }

  /// Debug-only shortcut, see [AuthService.signInWithAccessToken].
  Future<void> signInWithAccessToken(String token) async {
    await _auth.signInWithAccessToken(token);
    await _reload();
  }

  Future<void> switchTo(String sub) async {
    await _store.writeActiveSub(sub);
    await _reload();
  }

  Future<void> setActiveClub(int clubId) async {
    final sub = state.value?.activeSub;
    if (sub == null) return;
    await _store.writeActiveClubId(sub, clubId);
    await _reload();
  }

  Future<void> remove(String sub) async {
    // Best effort, and before the credentials go: the DELETE needs them.
    await ref.read(pushServiceProvider).unregisterDevice(sub);
    await _auth.logout(sub);
    await _reload();
  }

  /// Called when renewal fails for good: drop the dead account locally.
  Future<void> sessionExpired(String sub) async {
    await _store.removeAccount(sub);
    await _reload();
  }
}

/// `sub` of the active account, or null when signed out. Everything account-scoped
/// (database, API client) watches this, so switching account rebuilds them.
@Riverpod(keepAlive: true)
String? activeSub(Ref ref) =>
    ref.watch(accountsControllerProvider).value?.activeSub;

@Riverpod(keepAlive: true)
Account? activeAccount(Ref ref) =>
    ref.watch(accountsControllerProvider).value?.active;
