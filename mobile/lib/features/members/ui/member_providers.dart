import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/db/app_database.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/member_dtos.dart';
import '../data/member_profile_repository.dart';

// Hand-written (not @riverpod): riverpod_generator can't see Drift's row types.

/// Every cached member card of the active club by member id (D61). Avatars
/// watch this one stream (with `.select` for their own member) instead of
/// opening a query each.
final memberCardsProvider = StreamProvider<Map<String, MemberCard>>((ref) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  final clubId = ref.watch(activeClubIdProvider);
  return ref.watch(memberProfileRepositoryProvider).watchCards(clubId);
});

/// One member's cached card, or null when they have none (a plain member with
/// no photo/bio is not listed; draw initials from the name you already have).
final memberCardProvider = StreamProvider.family<MemberCard?, String>((
  ref,
  memberId,
) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  return ref.watch(memberProfileRepositoryProvider).watchCard(memberId);
});

/// The last fetched profile of a member (profile page), null until fetched.
final memberProfileProvider = StreamProvider.family<MemberProfile?, String>((
  ref,
  memberId,
) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  final clubId = ref.watch(activeClubIdProvider);
  return ref
      .watch(memberProfileRepositoryProvider)
      .watchProfile(clubId, memberId);
});

/// The caller's own cached card (photo, bio, goals); null until fetched once.
final myCardProvider = StreamProvider<MyCard?>((ref) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  final clubId = ref.watch(activeClubIdProvider);
  return ref.watch(memberProfileRepositoryProvider).watchMine(clubId);
});

/// The caller's own member id in the active club (from the cached membership).
final ownMemberIdProvider = Provider<String?>(
  (ref) => ref.watch(activeMembershipProvider)?.memberId,
);

/// Turns a card's relative `photoPath` into a full URL. A provider so tests can
/// swap it (same idea as the other injectable helpers).
final memberPhotoUrlProvider = Provider<String? Function(String?)>(
  (ref) => memberPhotoUrl,
);

/// Friendly text for a failed profile-card write or moderation call.
String memberErrorMessage(Object error) {
  final api = ApiException.from(error);
  if (api.isNetworkError) return 'You need a connection to do that.';
  if (api.statusCode == 403) return 'Only the committee can do that.';
  return api.message;
}
