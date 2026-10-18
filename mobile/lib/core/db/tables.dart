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

  /// Null = the run has no fixed end time (D47).
  IntColumn get durationMin => integer().nullable()();
  IntColumn get intervalWeeks => integer().withDefault(const Constant(1))();
  TextColumn get validFrom => text()();
  TextColumn get validUntil => text().nullable()();

  /// `paced` | `single` | `open` | `routes`.
  TextColumn get groupMode => text()();
  TextColumn get cmsSlug => text().nullable()();

  /// Optional banner image URL (D49).
  TextColumn get imageUrl => text().nullable()();
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

  /// Null when the run has no end time (D47). `endsAt` stays filled (start + 3 h)
  /// so "is it over" checks keep working; see D52.
  TextColumn get localEndTime => text().nullable()();
  TextColumn get groupMode => text()();

  /// `scheduled` | `cancelled`.
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  TextColumn get cancelReason => text().nullable()();

  /// The series' banner image URL, copied onto the run by the server (D49).
  TextColumn get imageUrl => text().nullable()();

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

  /// "Days I may lead" (D107): comma-separated ISO weekdays (`2,4`, Monday = 1).
  /// Null = never chosen, empty string = chose none. The server owns it; this is
  /// a cache (D111).
  TextColumn get leadDays => text().nullable()();

  /// "Days I run" (D115), the same encoding as [leadDays]. Null = never chosen
  /// (every day). Hides runs on other days on the Runs tab.
  TextColumn get runDays => text().nullable()();

  /// Null until the server has stored them.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clubId};
}

/// Cached group chat messages (`GET …/groups/{groupId}/messages`), including
/// the caller's own unsent ones (D43). A deleted message stays as a tombstone
/// (`deletedAt` set, empty body) so it can show "Message deleted".
class GroupMessages extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();
  TextColumn get groupId => text()();
  TextColumn get memberId => text()();

  /// First name + surname initial, as sent by the server (`Sam B.`).
  TextColumn get authorName => text()();

  /// The author's role in this thread: `leader` | `coordinator` | `committee` | `member`.
  TextColumn get authorRole => text().withDefault(const Constant('member'))();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// `sent` | `pending` (outbox, retried) | `failed` (refused, Retry/Delete).
  TextColumn get sendState => text().withDefault(const Constant('sent'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Per-thread state for the caller: what `GET …/threads` says (unread count,
/// mute, closed, last message and the run it belongs to) plus the
/// `closed`/`muted` flags the messages endpoint reports. One row per group.
class ThreadStates extends Table {
  TextColumn get groupId => text()();
  IntColumn get clubId => integer()();

  /// Null until the thread has been listed by `GET …/threads`.
  TextColumn get sessionId => text().nullable()();

  /// The group's pace/label text in the caller's units.
  TextColumn get label => text().nullable()();

  /// Club-local `yyyy-MM-dd` of the run.
  TextColumn get localDate => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  TextColumn get lastBody => text().nullable()();
  TextColumn get lastAuthor => text().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  BoolColumn get closed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {groupId};
}

/// One row per member in `GET …/member-cards` (D61): who is shown by name or has a
/// photo/bio. The whole list for a club is replaced on every refresh. Avatars and
/// names across the app are drawn from this table, so cached runs and chat never
/// go stale when someone changes their photo.
class MemberCards extends Table {
  TextColumn get memberId => text()();
  IntColumn get clubId => integer()();

  /// First name + surname initial (`Sam B.`).
  TextColumn get displayName => text()();

  /// Relative signed link (`/app/clubs/1/members/<id>/photo?v=…&sig=…`) or null.
  TextColumn get photoPath => text().nullable()();

  /// Comma-separated subset of `leader,committee,admin` (empty for none).
  TextColumn get rolesCsv => text().withDefault(const Constant(''))();
  BoolColumn get hasBio => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

/// The last fetched profile JSON per member (the profile page works offline from
/// this). The caller's own editable card (`GET …/member-profile`) is kept in the
/// same table under the fixed key `me` (it can't clash with a member uuid).
@DataClassName('MemberProfileRow')
class MemberProfiles extends Table {
  TextColumn get memberId => text()();
  IntColumn get clubId => integer()();

  /// The response body, as sent.
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {memberId, clubId};
}

/// Cached club event locations (`GET /app/clubs/{clubId}/event-locations`,
/// Phase 8): the parkrun list (imported on the server), races and others. Unlike
/// venues, tombstones are kept (with [deletedAt]) and filtered out by queries.
class EventLocations extends Table {
  TextColumn get id => text()();
  IntColumn get clubId => integer()();

  /// `parkrun` | `race` | `other`.
  TextColumn get kind => text()();
  TextColumn get name => text()();

  /// parkrun site code, e.g. `worcester`.
  TextColumn get slug => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get region => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get url => text().nullable()();

  /// `import` | `manual`.
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The cached club standards document (Phase 9b, D90): one row per club holding
/// the response body as JSON text, so the screen reads a Drift stream like every
/// other feature. [etag] is what the server sent, replayed as `If-None-Match`.
@DataClassName('StandardsCacheRow')
class StandardsCache extends Table {
  IntColumn get clubId => integer()();
  TextColumn get bodyJson => text()();
  TextColumn get etag => text().nullable()();

  /// When the server last confirmed this copy (a 200 or a 304).
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {clubId};
}
