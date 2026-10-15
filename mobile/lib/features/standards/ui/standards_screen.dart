import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/units/dist_unit.dart';
import '../../../core/util/clock.dart';
import '../../../core/util/open_link.dart';
import '../../../core/util/relative_time.dart';
import '../../groups/data/small_kv_store.dart';
import '../../groups/ui/groups_providers.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/standards_dtos.dart';
import '../data/standards_repository.dart';
import '../logic/standards_format.dart';
import '../logic/standards_selection.dart';
import 'medal_style.dart';
import 'standards_providers.dart';

/// Where members claim an award (the website's claim page).
final claimAwardUrl = Uri.parse('https://bpj.org.uk/claim-award');

/// Club standards (`/profile/standards`, Phase 9b): the Bronze to Platinum time
/// for each event in one gender and age category, opening on the viewer's own.
/// Same offline pattern as the other screens: render the Drift cache straight
/// away, revalidate in the background (on open and on app resume) and show a
/// banner, not an error screen, if that fails.
class StandardsScreen extends ConsumerStatefulWidget {
  const StandardsScreen({super.key});

  @override
  ConsumerState<StandardsScreen> createState() => _StandardsScreenState();
}

// `WidgetsBindingObserver` tells us when the app returns to the foreground
// (like a `visibilitychange` listener).
class _StandardsScreenState extends ConsumerState<StandardsScreen>
    with WidgetsBindingObserver {
  bool _refreshing = true;
  bool _refreshFailed = false;

  /// What the viewer picked; null means "follow the default" (their own
  /// category). Never saved: every visit opens on their own (D91).
  MyCategory? _picked;

  /// The "How it works" card: open the first time ever, collapsed after.
  bool _introLoaded = false;
  bool _introOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadIntro());
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _loadIntro() async {
    final store = ref.read(smallKvStoreProvider);
    var seen = false;
    try {
      seen = await store.get(SmallKvStore.standardsIntroSeenKey) != null;
      if (!seen) await store.set(SmallKvStore.standardsIntroSeenKey, '1');
    } on Object {
      // No stored flag: show the card open.
    }
    if (!mounted) return;
    setState(() {
      _introLoaded = true;
      _introOpen = !seen;
    });
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(standardsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    var failed = false;
    try {
      await repo.refresh(clubId);
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
    final cached = ref.watch(standardsProvider(clubId)).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Club standards')),
      body: SafeArea(
        child: cached == null
            ? _buildNoCache(context)
            : RefreshIndicator(
                onRefresh: _refresh,
                child: _buildContent(context, cached),
              ),
      ),
    );
  }

  /// Nothing cached: a spinner while the first load runs, else a retry message.
  Widget _buildNoCache(BuildContext context) {
    if (_refreshing) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Couldn't load the club standards. Check your connection and try again.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
              onPressed: _refresh,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CachedStandards cached) {
    final theme = Theme.of(context);
    final data = cached.data;
    final now = ref.watch(nowProvider);
    final updated = 'Updated ${relativeTime(cached.fetchedAt, now: now)}';
    final showPace = ref.watch(standardsShowPaceProvider);
    final unit =
        ref
            .watch(runPreferencesProvider(ref.watch(activeClubIdProvider)))
            .value
            ?.paceUnit ??
        DistUnit.mi;

    final mine = data.mine;
    final fallback = defaultSelection(data);
    final selected = _picked ?? fallback;
    // True when the open table is the default one: the viewer's own category,
    // or Men SEN when the server does not know it.
    final onDefault = selected == fallback;
    final table = data.tableFor(selected.gender, selected.category);
    // Only events this category has standards for, in distance order.
    final events = [
      for (final e in data.events)
        if (table[e.name]?.isNotEmpty ?? false) e,
    ];
    final offline = _refreshFailed && !_refreshing;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (offline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OfflineBanner('Offline — showing saved standards. $updated'),
          ),
        Text(
          'Club standards awards',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _HowItWorks(
          // Rebuilt once the saved flag is known so `initiallyExpanded` applies.
          key: ValueKey(_introLoaded),
          initiallyExpanded: _introOpen,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: [
            for (final g in const ['male', 'female'])
              ButtonSegment(value: g, label: Text(genderLabel(g))),
          ],
          selected: {selected.gender},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(
            () => _picked = selectionAfterGender(data, selected, s.single),
          ),
        ),
        const SizedBox(height: 8),
        _CategoryChips(
          categories: data.categoriesFor(selected.gender),
          gender: selected.gender,
          selected: selected.category,
          mine: mine,
          onPick: (c) => setState(
            () => _picked = MyCategory(gender: selected.gender, category: c),
          ),
        ),
        const SizedBox(height: 4),
        _SelectionCaption(
          selected: selected,
          onDefault: onDefault,
          hasMine: mine != null && fallback == mine,
          onBackToMine: () => setState(() => _picked = null),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            const ButtonSegment(value: false, label: Text('Time')),
            ButtonSegment(
              value: true,
              label: Text(
                unit == DistUnit.mi ? 'Pace (min/mile)' : 'Pace (min/km)',
              ),
            ),
          ],
          selected: {showPace},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              ref.read(standardsShowPaceProvider.notifier).set(s.single),
        ),
        if (showPace) ...[
          const SizedBox(height: 8),
          Text(
            'Awards are based on finish times, not pace. Paces are a rough '
            'guide to what you may need to run.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('There are no standards for this category yet.'),
          )
        else
          for (final event in events)
            _EventCard(
              event: event,
              awards: [
                for (final a in data.awards)
                  if (table[event.name]![a] != null) table[event.name]![a]!,
              ],
              showPace: showPace,
              unit: unit,
            ),
        const SizedBox(height: 8),
        if (!offline)
          Center(
            child: Text(
              updated,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => openLink(context, ref, claimAwardUrl),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Claim an award on the website'),
        ),
      ],
    );
  }
}

/// The "How it works" card: the scheme in a few lines, collapsible.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({super.key, required this.initiallyExpanded});

  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.info_outline),
        title: const Text('How it works'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'There are four awards: Bronze, Silver, Gold and Platinum. To '
            'earn one, run the standard for it in three of the five events '
            '(Mile, 5K, 10K, Half Marathon and Marathon).',
            style: style,
          ),
          const SizedBox(height: 8),
          Text(
            'The times depend on your age category and are based on age '
            'grading, the same as parkrun uses.',
            style: style,
          ),
          const SizedBox(height: 8),
          Text(
            'parkruns count for the 5K and the club Magic Mile counts for the '
            'mile. Every other run must be at a licensed event (so no fun '
            'runs or training runs).',
            style: style,
          ),
        ],
      ),
    );
  }
}

/// A horizontally scrolling row of category chips. The viewer's own category
/// carries a star and reads "Your category" to screen readers.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.gender,
    required this.selected,
    required this.mine,
    required this.onPick,
  });

  final List<String> categories;
  final String gender;
  final String selected;
  final MyCategory? mine;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = categories[i];
          final isMine =
              mine != null &&
              mine!.gender == gender &&
              mine!.category == category;
          return Center(
            child: Semantics(
              label: isMine ? 'Your category' : null,
              child: ChoiceChip(
                avatar: isMine
                    ? const Icon(Icons.star_rounded, size: 18)
                    : null,
                label: Text(category),
                selected: category == selected,
                onSelected: (_) => onPick(category),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Showing your category", or "Showing V50 women" with a way back.
class _SelectionCaption extends StatelessWidget {
  const _SelectionCaption({
    required this.selected,
    required this.onDefault,
    required this.hasMine,
    required this.onBackToMine,
  });

  final MyCategory selected;
  final bool onDefault;

  /// Whether the default is the viewer's own category (known to the server).
  final bool hasMine;
  final VoidCallback onBackToMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final name = '${selected.category} ${genderNoun(selected.gender)}';
    if (onDefault && hasMine) {
      return Text('Showing your category', style: muted);
    }
    if (onDefault) {
      return Text(
        'Showing $name. Link your membership with your date of birth and '
        'gender to see your own category.',
        style: muted,
      );
    }
    return Row(
      children: [
        Expanded(child: Text('Showing $name', style: muted)),
        TextButton(
          onPressed: onBackToMine,
          child: Text(hasMine ? 'Back to mine' : 'Back to default'),
        ),
      ],
    );
  }
}

/// One event: its name, then one tile per award.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.awards,
    required this.showPace,
    required this.unit,
  });

  final StandardsEvent event;
  final List<StandardsItem> awards;
  final bool showPace;
  final DistUnit unit;

  String _text(StandardsItem item) {
    if (!showPace) return item.time;
    final s = item.timeS;
    return s == null ? '–' : formatRacePace(s, event.distanceM, unit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // Four tiles in a row on a normal phone, two by two on a narrow one,
            // so a time like 1:58:26 never has to shrink much or overflow.
            LayoutBuilder(
              builder: (context, box) {
                const gap = 6.0;
                final columns = box.maxWidth >= 290 ? 4 : 2;
                final width = (box.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final item in awards)
                      SizedBox(
                        width: width,
                        child: _AwardTile(item: item, text: _text(item)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AwardTile extends StatelessWidget {
  const _AwardTile({required this.item, required this.text});

  final StandardsItem item;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = medalStyle(context, item.award);
    final theme = Theme.of(context);
    return Semantics(
      label: '${item.award}: $text',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium, size: 14, color: style.accent),
                const SizedBox(width: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.award,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: style.foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // scaleDown keeps a long time on one line on the narrowest phones.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
