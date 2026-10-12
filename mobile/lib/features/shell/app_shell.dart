import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/accounts_controller.dart';
import '../../core/auth/session_expiry.dart';
import '../../core/notifications/push_service.dart';
import '../events/data/event_locations_repository.dart';
import '../groups/data/attendance_repository.dart';
import '../inbox/data/inbox_repository.dart';
import '../inbox/ui/inbox_providers.dart';
import '../membership/ui/membership_providers.dart';
import '../members/data/member_profile_repository.dart';
import '../messages/data/messages_repository.dart';

/// Bottom navigation around the four tabs (Runs, Updates, Inbox, Profile). It's only
/// built once the user is signed in and linked, so it's also where we ask for
/// notification permission, once, with an explainer first.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshInbox());
      unawaited(_refreshMemberCards());
      unawaited(_refreshEventLocations());
      unawaited(
        ref.read(pushServiceProvider).requestPermissionWithExplainer(context),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back in the foreground: re-send any run responses that couldn't be sent.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryPending());
      unawaited(_refreshMemberCards());
      unawaited(_refreshEventLocations());
    }
  }

  /// Re-sends unsent run responses and chat messages, and refreshes the chat
  /// unread dots.
  Future<void> _retryPending() async {
    final clubId = ref.read(activeClubIdProvider);
    final sub = ref.read(activeSubProvider);
    final repo = ref.read(attendanceRepositoryProvider);
    final messages = ref.read(messagesRepositoryProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await repo.retryPending(clubId);
      await messages.retryPending(clubId);
      await messages.refreshThreadsQuietly(clubId);
    } on Object catch (e) {
      if (sub != null) await handleExpiry(sub, e);
    }
  }

  /// Keeps the Inbox badge fresh without waiting for the Inbox tab to open.
  Future<void> _refreshInbox() async {
    final clubId = ref.read(activeClubIdProvider);
    final sub = ref.read(activeSubProvider);
    final repo = ref.read(inboxRepositoryProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await repo.refresh(clubId);
    } on Object catch (e) {
      if (sub != null) await handleExpiry(sub, e);
      // Otherwise offline: the cached inbox is fine.
    }
  }

  /// Keeps member photos and names (D61) fresh: at start, on resume and after
  /// an account switch. Failures other than an expired session are ignored (the
  /// cached cards keep working offline).
  Future<void> _refreshMemberCards() async {
    final clubId = ref.read(activeClubIdProvider);
    final sub = ref.read(activeSubProvider);
    final repo = ref.read(memberProfileRepositoryProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await repo.refreshCardsQuietly(clubId);
    } on Object catch (e) {
      if (sub != null) await handleExpiry(sub, e);
    }
  }

  /// Keeps the club's event locations (parkruns, races) fresh for the event
  /// picker: at start, on resume and after an account or club switch. Only an
  /// expired session is reported; offline, the cached list is used.
  Future<void> _refreshEventLocations() async {
    final clubId = ref.read(activeClubIdProvider);
    final sub = ref.read(activeSubProvider);
    final repo = ref.read(eventLocationsRepositoryProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await repo.refresh(clubId);
    } on Object catch (e) {
      if (sub != null) await handleExpiry(sub, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh again whenever the account changes (the repository rebuilds).
    ref.listen(inboxRepositoryProvider, (_, _) => unawaited(_refreshInbox()));
    ref.listen(
      memberProfileRepositoryProvider,
      (_, _) => unawaited(_refreshMemberCards()),
    );
    ref.listen(
      eventLocationsRepositoryProvider,
      (_, _) => unawaited(_refreshEventLocations()),
    );
    ref.listen(
      activeClubIdProvider,
      (_, _) => unawaited(_refreshEventLocations()),
    );
    final clubId = ref.watch(activeClubIdProvider);
    final unread = ref.watch(unreadCountProvider(clubId)).value ?? 0;
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) => widget.shell.goBranch(
          i,
          // Tapping the current tab returns to its root, like most apps.
          initialLocation: i == widget.shell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Runs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
