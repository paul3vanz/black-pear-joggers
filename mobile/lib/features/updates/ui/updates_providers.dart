import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../membership/data/membership_dtos.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/posts_repository.dart';

/// Live cached posts for a club (pinned first, then newest). Hand-written because
/// riverpod_generator can't reference Drift's generated `Post` class.
final postsProvider = StreamProvider.family<List<Post>, int>(
  (ref, clubId) => ref.watch(postsRepositoryProvider).watchPosts(clubId),
);

/// One cached post by id (null if it isn't cached, e.g. a stale deep link).
final postProvider = StreamProvider.family<Post?, String>(
  (ref, id) => ref.watch(postsRepositoryProvider).watchPost(id),
);

/// True when the active membership has the `committee` or `admin` role, i.e. the
/// user may publish club updates. The server enforces this too (403).
final canPostProvider = Provider<bool>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  if (membership == null) return false;
  final roles = decodeRoles(membership.rolesJson);
  return roles.contains('committee') || roles.contains('admin');
});
