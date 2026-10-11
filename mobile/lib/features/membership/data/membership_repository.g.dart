// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(membershipRepository)
final membershipRepositoryProvider = MembershipRepositoryProvider._();

final class MembershipRepositoryProvider
    extends
        $FunctionalProvider<
          MembershipRepository,
          MembershipRepository,
          MembershipRepository
        >
    with $Provider<MembershipRepository> {
  MembershipRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipRepositoryHash();

  @$internal
  @override
  $ProviderElement<MembershipRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MembershipRepository create(Ref ref) {
    return membershipRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MembershipRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MembershipRepository>(value),
    );
  }
}

String _$membershipRepositoryHash() =>
    r'335595156b686fdb709d5ae8fb6920287718bb2b';
