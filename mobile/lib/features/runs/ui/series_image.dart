import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_image.g.dart';

/// Builds the [ImageProvider] for a series image URL. A provider so widget tests can
/// swap in an in-memory or failing image instead of touching the network (same idea as
/// the `urlOpener` fake). The default downloads once and caches on the device (D49).
@Riverpod(keepAlive: true)
ImageProvider Function(String url) seriesImageFactory(Ref ref) =>
    CachedNetworkImageProvider.new;

/// Height of the banner above a run card / on the run page.
const seriesImageHeight = 150.0;

/// The series banner (D49): full width, [seriesImageHeight] tall, `BoxFit.cover`, top
/// corners rounded to match the card, fading in once loaded.
///
/// Renders **nothing** (zero height, no placeholder or error icon) when [url] is null or
/// empty, while it loads, and if loading fails. Because it only takes space after a
/// successful load, a failure never moves the layout.
class SeriesImage extends ConsumerStatefulWidget {
  const SeriesImage({
    super.key,
    required this.url,
    this.radius = 12,
    this.roundBottom = false,
    this.gapBelow = 0,
  });

  final String? url;

  /// Top-corner radius; the Material 3 card radius is 12.
  final double radius;

  /// Round all four corners (the run page) instead of just the top (inside a card).
  final bool roundBottom;

  /// Space under the image, only added while the image is shown.
  final double gapBelow;

  @override
  ConsumerState<SeriesImage> createState() => _SeriesImageState();
}

class _SeriesImageState extends ConsumerState<SeriesImage> {
  ImageProvider? _provider;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, sync) {
      if (mounted) setState(() => _loaded = true);
    },
    onError: (error, stack) {
      if (mounted) setState(() => _loaded = false);
    },
  );
  bool _loaded = false;

  // ~ React's useEffect([url]): (re)subscribe whenever the URL changes. Resolving needs
  // the BuildContext (device pixel ratio etc.), hence didChangeDependencies.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(SeriesImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _resolve();
  }

  void _resolve() {
    _stream?.removeListener(_listener);
    _stream = null;
    _provider = null;
    _loaded = false;
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    _provider = ref.read(seriesImageFactoryProvider)(url);
    _stream = _provider!.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    if (!_loaded || provider == null) return const SizedBox.shrink();
    final image = ClipRRect(
      borderRadius: widget.roundBottom
          ? BorderRadius.circular(widget.radius)
          : BorderRadius.vertical(top: Radius.circular(widget.radius)),
      // Fade 0 -> 1 on first build (like a CSS opacity transition on mount).
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Image(
          image: provider,
          width: double.infinity,
          height: seriesImageHeight,
          fit: BoxFit.cover,
          // Already decoded and cached by now; never show an error widget.
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
    return widget.gapBelow == 0
        ? image
        : Padding(
            padding: EdgeInsets.only(bottom: widget.gapBelow),
            child: image,
          );
  }
}
