import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/post_receipts_repository.dart';

/// The committee's receipts for one update (`GET /posts/{id}/receipts`),
/// fetched when the card opens and again on **Refresh**. Not cached: it is
/// only worth seeing live.
final postReceiptsProvider = FutureProvider.autoDispose
    .family<PostReceipts, String>(
      (ref, postId) => ref
          .watch(postReceiptsRepositoryProvider)
          .fetch(ref.watch(activeClubIdProvider), postId),
    );

/// The tick for a state, WhatsApp style: one grey tick for delivered, two
/// coloured ticks for read, an empty clock for neither.
class ReceiptTick extends StatelessWidget {
  const ReceiptTick(this.state, {super.key, this.size = 20});

  final ReceiptState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      ReceiptState.read => Icon(
        Icons.done_all,
        size: size,
        color: scheme.primary,
        semanticLabel: 'Read',
      ),
      ReceiptState.delivered => Icon(
        Icons.done,
        size: size,
        color: scheme.onSurfaceVariant,
        semanticLabel: 'Delivered',
      ),
      ReceiptState.none => Icon(
        Icons.schedule,
        size: size,
        color: scheme.outline,
        semanticLabel: 'Not delivered yet',
      ),
    };
  }
}

/// "Seen by": counts of read, delivered and not yet, with the names behind them.
/// Shown to the committee on an update's page.
class PostReceiptsCard extends ConsumerWidget {
  const PostReceiptsCard({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final receipts = ref.watch(postReceiptsProvider(postId));
    return Card(
      key: const ValueKey('postReceipts'),
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Seen by',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('receiptsRefresh'),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(postReceiptsProvider(postId)),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            receipts.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 12, right: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 8),
                child: Text(
                  ApiException.from(e).isNetworkError
                      ? "You're offline. Connect to see who has read this."
                      : "Couldn't load who has read this.",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              data: (r) => _Body(receipts: r),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.receipts});

  final PostReceipts receipts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = receipts;
    if (r.audienceCount == 0) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text('Nobody else was meant to see this.'),
      );
    }
    final notYet = r.audienceCount - r.deliveredCount;
    final delivered = r.deliveredCount - r.readCount;
    List<ReceiptMember> of(ReceiptState s) => [
      for (final m in r.members)
        if (m.state == s) m,
    ];
    Widget count(ReceiptState s, int n, String label) => Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReceiptTick(s, size: 18),
          const SizedBox(width: 4),
          Text('$n $label'),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          runSpacing: 4,
          children: [
            count(ReceiptState.read, r.readCount, 'read'),
            count(ReceiptState.delivered, delivered, 'delivered'),
            count(ReceiptState.none, notYet, 'not yet'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'of ${r.audienceCount}. Read means they opened it and got to the end.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('receiptsNames'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(right: 8),
            title: Text('See who', style: theme.textTheme.labelLarge),
            children: [
              _Group('Not yet', of(ReceiptState.none), ReceiptState.none),
              _Group(
                'Delivered',
                of(ReceiptState.delivered),
                ReceiptState.delivered,
              ),
              _Group('Read', of(ReceiptState.read), ReceiptState.read),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.members, this.state);

  final String title;
  final List<ReceiptMember> members;
  final ReceiptState state;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            '$title (${members.length})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final m in members)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(m.displayName)),
                ReceiptTick(state, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
