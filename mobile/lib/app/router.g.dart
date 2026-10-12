// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// go_router is the React Router of Flutter. `redirect` runs before every navigation,
/// like an auth guard in Next.js middleware:
///   * accounts (or the first `/app/me` refresh) still loading -> `/splash`
///   * nobody signed in                                         -> `/sign-in`
///   * signed in, active club has no membership                 -> `/link`
///   * first load failed with nothing cached                    -> `/unavailable`
///   * linked                                                   -> `/runs`

@ProviderFor(router)
final routerProvider = RouterProvider._();

/// go_router is the React Router of Flutter. `redirect` runs before every navigation,
/// like an auth guard in Next.js middleware:
///   * accounts (or the first `/app/me` refresh) still loading -> `/splash`
///   * nobody signed in                                         -> `/sign-in`
///   * signed in, active club has no membership                 -> `/link`
///   * first load failed with nothing cached                    -> `/unavailable`
///   * linked                                                   -> `/runs`

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// go_router is the React Router of Flutter. `redirect` runs before every navigation,
  /// like an auth guard in Next.js middleware:
  ///   * accounts (or the first `/app/me` refresh) still loading -> `/splash`
  ///   * nobody signed in                                         -> `/sign-in`
  ///   * signed in, active club has no membership                 -> `/link`
  ///   * first load failed with nothing cached                    -> `/unavailable`
  ///   * linked                                                   -> `/runs`
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'0846a83e843ddb5b3d7066ca997bd1dee8dbee43';
