// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Source of truth for accounts. React/TS equivalent: a Zustand store / React Query
/// mutation set. `AsyncNotifier` = state that is loaded asynchronously, exposed to
/// widgets as an `AsyncValue` (`{data, error, isLoading}`).

@ProviderFor(AccountsController)
final accountsControllerProvider = AccountsControllerProvider._();

/// Source of truth for accounts. React/TS equivalent: a Zustand store / React Query
/// mutation set. `AsyncNotifier` = state that is loaded asynchronously, exposed to
/// widgets as an `AsyncValue` (`{data, error, isLoading}`).
final class AccountsControllerProvider
    extends $AsyncNotifierProvider<AccountsController, AccountsState> {
  /// Source of truth for accounts. React/TS equivalent: a Zustand store / React Query
  /// mutation set. `AsyncNotifier` = state that is loaded asynchronously, exposed to
  /// widgets as an `AsyncValue` (`{data, error, isLoading}`).
  AccountsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsControllerHash();

  @$internal
  @override
  AccountsController create() => AccountsController();
}

String _$accountsControllerHash() =>
    r'1b1074d99565b26806196192cadcf1c58c83cd20';

/// Source of truth for accounts. React/TS equivalent: a Zustand store / React Query
/// mutation set. `AsyncNotifier` = state that is loaded asynchronously, exposed to
/// widgets as an `AsyncValue` (`{data, error, isLoading}`).

abstract class _$AccountsController extends $AsyncNotifier<AccountsState> {
  FutureOr<AccountsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AccountsState>, AccountsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountsState>, AccountsState>,
              AsyncValue<AccountsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `sub` of the active account, or null when signed out. Everything account-scoped
/// (database, API client) watches this, so switching account rebuilds them.

@ProviderFor(activeSub)
final activeSubProvider = ActiveSubProvider._();

/// `sub` of the active account, or null when signed out. Everything account-scoped
/// (database, API client) watches this, so switching account rebuilds them.

final class ActiveSubProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// `sub` of the active account, or null when signed out. Everything account-scoped
  /// (database, API client) watches this, so switching account rebuilds them.
  ActiveSubProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSubProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSubHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return activeSub(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeSubHash() => r'865010e2f1553d05d5447cb5bbba874eef10d1e0';

@ProviderFor(activeAccount)
final activeAccountProvider = ActiveAccountProvider._();

final class ActiveAccountProvider
    extends $FunctionalProvider<Account?, Account?, Account?>
    with $Provider<Account?> {
  ActiveAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAccountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAccountHash();

  @$internal
  @override
  $ProviderElement<Account?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Account? create(Ref ref) {
    return activeAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Account? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Account?>(value),
    );
  }
}

String _$activeAccountHash() => r'9b6890d905ad167c60a45d531ff4c78c8bc1d1f5';
