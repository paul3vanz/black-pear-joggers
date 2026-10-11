// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider ≈ a module-level singleton you can swap in tests
/// (`ProviderScope(overrides: [...])` is like wrapping a component in a test Context).

@ProviderFor(accountStore)
final accountStoreProvider = AccountStoreProvider._();

/// Riverpod provider ≈ a module-level singleton you can swap in tests
/// (`ProviderScope(overrides: [...])` is like wrapping a component in a test Context).

final class AccountStoreProvider
    extends $FunctionalProvider<AccountStore, AccountStore, AccountStore>
    with $Provider<AccountStore> {
  /// Riverpod provider ≈ a module-level singleton you can swap in tests
  /// (`ProviderScope(overrides: [...])` is like wrapping a component in a test Context).
  AccountStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStoreHash();

  @$internal
  @override
  $ProviderElement<AccountStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountStore create(Ref ref) {
    return accountStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountStore>(value),
    );
  }
}

String _$accountStoreHash() => r'a6eadf4f1d29a96a3c5e513486553373e628627f';
