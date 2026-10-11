import 'package:drift/drift.dart';

/// Drift tables ≈ Drizzle schema. Each class becomes a table (snake_case column names)
/// and, after codegen, a typed row class: `Memberships` → `Membership`.

/// Cached `memberships[]` from `GET /app/me`: one row per club this login is linked to.
class Memberships extends Table {
  TextColumn get memberId => text()();
  IntColumn get clubId => integer()();
  TextColumn get clubName => text()();
  TextColumn get clubSlug => text()();
  TextColumn get joinUrl => text().nullable()();
  TextColumn get status => text()();

  /// JSON array of role strings, e.g. `["leader"]`.
  TextColumn get rolesJson => text().withDefault(const Constant('[]'))();

  // Athlete summary (null if the member has no athlete record).
  IntColumn get athleteId => integer().nullable()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get category => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

/// Cached `GET /app/clubs/{clubId}/profile` for the member's own record.
class Profiles extends Table {
  TextColumn get memberId => text()();
  IntColumn get clubId => integer()();
  TextColumn get status => text()();
  TextColumn get rolesJson => text().withDefault(const Constant('[]'))();

  // athlete
  IntColumn get athleteRowId => integer().nullable()(); // athlete.id
  IntColumn get athleteId =>
      integer().nullable()(); // athlete.athleteId (EA/URN)
  TextColumn get po10Guid => text().nullable()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get category => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(false))();
  BoolColumn get affiliated => boolean().withDefault(const Constant(false))();

  // membership (null columns when the API returns `membership: null`)
  TextColumn get competitiveRegStatus => text().nullable()();
  TextColumn get firstClaimClubName => text().nullable()();

  // links
  TextColumn get resultsUrl => text().nullable()();
  TextColumn get powerOf10Url => text().nullable()();
  TextColumn get claimAwardUrl => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

/// Cached club updates (`GET /app/clubs/{clubId}/posts`). Tombstones from the API
/// delete the row rather than being stored.
class Posts extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();
  TextColumn get title => text()();
  TextColumn get bodyMd => text()();

  /// `normal` | `important`.
  TextColumn get priority => text().withDefault(const Constant('normal'))();

  /// `all` | `leaders` | `committee`.
  TextColumn get audience => text().withDefault(const Constant('all'))();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get pinnedUntil => dateTime().nullable()();
  TextColumn get authorMemberId => text()();
  TextColumn get authorName => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cached notification inbox (`GET /app/clubs/{clubId}/notifications`).
class InboxItems extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  /// JSON object, e.g. `{"route":"/updates/<postId>"}`.
  TextColumn get dataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();

  /// True while a local "mark read" hasn't reached the server yet. The next refresh
  /// retries it. Cleared once the POST succeeds.
  BoolColumn get readPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Delta-sync position per list, e.g. key `posts:1` -> the last `serverTime`.
class SyncCursors extends Table {
  TextColumn get key => text()();
  TextColumn get serverTime => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Cached venues (`GET /app/clubs/{clubId}/venues`). Tombstones delete the row.
class Venues extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cached weekly patterns (`GET /app/clubs/{clubId}/series`). Dates are
/// `yyyy-MM-dd` text and times `HH:mm` text (club-local, never converted).
@DataClassName('RunSeries')
class SessionSeries extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get venueId => text().nullable()();

  /// ISO weekday, 1 = Monday ... 7 = Sunday.
  IntColumn get weekday => integer()();
  TextColumn get startTime => text()();
  IntColumn get durationMin => integer()();
  IntColumn get intervalWeeks => integer().withDefault(const Constant(1))();
  TextColumn get validFrom => text()();
  TextColumn get validUntil => text().nullable()();

  /// `paced` | `single` | `open` | `routes`.
  TextColumn get groupMode => text()();
  TextColumn get cmsSlug => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cached concrete dated runs (`GET /app/clubs/{clubId}/sessions`). Display and
/// grouping use the club-local `localDate` / `localStartTime` / `localEndTime`
/// strings (D17); `startsAt` / `endsAt` are the UTC instants.
class Sessions extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();
  TextColumn get seriesId => text().nullable()();
  TextColumn get occurrenceDate => text().nullable()();
  TextColumn get title => text()();
  TextColumn get venueId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get localDate => text()();
  TextColumn get localStartTime => text()();
  TextColumn get localEndTime => text()();
  TextColumn get groupMode => text()();

  /// `scheduled` | `cancelled`.
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get coordinatorMemberId => text().nullable()();
  TextColumn get coordinatorName => text().nullable()();
  BoolColumn get isDetached => boolean().withDefault(const Constant(false))();

  /// JSON of the contract's `original` block (what the series says), or null.
  TextColumn get originalJson => text().nullable()();

  /// JSON array of the contract's embedded `groups` (Phase 4), or null for an
  /// older payload that had none.
  TextColumn get groupsJson => text().nullable()();

  /// JSON of the contract's `summary` block for the caller (Phase 4), or null.
  TextColumn get summaryJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The last `GET …/sessions/{id}/plan` response, cached for offline viewing (D22).
@DataClassName('SessionPlanRow')
class SessionPlans extends Table {
  TextColumn get sessionId => text()();
  IntColumn get clubId => integer()();
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId};
}

/// The caller's own response for a session (one row per session). `pending` means
/// the PUT has not been confirmed by the server yet (D23).
@DataClassName('MyAttendanceRow')
class MyAttendance extends Table {
  TextColumn get sessionId => text()();
  IntColumn get clubId => integer()();

  /// `going` | `maybe` | `not_going`.
  TextColumn get status => text()();
  TextColumn get groupId => text().nullable()();

  /// Per-run pace override, stored as entered (`mi`/`km` + seconds).
  TextColumn get paceUnit => text().nullable()();
  IntColumn get paceFromS => integer().nullable()();
  IntColumn get paceToS => integer().nullable()();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId};
}

/// The caller's running preferences for a club (units and usual pace range).
@DataClassName('RunPreferences')
class Preferences extends Table {
  IntColumn get clubId => integer()();
  TextColumn get paceUnit => text()();
  TextColumn get distanceUnit => text()();
  IntColumn get paceFromS => integer().nullable()();
  IntColumn get paceToS => integer().nullable()();

  /// Null until the server has stored them.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clubId};
}
