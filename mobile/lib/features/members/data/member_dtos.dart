// Wire shapes for the Phase 6.5 member card endpoints (see docs/api-contract.md).
// Hand-written, like the other DTOs.

/// The longest bio the server accepts.
const maxBioLength = 300;

/// The longest goals text the server accepts.
const maxGoalsLength = 1000;

/// Roles shown as badges, in display order. The server only ever sends these.
const memberBadgeRoles = ['leader', 'committee', 'admin'];

List<String> _stringList(Object? value) => [
  for (final v in (value as List<Object?>? ?? const [])) '$v',
];

/// `GET /members/{memberId}/profile`: what other members see.
class MemberProfile {
  const MemberProfile({
    required this.memberId,
    required this.displayName,
    this.roles = const [],
    this.photoPath,
    this.bio,
    this.goals,
    this.isYou = false,
  });

  final String memberId;
  final String displayName;
  final List<String> roles;
  final String? photoPath;
  final String? bio;

  /// Null unless the member shares their goals (or this is your own profile).
  final String? goals;
  final bool isYou;

  factory MemberProfile.fromJson(Map<String, Object?> json) => MemberProfile(
    memberId: json['memberId']! as String,
    displayName: json['displayName']! as String,
    roles: _stringList(json['roles']),
    photoPath: json['photoPath'] as String?,
    bio: json['bio'] as String?,
    goals: json['goals'] as String?,
    isYou: json['isYou'] as bool? ?? false,
  );
}

/// `GET/PUT /member-profile`: the caller's own editable card.
class MyCard {
  const MyCard({
    this.bio,
    this.goals,
    this.goalsVisible = false,
    this.photoPath,
    this.updatedAt,
  });

  final String? bio;
  final String? goals;
  final bool goalsVisible;
  final String? photoPath;
  final String? updatedAt;

  bool get isEmpty =>
      (bio ?? '').isEmpty && (goals ?? '').isEmpty && photoPath == null;

  factory MyCard.fromJson(Map<String, Object?> json) => MyCard(
    bio: json['bio'] as String?,
    goals: json['goals'] as String?,
    goalsVisible: json['goalsVisible'] as bool? ?? false,
    photoPath: json['photoPath'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );
}

/// A profile (or own card) and whether it came from the local cache because the
/// network was unreachable.
class Fetched<T> {
  const Fetched(this.value, {this.fromCache = false, this.fetchedAt});

  final T value;
  final bool fromCache;
  final DateTime? fetchedAt;
}

/// Thrown by the online-first reads when there is no connection AND nothing is
/// cached to show instead.
class MemberOfflineException implements Exception {
  const MemberOfflineException();

  @override
  String toString() => 'MemberOfflineException';
}
