import 'package:bpj/core/db/app_database.dart';
import 'package:drift/drift.dart';

/// Phase 6.5 fixtures matching docs/api-contract.md (member profile cards).
const photoPathJson = '/app/clubs/1/members/sam/photo?v=ab12cd34&sig=ff00';

Map<String, Object?> memberCardJson(
  String memberId, {
  String displayName = 'Sam B.',
  String? photoPath,
  List<String> roles = const [],
  bool hasBio = false,
}) => {
  'memberId': memberId,
  'displayName': displayName,
  'photoPath': photoPath,
  'roles': roles,
  'hasBio': hasBio,
};

Map<String, Object?> memberCardsBody(List<Map<String, Object?>> items) => {
  'items': items,
  'serverTime': '2026-10-12T18:00:00.000Z',
};

/// `GET /members/{id}/profile`.
Map<String, Object?> memberProfileJson(
  String memberId, {
  String displayName = 'Sam B.',
  List<String> roles = const [],
  String? photoPath,
  String? bio = 'Love a hilly run.',
  String? goals,
  bool isYou = false,
}) => {
  'memberId': memberId,
  'displayName': displayName,
  'roles': roles,
  'photoPath': photoPath,
  'bio': bio,
  'goals': goals,
  'isYou': isYou,
};

/// `GET/PUT /member-profile`.
Map<String, Object?> myCardJson({
  String? bio,
  String? goals,
  bool goalsVisible = false,
  String? photoPath,
}) => {
  'bio': bio,
  'goals': goals,
  'goalsVisible': goalsVisible,
  'photoPath': photoPath,
  'updatedAt': '2026-10-12T18:00:00.000Z',
};

/// A 422 body with a message on one field.
Map<String, Object?> validationBody(String field, String message) => {
  'error': 'validation_failed',
  'message': 'The given data was invalid.',
  'errors': {
    field: [message],
  },
};

Future<void> seedCard(
  AppDatabase db,
  String memberId, {
  String name = 'Sam B.',
  String? photoPath,
  int clubId = 1,
}) => db
    .into(db.memberCards)
    .insertOnConflictUpdate(
      MemberCardsCompanion.insert(
        memberId: memberId,
        clubId: clubId,
        displayName: name,
        photoPath: Value(photoPath),
      ),
    );
