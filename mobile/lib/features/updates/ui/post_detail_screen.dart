import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/open_link.dart';
import '../../../core/util/relative_time.dart';
import 'updates_providers.dart';

/// `/updates/:id`: one post, with its Markdown body rendered. Links open in the
/// browser or mail app. Reads the Drift cache only; a deep link to a post that
/// isn't cached yet (push arrived, feed not refreshed) shows a friendly message.
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
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
            return ListView(
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
                Text(
                  [
                    if (post.authorName.isNotEmpty) post.authorName,
                    relativeTime(post.publishedAt),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
