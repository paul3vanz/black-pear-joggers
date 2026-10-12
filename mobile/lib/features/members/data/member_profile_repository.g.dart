// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memberProfileRepository)
final memberProfileRepositoryProvider = MemberProfileRepositoryProvider._();

final class MemberProfileRepositoryProvider
    extends
        $FunctionalProvider<
          MemberProfileRepository,
          MemberProfileRepository,
          MemberProfileRepository
        >
    with $Provider<MemberProfileRepository> {
  MemberProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberProfileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemberProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemberProfileRepository create(Ref ref) {
    return memberProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberProfileRepository>(value),
    );
  }
}

String _$memberProfileRepositoryHash() =>
    r'4c31f634b84c1309f1bb29a4f5226f04388c3c4f';
