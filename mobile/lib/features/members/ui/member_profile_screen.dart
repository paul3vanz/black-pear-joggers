import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/relative_time.dart';
import '../../membership/ui/membership_providers.dart';
import '../../updates/ui/updates_providers.dart';
import '../data/member_dtos.dart';
import '../data/member_profile_repository.dart';
import 'member_avatar.dart';
import 'member_providers.dart';

enum _Load { loading, ok, notFound, offline, failed }

/// A member's profile page (`/members/:memberId`, D62): photo, name, role badges,
/// bio and (only when they share it) goals. It is *pushed*, so Back returns to
/// the run, chat or group you came from. It draws from the cached profile at
/// once and refreshes in the background; offline it keeps showing the cache.
class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  _Load _state = _Load.loading;
  String? _error;
  DateTime? _staleSince;

  @override
  void initState() {
    super.initState();
    // Like `useEffect(() => { load() }, [])`.
    unawaited(_load());
  }

  Future<void> _load() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(memberProfileRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    _Load next;
    DateTime? staleSince;
    String? error;
    try {
      final result = await repo.fetchProfile(clubId, widget.memberId);
      next = _Load.ok;
      if (result.fromCache) staleSince = result.fetchedAt;
    } on MemberOfflineException {
      next = _Load.offline;
    } on ApiException catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      next = e.statusCode == 404 ? _Load.notFound : _Load.failed;
      error = e.message;
    }
    if (!mounted) return;
    setState(() {
      _state = next;
      _error = error;
      _staleSince = staleSince;
    });
  }

  Future<void> _clear(MemberProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove photo and bio?'),
        content: Text(
          "This clears ${profile.displayName}'s photo, bio and goals. They "
          'can add new ones afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(memberProfileRepositoryProvider)
          .clearMemberProfile(ref.read(activeClubIdProvider), profile.memberId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo, bio and goals removed')),
      );
      await _load();
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(memberErrorMessage(e))));
    }
  }

  void _showPhoto(String url, String name) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: AspectRatio(
              aspectRatio: 1,
              child: Image(
                image: ref.read(avatarImageFactoryProvider)(url),
                fit: BoxFit.cover,
                semanticLabel: 'Photo of $name',
                errorBuilder: (context, error, stack) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(memberProfileProvider(widget.memberId)).value;
    // A 404 drops the cached copy, but be explicit: never show a removed member.
    final shown = _state == _Load.notFound ? null : profile;
    final canModerate =
        ref.watch(canPostProvider) &&
        shown != null &&
        !shown.isYou &&
        widget.memberId != ref.watch(ownMemberIdProvider);

    return Scaffold(
      appBar: AppBar(
        // Opened straight from a link (nothing to go back to): offer Home.
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home_outlined),
                onPressed: () => context.go('/runs'),
              ),
        title: const Text('Member'),
        actions: [
          if (canModerate)
            PopupMenuButton<String>(
              onSelected: (_) => _clear(shown),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Text('Remove photo and bio'),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _body(shown)),
      ),
    );
  }

  Widget _body(MemberProfile? profile) {
    if (profile != null) {
      return _ProfileView(
        profile: profile,
        banner: _state == _Load.ok && _staleSince != null
            ? OfflineBanner(
                'Offline: showing a saved copy '
                '(updated ${relativeTime(_staleSince!)})',
              )
            : null,
        onPhotoTap: _showPhoto,
      );
    }
    return switch (_state) {
      _Load.loading => const _Scrollable(
        child: Center(child: CircularProgressIndicator()),
      ),
      _Load.notFound => const _Scrollable(
        child: _Message(
          icon: Icons.person_off_outlined,
          title: "This member isn't available",
          text: 'They may have left the club.',
        ),
      ),
      _Load.offline => _Scrollable(
        child: _Message(
          icon: Icons.cloud_off,
          title: "You're offline",
          text: "Connect to the internet to see this member's profile.",
          retry: _load,
        ),
      ),
      _ => _Scrollable(
        child: _Message(
          icon: Icons.error_outline,
          title: "Couldn't load this profile",
          text: _error ?? 'Please try again.',
          retry: _load,
        ),
      ),
    };
  }
}

/// Lets a short message still be pulled to refresh.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.retry,
  });

  final IconData icon;
  final String title;
  final String text;
  final Future<void> Function()? retry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (retry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: retry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({
    required this.profile,
    required this.onPhotoTap,
    this.banner,
  });

  final MemberProfile profile;
  final Widget? banner;
  final void Function(String url, String name) onPhotoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final url = ref.watch(memberPhotoUrlProvider)(profile.photoPath);
    final bio = profile.bio ?? '';
    final goals = profile.goals ?? '';
    final roles = [
      for (final r in memberBadgeRoles)
        if (profile.roles.contains(r)) r,
    ];

    Widget section(String title, String text) => Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ?banner,
        if (banner != null) const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: url == null
                ? null
                : () => onPhotoTap(url, profile.displayName),
            child: AvatarCircle(
              name: profile.displayName,
              photoUrl: url,
              size: 120,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (roles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [for (final r in roles) Chip(label: Text(_roleLabel(r)))],
          ),
        ],
        if (profile.isYou) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This is how you appear to other members.'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: () => context.push('/profile/card'),
                      child: const Text('Edit my profile card'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (bio.isNotEmpty) section('About', bio),
        if (goals.isNotEmpty) section('Goals', goals),
        if (bio.isEmpty && goals.isEmpty && !profile.isYou)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              "${profile.displayName} hasn't added anything else yet.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

String _roleLabel(String role) => switch (role) {
  'leader' => 'Leader',
  'committee' => 'Committee',
  'admin' => 'Admin',
  _ => role,
};
