// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inboxRepository)
final inboxRepositoryProvider = InboxRepositoryProvider._();

final class InboxRepositoryProvider
    extends
        $FunctionalProvider<InboxRepository, InboxRepository, InboxRepository>
    with $Provider<InboxRepository> {
  InboxRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxRepositoryHash();

  @$internal
  @override
  $ProviderElement<InboxRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InboxRepository create(Ref ref) {
    return inboxRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InboxRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InboxRepository>(value),
    );
  }
}

String _$inboxRepositoryHash() => r'1bffd15e88674506c3711acca978fbd585ef15da';
