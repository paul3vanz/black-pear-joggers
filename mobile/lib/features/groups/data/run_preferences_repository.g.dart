// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_preferences_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(runPreferencesRepository)
final runPreferencesRepositoryProvider = RunPreferencesRepositoryProvider._();

final class RunPreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          RunPreferencesRepository,
          RunPreferencesRepository,
          RunPreferencesRepository
        >
    with $Provider<RunPreferencesRepository> {
  RunPreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runPreferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runPreferencesRepositoryHash();

  @$internal
  @override
  $ProviderElement<RunPreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RunPreferencesRepository create(Ref ref) {
    return runPreferencesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunPreferencesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunPreferencesRepository>(value),
    );
  }
}

String _$runPreferencesRepositoryHash() =>
    r'a8a91225212ca4b10b5e63156d8f6cf0629bdb7b';
