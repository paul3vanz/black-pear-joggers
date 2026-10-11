// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'runs_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(runsRepository)
final runsRepositoryProvider = RunsRepositoryProvider._();

final class RunsRepositoryProvider
    extends $FunctionalProvider<RunsRepository, RunsRepository, RunsRepository>
    with $Provider<RunsRepository> {
  RunsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runsRepositoryHash();

  @$internal
  @override
  $ProviderElement<RunsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RunsRepository create(Ref ref) {
    return runsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunsRepository>(value),
    );
  }
}

String _$runsRepositoryHash() => r'1b9c6537091ec8f534f174ca54d05226a98a2e95';
