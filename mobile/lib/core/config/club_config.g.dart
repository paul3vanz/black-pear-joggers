// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The club this build is for. Override in tests; later, white-label flavors return
/// their own [ClubConfig].

@ProviderFor(clubConfig)
final clubConfigProvider = ClubConfigProvider._();

/// The club this build is for. Override in tests; later, white-label flavors return
/// their own [ClubConfig].

final class ClubConfigProvider
    extends $FunctionalProvider<ClubConfig, ClubConfig, ClubConfig>
    with $Provider<ClubConfig> {
  /// The club this build is for. Override in tests; later, white-label flavors return
  /// their own [ClubConfig].
  ClubConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubConfigHash();

  @$internal
  @override
  $ProviderElement<ClubConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClubConfig create(Ref ref) {
    return clubConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubConfig>(value),
    );
  }
}

String _$clubConfigHash() => r'f616fb87af2266b14049860ea442f82b2519f44d';
