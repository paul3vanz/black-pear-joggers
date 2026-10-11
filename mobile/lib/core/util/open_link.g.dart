// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_link.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens a URL outside the app (browser, mail app...). A provider so tests can
/// replace it with a fake instead of trying to launch a real browser; same idea
/// as mocking `window.open` in Jest.

@ProviderFor(urlOpener)
final urlOpenerProvider = UrlOpenerProvider._();

/// Opens a URL outside the app (browser, mail app...). A provider so tests can
/// replace it with a fake instead of trying to launch a real browser; same idea
/// as mocking `window.open` in Jest.

final class UrlOpenerProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(Uri url),
          Future<bool> Function(Uri url),
          Future<bool> Function(Uri url)
        >
    with $Provider<Future<bool> Function(Uri url)> {
  /// Opens a URL outside the app (browser, mail app...). A provider so tests can
  /// replace it with a fake instead of trying to launch a real browser; same idea
  /// as mocking `window.open` in Jest.
  UrlOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlOpenerHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function(Uri url)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function(Uri url) create(Ref ref) {
    return urlOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function(Uri url) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function(Uri url)>(
        value,
      ),
    );
  }
}

String _$urlOpenerHash() => r'729e541b0de9c703eabc22b95e8524d111364d11';
