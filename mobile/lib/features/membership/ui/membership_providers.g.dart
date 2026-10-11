// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The club the active account is looking at (defaults to this build's club).

@ProviderFor(activeClubId)
final activeClubIdProvider = ActiveClubIdProvider._();

/// The club the active account is looking at (defaults to this build's club).

final class ActiveClubIdProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The club the active account is looking at (defaults to this build's club).
  ActiveClubIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeClubIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeClubIdHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return activeClubId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeClubIdHash() => r'030481acefd61e83dcd3b5963978280f2932e3f4';

/// Runs `refreshMe()` once at app start and again whenever the active account
/// changes (it watches [activeSubProvider], so Riverpod rebuilds it, which re-runs
/// `build`). `state` is the status of that refresh. React equivalent: a
/// `useEffect(() => { refetch() }, [sub])` kept in a global store.

@ProviderFor(MeSync)
final meSyncProvider = MeSyncProvider._();

/// Runs `refreshMe()` once at app start and again whenever the active account
/// changes (it watches [activeSubProvider], so Riverpod rebuilds it, which re-runs
/// `build`). `state` is the status of that refresh. React equivalent: a
/// `useEffect(() => { refetch() }, [sub])` kept in a global store.
final class MeSyncProvider extends $NotifierProvider<MeSync, MeSyncStatus> {
  /// Runs `refreshMe()` once at app start and again whenever the active account
  /// changes (it watches [activeSubProvider], so Riverpod rebuilds it, which re-runs
  /// `build`). `state` is the status of that refresh. React equivalent: a
  /// `useEffect(() => { refetch() }, [sub])` kept in a global store.
  MeSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meSyncHash();

  @$internal
  @override
  MeSync create() => MeSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeSyncStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeSyncStatus>(value),
    );
  }
}

String _$meSyncHash() => r'7beabbe27b1545f47dcb292f3f81d2470a0c82a3';

/// Runs `refreshMe()` once at app start and again whenever the active account
/// changes (it watches [activeSubProvider], so Riverpod rebuilds it, which re-runs
/// `build`). `state` is the status of that refresh. React equivalent: a
/// `useEffect(() => { refetch() }, [sub])` kept in a global store.

abstract class _$MeSync extends $Notifier<MeSyncStatus> {
  MeSyncStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MeSyncStatus, MeSyncStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MeSyncStatus, MeSyncStatus>,
              MeSyncStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// "Does this account need to link its membership?" Answered from the cache as soon
/// as it has rows, otherwise once the first `/app/me` refresh has finished.

@ProviderFor(linkStatus)
final linkStatusProvider = LinkStatusProvider._();

/// "Does this account need to link its membership?" Answered from the cache as soon
/// as it has rows, otherwise once the first `/app/me` refresh has finished.

final class LinkStatusProvider
    extends $FunctionalProvider<LinkStatus, LinkStatus, LinkStatus>
    with $Provider<LinkStatus> {
  /// "Does this account need to link its membership?" Answered from the cache as soon
  /// as it has rows, otherwise once the first `/app/me` refresh has finished.
  LinkStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkStatusHash();

  @$internal
  @override
  $ProviderElement<LinkStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LinkStatus create(Ref ref) {
    return linkStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkStatus>(value),
    );
  }
}

String _$linkStatusHash() => r'b85475e35ceb8d8ee794e90ef9b5749af117b716';
