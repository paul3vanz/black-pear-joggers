import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'member_providers.dart';

/// Builds the [ImageProvider] for a member photo URL. A provider so widget tests
/// can swap in an in-memory or failing image instead of touching the network
/// (same idea as `seriesImageFactoryProvider`). The default downloads once and
/// caches on the device; the signed link changes when the photo changes, so a
/// cached copy never goes stale.
final avatarImageFactoryProvider = Provider<ImageProvider Function(String url)>(
  (ref) => CachedNetworkImageProvider.new,
);

/// "Sam B." -> "SB", "Sam" -> "S", "" -> "?". First letter of the first and the
/// last word, upper-cased; dots and extra spaces are ignored.
String initialsOf(String name) {
  final words = name
      .split(RegExp(r'[\s.]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();
  return words.length == 1
      ? first(words.first)
      : first(words.first) + first(words.last);
}

/// A circular avatar for an explicit photo URL: initials on a neutral grey disc,
/// with the photo fading in on top once it has loaded (no spinner, and a failed
/// or missing photo simply leaves the initials, so the layout never moves). Use
/// [MemberAvatar] when you only have a member id.
class AvatarCircle extends ConsumerStatefulWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 28,
  });

  final String name;

  /// Full photo URL, or null for initials only.
  final String? photoUrl;
  final double size;

  @override
  ConsumerState<AvatarCircle> createState() => _AvatarCircleState();
}

class _AvatarCircleState extends ConsumerState<AvatarCircle> {
  ImageProvider? _provider;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, synchronous) {
      if (!mounted) return;
      // Already in memory (the same photo shown a moment ago): show it at once.
      setState(() {
        _loaded = true;
        _fade = !synchronous;
      });
    },
    onError: (error, stack) {
      if (mounted) setState(() => _loaded = false);
    },
  );
  bool _loaded = false;
  bool _fade = false;

  // ~ React's useEffect([url]): (re)subscribe whenever the URL changes. Resolving
  // needs the BuildContext (pixel ratio), hence didChangeDependencies.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AvatarCircle old) {
    super.didUpdateWidget(old);
    if (old.photoUrl != widget.photoUrl || old.size != widget.size) _resolve();
  }

  void _resolve() {
    _stream?.removeListener(_listener);
    _stream = null;
    _provider = null;
    _loaded = false;
    final url = widget.photoUrl;
    if (url == null || url.isEmpty) return;
    final px = (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil();
    // Decode at display size rather than the full 512 px.
    _provider = ResizeImage.resizeIfNeeded(
      px,
      null,
      ref.read(avatarImageFactoryProvider)(url),
    );
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
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final provider = _provider;
    final image = _loaded && provider != null
        ? Image(
            key: const ValueKey('member-avatar-photo'),
            image: provider,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          )
        : null;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  initialsOf(widget.name),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                    height: 1,
                  ),
                ),
              ),
              if (image != null)
                _fade
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 200),
                        builder: (context, opacity, child) =>
                            Opacity(opacity: opacity, child: child),
                        child: image,
                      )
                    : image,
            ],
          ),
        ),
      ),
    );
  }
}

/// A member's avatar from the cached member cards (D61): their photo when they
/// have one, otherwise initials of [name]. [memberId] may be null (unknown
/// author): initials only. Compact by default (28 px).
///
/// ```dart
/// MemberAvatar(memberId: leader.memberId, name: leader.name, size: 36)
/// ```
class MemberAvatar extends ConsumerWidget {
  const MemberAvatar({
    super.key,
    required this.memberId,
    required this.name,
    this.size = 28,
  });

  final String? memberId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = memberId;
    // `select`: rebuild only when THIS member's photo path changes.
    final photoPath = id == null
        ? null
        : ref.watch(memberCardsProvider.select((v) => v.value?[id]?.photoPath));
    return AvatarCircle(
      name: name,
      size: size,
      photoUrl: ref.watch(memberPhotoUrlProvider)(photoPath),
    );
  }
}

/// Small avatar + name that opens the member's profile page when tapped. The
/// page is *pushed* (D62), so Back returns to the screen you came from. With a
/// null [memberId] it shows the same avatar and name but is not tappable.
class MemberLink extends StatelessWidget {
  const MemberLink({
    super.key,
    required this.memberId,
    required this.name,
    this.avatarSize = 28,
    this.style,
    this.maxLines = 1,
  });

  final String? memberId;
  final String name;
  final double avatarSize;

  /// Text style of the name (defaults to `bodyMedium`).
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final id = memberId;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: MemberAvatar(memberId: id, name: name, size: avatarSize),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style ?? Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
    if (id == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(avatarSize),
      onTap: () => context.push('/members/${Uri.encodeComponent(id)}'),
      child: content,
    );
  }
}

/// Just the name as tappable text (no avatar), for places that already show the
/// avatar elsewhere, e.g. the author line above a chat bubble. Opens the
/// member's profile page, pushed (D62). With a null or empty [memberId] it is
/// plain text.
class MemberNameLink extends StatelessWidget {
  const MemberNameLink({
    super.key,
    required this.memberId,
    required this.name,
    this.style,
  });

  final String? memberId;
  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final id = memberId;
    final text = Text(name, style: style);
    if (id == null || id.isEmpty) return text;
    return InkWell(
      onTap: () => context.push('/members/${Uri.encodeComponent(id)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: text,
      ),
    );
  }
}
