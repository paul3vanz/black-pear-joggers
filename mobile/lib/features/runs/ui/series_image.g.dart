// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_image.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds the [ImageProvider] for a series image URL. A provider so widget tests can
/// swap in an in-memory or failing image instead of touching the network (same idea as
/// the `urlOpener` fake). The default downloads once and caches on the device (D49).

@ProviderFor(seriesImageFactory)
final seriesImageFactoryProvider = SeriesImageFactoryProvider._();

/// Builds the [ImageProvider] for a series image URL. A provider so widget tests can
/// swap in an in-memory or failing image instead of touching the network (same idea as
/// the `urlOpener` fake). The default downloads once and caches on the device (D49).

final class SeriesImageFactoryProvider
    extends
        $FunctionalProvider<
          ImageProvider<Object> Function(String url),
          ImageProvider<Object> Function(String url),
          ImageProvider<Object> Function(String url)
        >
    with $Provider<ImageProvider<Object> Function(String url)> {
  /// Builds the [ImageProvider] for a series image URL. A provider so widget tests can
  /// swap in an in-memory or failing image instead of touching the network (same idea as
  /// the `urlOpener` fake). The default downloads once and caches on the device (D49).
  SeriesImageFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seriesImageFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seriesImageFactoryHash();

  @$internal
  @override
  $ProviderElement<ImageProvider<Object> Function(String url)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageProvider<Object> Function(String url) create(Ref ref) {
    return seriesImageFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageProvider<Object> Function(String url) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ImageProvider<Object> Function(String url)>(value),
    );
  }
}

String _$seriesImageFactoryHash() =>
    r'cf68ed4b670e375cf7a30dbfdbfc51cabbb84666';
