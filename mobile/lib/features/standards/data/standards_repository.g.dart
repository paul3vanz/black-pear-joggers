// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standards_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(standardsRepository)
final standardsRepositoryProvider = StandardsRepositoryProvider._();

final class StandardsRepositoryProvider
    extends
        $FunctionalProvider<
          StandardsRepository,
          StandardsRepository,
          StandardsRepository
        >
    with $Provider<StandardsRepository> {
  StandardsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'standardsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$standardsRepositoryHash();

  @$internal
  @override
  $ProviderElement<StandardsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StandardsRepository create(Ref ref) {
    return standardsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StandardsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StandardsRepository>(value),
    );
  }
}

String _$standardsRepositoryHash() =>
    r'56620ebba2d57a87f8122ae32b6be0c6ce8fab2d';
