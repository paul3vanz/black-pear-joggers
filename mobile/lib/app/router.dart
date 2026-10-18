import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/accounts_controller.dart';
import '../core/diagnostics/db_guard.dart';
import '../features/auth/ui/sign_in_screen.dart';
import '../features/events/ui/event_locations_screen.dart';
import '../features/groups/ui/group_editor_screen.dart';
import '../features/groups/ui/leader_roster_screen.dart';
import '../features/groups/ui/members_roles_screen.dart';
import '../features/inbox/ui/inbox_screen.dart';
import '../features/membership/ui/link_screen.dart';
import '../features/membership/ui/membership_providers.dart';
import '../features/membership/ui/unavailable_screen.dart';
import '../features/members/ui/member_profile_screen.dart';
import '../features/members/ui/my_profile_card_screen.dart';
import '../features/messages/ui/chat_screen.dart';
import '../features/profile/ui/about_screen.dart';
import '../features/profile/ui/delete_account_screen.dart';
import '../features/profile/ui/diagnostics_screen.dart';
import '../features/profile/ui/recover_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../features/runs/ui/runs_screen.dart';
import '../features/runs/ui/series_screens.dart';
import '../features/runs/ui/session_detail_screen.dart';
import '../features/runs/ui/session_edit_screen.dart';
import '../features/runs/ui/venues_screen.dart';
import '../features/settings/ui/notification_settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/standards/ui/standards_screen.dart';
import '../features/updates/ui/compose_post_screen.dart';
import '../features/updates/ui/post_detail_screen.dart';
import '../features/updates/ui/updates_screen.dart';

part 'router.g.dart';

/// Root navigator key: routes that must cover the bottom navigation bar name it as
/// their `parentNavigatorKey`.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// go_router is the React Router of Flutter. `redirect` runs before every navigation,
/// like an auth guard in Next.js middleware:
///   * accounts (or the first `/app/me` refresh) still loading -> `/splash`
///   * nobody signed in                                         -> `/sign-in`
///   * the database failed its first check (twice)              -> `/recover`
///   * signed in, active club has no membership                 -> `/link`
///   * first load failed with nothing cached                    -> `/unavailable`
///   * linked                                                   -> `/runs`
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // go_router re-runs `redirect` when this notifier fires, i.e. when auth state or
  // the membership status changes.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(accountsControllerProvider, (_, _) => refresh.value++)
    ..listen(linkStatusProvider, (_, _) => refresh.value++)
    ..listen(dbGuardProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final accounts = ref.read(accountsControllerProvider);
      final location = state.matchedLocation;

      String? only(String target) => location == target ? null : target;

      if (!accounts.hasValue) return only('/splash');
      if (accounts.requireValue.activeSub == null) return only('/sign-in');

      // The database must prove it can answer a query before any screen reads
      // it (D101). `/recover` is the way out when it can't, even after a reset.
      final guard = ref.read(dbGuardProvider);
      if (guard.hasError || guard.value == DbGuardResult.failed) {
        return only('/recover');
      }
      if (!guard.hasValue) return only('/splash');
      if (location == '/recover') return '/';

      return switch (ref.read(linkStatusProvider)) {
        LinkStatus.unknown => only('/splash'),
        LinkStatus.unavailable => only('/unavailable'),
        LinkStatus.needsLink => only('/link'),
        // `/link` stays reachable once linked: the "we think we found you"
        // confirmation is shown there right after a successful link.
        LinkStatus.linked =>
          const {'/sign-in', '/splash', '/unavailable'}.contains(location)
              ? '/runs'
              : null,
      };
    },
    routes: [
      // `/` is only an entry point; the home tab is Runs.
      GoRoute(path: '/', redirect: (_, _) => '/runs'),
      // Bottom-navigation shell: one Navigator per tab, state kept when switching.
      // React Router equivalent: a layout route with an <Outlet/> per tab.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/runs',
                builder: (_, _) => const RunsScreen(),
                routes: [
                  // Literal paths (`new`, `series`, `venues`) must come before
                  // `:id`. All of these push above the shell.
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const SessionEditScreen(),
                  ),
                  GoRoute(
                    path: 'lead',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const LeaderRosterScreen(),
                  ),
                  GoRoute(
                    path: 'series',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const SeriesListScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, _) => const SeriesEditScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => SeriesEditScreen(
                          seriesId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'venues',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const VenuesScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, _) => const VenueEditScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => VenueEditScreen(
                          venueId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, state) => SessionDetailScreen(
                      sessionId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => SessionEditScreen(
                          sessionId: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        path: 'groups/new',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => GroupEditorScreen.fromUri(
                          state.pathParameters['id']!,
                          state.uri,
                        ),
                      ),
                      GoRoute(
                        path: 'groups/:groupId/edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => GroupEditorScreen(
                          sessionId: state.pathParameters['id']!,
                          groupId: state.pathParameters['groupId'],
                        ),
                      ),
                      // Also the target of a group-message push (D42).
                      GoRoute(
                        path: 'groups/:groupId/chat',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => ChatScreen(
                          sessionId: state.pathParameters['id']!,
                          groupId: state.pathParameters['groupId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/updates',
                builder: (_, _) => const UpdatesScreen(),
                routes: [
                  // Detail/compose push above the shell (root navigator), but
                  // `go('/updates/<id>')` still leaves the Updates tab beneath.
                  // `new` must come before `:id`.
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const ComposePostScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, state) =>
                        PostDetailScreen(postId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'card',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const MyProfileCardScreen(),
                  ),
                  GoRoute(
                    path: 'standards',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const StandardsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'members',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const MembersRolesScreen(),
                  ),
                  GoRoute(
                    path: 'event-locations',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const EventLocationsScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const AboutScreen(),
                    routes: [
                      // A real route (not Navigator.push) so signing out replaces
                      // it along with everything else.
                      GoRoute(
                        path: 'delete',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, _) => const DeleteAccountScreen(),
                      ),
                      GoRoute(
                        path: 'diagnostics',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, _) => const DiagnosticsScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // A member's profile, pushed above whatever screen opened it (D62).
      GoRoute(
        path: '/members/:memberId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) =>
            MemberProfileScreen(memberId: state.pathParameters['memberId']!),
      ),
      // Outside the shell and with no database access: shown when the saved
      // data can't be opened even after the automatic repair (D101).
      GoRoute(path: '/recover', builder: (_, _) => const RecoverScreen()),
      GoRoute(path: '/link', builder: (_, _) => const LinkScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: '/unavailable',
        builder: (_, _) => const UnavailableScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
