import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/relative_time.dart';
import '../../groups/ui/group_access.dart';
import '../data/post_receipts_repository.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/post_dto.dart';
import '../data/posts_repository.dart';
import 'updates_providers.dart';

/// The Updates tab (`/updates`): club news, pinned first. Same offline pattern as
/// the profile screen: render the Drift cache straight away, refresh in the
/// background, and show a small banner (not an error screen) if that fails.
class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> {
  bool _refreshing = true;
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(postsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    var failed = false;
    try {
      await repo.refresh(clubId);
      // Tell the server these updates reached this phone (D123).
      unawaited(
        ref
            .read(postReceiptsRepositoryProvider)
            .syncQuietly(clubId, myMemberId: ref.read(myMemberIdProvider)),
      );
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _refreshFailed = failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final posts = ref.watch(postsProvider(clubId)).value;
    final canPost = ref.watch(canPostProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/updates/new'),
              icon: const Icon(Icons.edit),
              label: const Text('New update'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildList(context, posts),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Post>? posts) {
    // Minute-fresh, so "5 minutes ago" and pin expiry keep up (D87).
    final now = ref.watch(nowProvider);
    final showBanner = _refreshFailed && !_refreshing;
    final loadingFirst = posts == null || (posts.isEmpty && _refreshing);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (_refreshing && (posts?.isEmpty ?? true))
          const LinearProgressIndicator(),
        if (showBanner)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OfflineBanner(
              (posts?.isEmpty ?? true)
                  ? "Offline — updates couldn't be loaded"
                  : 'Offline — showing saved updates',
            ),
          ),
        if (!loadingFirst && posts.isEmpty && !showBanner) const _EmptyState(),
        if (posts != null)
          for (final post in sortPosts(posts, now))
            _PostCard(post: post, now: now),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No updates yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'News from the committee will show up here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.now});

  final Post post;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final important = post.priority == 'important';
    final pinned = isPinned(post, now);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/updates/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (important || pinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (important)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            Icons.priority_high,
                            size: 16,
                            color: scheme.onErrorContainer,
                          ),
                          label: Text(
                            'Important',
                            style: TextStyle(color: scheme.onErrorContainer),
                          ),
                          backgroundColor: scheme.errorContainer,
                        ),
                      if (pinned)
                        const Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(Icons.push_pin, size: 16),
                          label: Text('Pinned'),
                        ),
                    ],
                  ),
                ),
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bodyPreview(post.bodyMd),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (post.authorName.isNotEmpty) post.authorName,
                  relativeTime(post.publishedAt, now: now),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Markdown stripped to plain-ish text for the list preview.
String bodyPreview(String markdown) => markdown
    .replaceAll(RegExp(r'!?\[([^\]]*)\]\([^)]*\)'), r'$1')
    .replaceAll(RegExp(r'[#*_`>~]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
