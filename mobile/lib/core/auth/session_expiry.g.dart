// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_expiry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Key for the app's root `ScaffoldMessenger`, so code outside the widget tree
/// (like the session-expiry handler) can show a SnackBar. In React terms: a ref to
/// a toast container that any module can reach.

@ProviderFor(scaffoldMessengerKey)
final scaffoldMessengerKeyProvider = ScaffoldMessengerKeyProvider._();

/// Key for the app's root `ScaffoldMessenger`, so code outside the widget tree
/// (like the session-expiry handler) can show a SnackBar. In React terms: a ref to
/// a toast container that any module can reach.

final class ScaffoldMessengerKeyProvider
    extends
        $FunctionalProvider<
          GlobalKey<ScaffoldMessengerState>,
          GlobalKey<ScaffoldMessengerState>,
          GlobalKey<ScaffoldMessengerState>
        >
    with $Provider<GlobalKey<ScaffoldMessengerState>> {
  /// Key for the app's root `ScaffoldMessenger`, so code outside the widget tree
  /// (like the session-expiry handler) can show a SnackBar. In React terms: a ref to
  /// a toast container that any module can reach.
  ScaffoldMessengerKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scaffoldMessengerKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scaffoldMessengerKeyHash();

  @$internal
  @override
  $ProviderElement<GlobalKey<ScaffoldMessengerState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalKey<ScaffoldMessengerState> create(Ref ref) {
    return scaffoldMessengerKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalKey<ScaffoldMessengerState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalKey<ScaffoldMessengerState>>(
        value,
      ),
    );
  }
}

String _$scaffoldMessengerKeyHash() =>
    r'6fdcaf2dd3359a74fa6f6d7fbd0c67c54a8e600d';

@ProviderFor(sessionExpiryHandler)
final sessionExpiryHandlerProvider = SessionExpiryHandlerProvider._();

final class SessionExpiryHandlerProvider
    extends
        $FunctionalProvider<
          SessionExpiryHandler,
          SessionExpiryHandler,
          SessionExpiryHandler
        >
    with $Provider<SessionExpiryHandler> {
  SessionExpiryHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionExpiryHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionExpiryHandlerHash();

  @$internal
  @override
  $ProviderElement<SessionExpiryHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionExpiryHandler create(Ref ref) {
    return sessionExpiryHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionExpiryHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionExpiryHandler>(value),
    );
  }
}

String _$sessionExpiryHandlerHash() =>
    r'd4299faf762db07a6ade000871640e88053cdb8d';
