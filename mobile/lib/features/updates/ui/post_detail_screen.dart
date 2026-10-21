import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/util/clock.dart';
import '../../../core/util/open_link.dart';
import '../../../core/util/relative_time.dart';
import '../../groups/ui/group_access.dart';
import '../../members/ui/member_avatar.dart';
import '../data/post_receipts_repository.dart';
import 'post_receipts_card.dart';
import 'updates_providers.dart';

/// `/updates/:id`: one post, with its Markdown body rendered. Links open in the
/// browser or mail app. Reads the Drift cache only; a deep link to a post that
/// isn't cached yet (push arrived, feed not refreshed) shows a friendly message.
///
/// Reading it to the end is reported to the server as a read receipt (D123):
/// the update has to have been open for [readDwell] and scrolled to the end (or
/// be short enough to fit on screen). The committee also sees who has read it.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  /// How long the update must have been open before it counts as read.
  static const readDwell = Duration(seconds: 2);

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _scroll = ScrollController();
  Timer? _dwell;
  bool _tracking = false;
  bool _dwelled = false;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkRead);
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Starts the dwell timer once the post is on screen (not for your own post).
  void _startTracking(Post post) {
    if (_tracking) return;
    _tracking = true;
    if (post.authorMemberId == ref.read(myMemberIdProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dwell = Timer(PostDetailScreen.readDwell, () {
        _dwelled = true;
        _checkRead();
      });
    });
  }

  /// Read once the dwell has passed and the end is on screen.
  void _checkRead() {
    if (_marked || !_dwelled || !mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.maxScrollExtent - p.pixels > 24) return;
    _marked = true;
    final post = ref.read(postProvider(widget.postId)).value;
    if (post == null) return;
    final repo = ref.read(postReceiptsRepositoryProvider);
    unawaited(
      repo
          .markRead(post.clubId, post.id)
          .then(
            (_) => repo.syncQuietly(
              post.clubId,
              myMemberId: ref.read(myMemberIdProvider),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postProvider(widget.postId));
    final canSeeReceipts = ref.watch(canPostProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Update')),
      body: SafeArea(
        child: post.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text("Couldn't load this post.")),
          data: (post) {
            if (post == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "This update isn't available yet. Pull to refresh on the "
                    'Updates tab, or check your connection.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            _startTracking(post);
            return ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                if (post.priority == 'important')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: Icon(
                          Icons.priority_high,
                          size: 16,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        label: Text(
                          'Important',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.errorContainer,
                      ),
                    ),
                  ),
                Text(
                  post.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                // Author avatar + tappable name (D69) then the time; the list
                // card keeps plain text because the whole card is a tap target.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    if (post.authorName.isNotEmpty)
                      MemberLink(
                        memberId: post.authorMemberId.isEmpty
                            ? null
                            : post.authorMemberId,
                        name: post.authorName,
                        avatarSize: 24,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      '${post.authorName.isNotEmpty ? '· ' : ''}'
                      '${relativeTime(post.publishedAt, now: ref.watch(nowProvider))}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MarkdownBody(
                  data: post.bodyMd,
                  selectable: true,
                  onTapLink: (text, href, title) {
                    final uri = href == null ? null : Uri.tryParse(href);
                    if (uri != null) openLink(context, ref, uri);
                  },
                ),
                if (canSeeReceipts) PostReceiptsCard(postId: post.id),
              ],
            );
          },
        ),
      ),
    );
  }
}
