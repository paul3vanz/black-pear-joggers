import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/config/club_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/util/open_link.dart';
import '../../../core/util/relative_time.dart';
import '../../auth/ui/account_switcher.dart';
import '../../groups/data/run_preferences_repository.dart';
import '../../membership/data/membership_dtos.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/profile_repository.dart';
import 'profile_providers.dart';
import 'run_preferences_card.dart';

/// The home screen (`/`). It never waits for the network to render: it watches the
/// cached membership + profile (Drift streams), and a refresh runs in the background
/// when the screen opens and on pull-to-refresh. If that refresh fails and we have a
/// cache, a small "offline" banner appears instead of an error screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _refreshing = true;
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    // Like `useEffect(() => { refresh() }, [])`.
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(profileRepositoryProvider);
    final meSync = ref.read(meSyncProvider.notifier);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    var failed = false;
    try {
      final result = await repo.refreshProfile(clubId);
      // Local rows were wiped; the router now sends the user to /link.
      if (result == ProfileRefresh.notAMember) {
        meSync.markSynced();
      } else {
        await _refreshPreferences(clubId);
      }
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

  /// Running preferences ride along with the profile refresh. A failure here
  /// is not shown: the cached preferences are fine.
  Future<void> _refreshPreferences(int clubId) async {
    try {
      await ref.read(runPreferencesRepositoryProvider).refresh(clubId);
    } on Object {
      // Offline or a server error: keep what is cached.
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(clubConfigProvider);
    final clubId = ref.watch(activeClubIdProvider);
    final membership = ref.watch(activeMembershipProvider);
    final profile = ref.watch(profileProvider(clubId)).value;

    return Scaffold(
      appBar: AppBar(title: Text(club.name)),
      body: SafeArea(
        child: membership == null && profile == null
            ? _buildEmpty(context)
            : RefreshIndicator(
                onRefresh: _refresh,
                child: _buildContent(context, club, membership, profile),
              ),
      ),
    );
  }

  /// Nothing cached at all (normally only a split second while the router redirects).
  Widget _buildEmpty(BuildContext context) {
    if (_refreshing) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Couldn't load your profile."),
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

  Widget _buildContent(
    BuildContext context,
    ClubConfig club,
    Membership? membership,
    Profile? profile,
  ) {
    final theme = Theme.of(context);
    final view = _ProfileView.from(membership, profile);
    final updatedAt = profile?.updatedAt ?? membership?.updatedAt;
    final joinUrl = Uri.tryParse(membership?.joinUrl ?? '') ?? club.joinUrl;
    final account = ref.watch(activeAccountProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (_refreshing && profile == null) const LinearProgressIndicator(),
        if (_refreshFailed && !_refreshing)
          _OfflineBanner(updatedAt: updatedAt, hasProfile: profile != null),
        const SizedBox(height: 8),
        _Header(view: view, clubName: membership?.clubName ?? club.name),
        if (view.isLapsed) ...[
          const SizedBox(height: 16),
          _LapsedCard(onTap: () => openLink(context, ref, joinUrl)),
        ],
        if (view.regStatus != null) ...[
          const SizedBox(height: 24),
          const _SectionTitle('England Athletics'),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Registration status'),
            subtitle: Text(view.regStatus!),
          ),
        ],
        if (view.hasLinks) ...[
          const SizedBox(height: 24),
          const _SectionTitle('Links'),
          if (view.resultsUrl != null)
            _LinkTile(
              icon: Icons.emoji_events_outlined,
              label: 'Race results',
              url: view.resultsUrl!,
            ),
          if (view.powerOf10Url != null)
            _LinkTile(
              icon: Icons.query_stats,
              label: 'Power of 10',
              url: view.powerOf10Url!,
            ),
          if (view.claimAwardUrl != null)
            _LinkTile(
              icon: Icons.military_tech_outlined,
              label: 'Claim an award',
              url: view.claimAwardUrl!,
            ),
        ],
        const SizedBox(height: 24),
        const RunPreferencesCard(),
        const SizedBox(height: 24),
        const _SectionTitle('Account'),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(
            'Signed in as ${account?.email ?? account?.displayName ?? 'unknown'}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notification settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/profile/notifications'),
        ),
        if (ref.watch(canManageRunsProvider))
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Members and roles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/members'),
          ),
        ListTile(
          leading: const Icon(Icons.switch_account_outlined),
          title: const Text('Switch or add account'),
          onTap: () => showAccountSwitcher(context),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: account == null
              ? null
              : () => ref
                    .read(accountsControllerProvider.notifier)
                    .remove(account.sub),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Version ${ref.watch(appVersionProvider).value ?? ''}'.trim(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// What the screen shows, merged from the membership row (available straight after
/// linking) and the fuller profile row (once fetched). Plain Dart class: React
/// equivalent is a selector that derives props from two queries.
class _ProfileView {
  const _ProfileView({
    required this.name,
    required this.category,
    required this.gender,
    required this.status,
    required this.roles,
    this.regStatus,
    this.resultsUrl,
    this.powerOf10Url,
    this.claimAwardUrl,
  });

  final String name;
  final String? category;
  final String? gender;
  final String status;
  final List<String> roles;
  final String? regStatus;
  final Uri? resultsUrl;
  final Uri? powerOf10Url;
  final Uri? claimAwardUrl;

  bool get isLapsed => status != 'active';
  bool get hasLinks =>
      resultsUrl != null || powerOf10Url != null || claimAwardUrl != null;

  factory _ProfileView.from(Membership? m, Profile? p) {
    final first = p?.firstName ?? m?.firstName;
    final last = p?.lastName ?? m?.lastName;
    Uri? uri(String? s) => s == null ? null : Uri.tryParse(s);
    return _ProfileView(
      name: [first, last].whereType<String>().join(' '),
      category: p?.category ?? m?.category,
      gender: p?.gender ?? m?.gender,
      status: p?.status ?? m?.status ?? 'active',
      roles: decodeRoles(p?.rolesJson ?? m?.rolesJson ?? '[]'),
      regStatus: p?.competitiveRegStatus,
      resultsUrl: uri(p?.resultsUrl),
      powerOf10Url: uri(p?.powerOf10Url),
      claimAwardUrl: uri(p?.claimAwardUrl),
    );
  }
}

String? _genderLabel(String? g) => switch (g) {
  'W' => 'Women',
  'M' => 'Men',
  _ => g,
};

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _Header extends StatelessWidget {
  const _Header({required this.view, required this.clubName});

  final _ProfileView view;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = [
      view.category,
      _genderLabel(view.gender),
    ].whereType<String>().join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          view.name.isEmpty ? 'Member' : view.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (details.isNotEmpty)
          Text(details, style: theme.textTheme.titleMedium),
        Text(
          clubName,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              avatar: Icon(
                view.isLapsed ? Icons.warning_amber : Icons.check_circle,
                size: 18,
                color: view.isLapsed ? scheme.onErrorContainer : null,
              ),
              label: Text(view.isLapsed ? 'Lapsed' : 'Active'),
              backgroundColor: view.isLapsed ? scheme.errorContainer : null,
            ),
            for (final role in view.roles) Chip(label: Text(_capitalise(role))),
          ],
        ),
      ],
    );
  }
}

class _LapsedCard extends StatelessWidget {
  const _LapsedCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(Icons.autorenew, color: scheme.onErrorContainer),
        title: Text(
          'Your membership has lapsed',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: scheme.onErrorContainer,
          ),
        ),
        subtitle: Text(
          'Renew to keep running with the club.',
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        trailing: Icon(Icons.open_in_new, color: scheme.onErrorContainer),
        onTap: onTap,
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.updatedAt, required this.hasProfile});

  final DateTime? updatedAt;
  final bool hasProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = updatedAt == null
        ? ''
        : ' (updated ${relativeTime(updatedAt!)})';
    final text = hasProfile
        ? 'Offline — showing saved details$when'
        : "Offline — some details couldn't be loaded";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _LinkTile extends ConsumerWidget {
  const _LinkTile({required this.icon, required this.label, required this.url});

  final IconData icon;
  final String label;
  final Uri url;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.open_in_new, size: 18),
    onTap: () => openLink(context, ref, url),
  );
}
