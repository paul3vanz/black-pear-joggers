# App API contract

This is the contract between `api/` and the Flutter app. Update it whenever an
endpoint changes.

All routes are under `/app` and require an Auth0 bearer token (audience
`https://bpj.org.uk`). JSON uses **camelCase** keys. Errors return
`{ "error": "<code>", "message": "<human text>" }`.

## Phase 1

### `GET /app/me`
Returns the caller's linked memberships, plus the clubs they could link to.
```json
{
  "userId": "google-oauth2|1234",
  "memberships": [
    {
      "memberId": "9b1d…-uuid",
      "club": { "id": 1, "name": "Black Pear Joggers", "slug": "bpj", "joinUrl": "https://bpj.org.uk/membership" },
      "status": "active",
      "roles": ["leader"],
      "athlete": { "id": 123, "firstName": "Jo", "lastName": "Bloggs", "gender": "W", "category": "V40" }
    }
  ],
  "clubs": [ { "id": 1, "name": "Black Pear Joggers", "slug": "bpj", "joinUrl": "https://bpj.org.uk/membership" } ]
}
```

### `POST /app/clubs/{clubId}/link`
Checks the athlete against `athletes` (`urn` + `dob`) and links this login to
that member in one step. It creates the `club_members` row if needed and also
sets the legacy `users.athleteId` so the web profile matches.

The same athlete can be linked from several logins. If this login is already
linked to a *different* member of this club, the link is moved.

Request:
```json
{ "urn": 1234567, "dob": "1983-01-01" }
```

| Status | Body |
|---|---|
| 200 | One `memberships[]` item, same shape as in `GET /app/me` |
| 404 | `{ "error": "not_found" }`: no athlete with that URN + DOB |
| 422 | Validation error |
| 429 | `{ "error": "too_many_attempts" }`: more than 5 failed attempts in the last hour for this login |

### `DELETE /app/clubs/{clubId}/link`
Unlinks this login from the club. The member row is kept. Returns 204.

### `GET /app/clubs/{clubId}/profile`
Returns 403 `{ "error": "not_a_member" }` if this login isn't linked to the club.
```json
{
  "memberId": "uuid",
  "status": "active",
  "roles": [],
  "athlete": {
    "id": 123, "athleteId": 450606, "po10Guid": "…|null",
    "firstName": "Jo", "lastName": "Bloggs", "gender": "W", "category": "V40",
    "active": true, "affiliated": true
  },
  "membership": { "competitiveRegStatus": "Registered", "firstClaimClubName": "Black Pear Joggers" },
  "links": {
    "results": "https://apps.bpj.org.uk/race-results/#/athlete/450606",
    "powerOf10": "https://www.powerof10.uk/…|null",
    "claimAward": "https://bpj.org.uk/claim-award"
  }
}
```
`membership` is `null` when there's no EA sync row. `status` is recalculated
from `athlete.active` on every call and saved.

## Implementation notes (Phase 1)

- `{clubId}` that doesn't exist returns 404 `{ "error": "club_not_found" }` on all three club routes.
- `422` bodies are `{ "error": "validation_failed", "message": "…", "errors": { "field": ["…"] } }`.
  `dob` must be `Y-m-d`; `urn` must be an integer.
- `403 not_a_member` also carries a `message`.
- Rate limit: once a login has **5** failed attempts for the club in the last hour, further attempts
  (even with correct details) get 429. Successful links are not counted.
- `DELETE /app/clubs/{clubId}/link` returns 204 even if the login wasn't linked.
- `GET /app/clubs/{clubId}/profile` returns 404 `{ "error": "athlete_not_found" }` if the member's athlete row has gone.
- `links.results` is `null` when the athlete has no EA `athleteId`.
- `athlete.athleteId` in the profile is `athletes.athlete_id`; `athlete.id` is the internal `athletes.id`.
- Neither `urn` nor `dob` is ever returned.

## Phase 2: devices, club updates, notifications

The shapes below are the same as Phase 1. `?since=` lists return
`{ "items": [...], "serverTime": "<ISO8601>" }`. Pass `serverTime` back as
`since` on the next call. Items may include `deletedAt` (tombstones).

### Devices (per login, not per club)
- `POST /app/devices` with `{ "token": "<fcm token>", "platform": "android|ios", "appVersion": "1.0.0+1" }` → 204.
  - Upserts by token. If the token was registered to another login (a shared
    device), it's moved to the caller.
- `DELETE /app/devices/{token}` → 204. Removes the token only if it belongs to
  the caller.

### Posts (club updates)
- `GET /app/clubs/{clubId}/posts?since=` returns:
  ```json
  { "items": [ { "id": "uuid", "title": "…", "bodyMd": "markdown", "priority": "normal|important",
                 "audience": "all|leaders|committee", "publishedAt": "…", "pinnedUntil": "…|null",
                 "author": { "memberId": "uuid", "displayName": "Jo Bloggs" },
                 "updatedAt": "…", "deletedAt": "…|null" } ],
    "serverTime": "…" }
  ```
  - Members only get posts whose audience they're in. `leaders` covers the
    `leader`, `committee` and `admin` roles; `committee` covers `committee` and
    `admin`.
- `POST /app/clubs/{clubId}/posts` (roles `committee`/`admin`, otherwise 403 `forbidden`):
  - Request: `{ "id": "client-uuid?", "title", "bodyMd", "priority", "audience", "pinnedUntil?", "notify": true }`.
  - Returns 201 with the Post.
  - It's idempotent on `id`.
  - With `notify`, each member in the audience gets an inbox notification
    (category `club_updates`) and a push.
- `PATCH /app/clubs/{clubId}/posts/{id}` updates the same fields (except
  `notify`). `DELETE` soft-deletes and returns 204. Both are for `committee`/`admin` only.

### Post receipts (D123)
Every member's app reports, always on and not a setting, when an update reached the phone and when it was read.
Only the committee can read them back.
- `POST /app/clubs/{clubId}/posts/receipts` with `{ "items": [ { "postId", "state": "delivered|read", "at?" } ] }`
  (1 to 100 items) → 204.
  - Reports the caller's own state. It's idempotent, never goes backwards (the earliest `at` wins) and a future
    `at` is clamped to now. `read` implies `delivered`.
  - Posts the caller can't see, or wrote, and unknown ids are ignored (still 204). A malformed item is 422.
- `GET /app/clubs/{clubId}/posts/{id}/receipts` (`committee`/`admin`, else 403; unknown post 404) returns:
  ```json
  { "postId": "uuid", "audienceCount": 40, "deliveredCount": 31, "readCount": 22,
    "members": [ { "memberId": "uuid", "displayName": "Sam B.", "state": "none|delivered|read",
                   "deliveredAt": "…|null", "readAt": "…|null" } ] }
  ```
  - `members` is every active member the post was meant for, except its author, sorted by name.
    `deliveredCount` includes the read ones.
  - **Delivered** is the earlier of the app's report and the push being accepted by Firebase
    (`notifications.pushed_at` of the `post:<id>` notification, which `POST /posts` with `notify` now sets as its
    dedupe key). Updates published before D123 only have the app's report.
  - **Read** means the member opened the update and read to the end (the app waits about 2 seconds on a short
    update, or until the end of a long one).
- Table `post_receipts(id, club_id, post_id, member_id, delivered_at?, read_at?)`, unique on (post, member). It's
  in `AccountDeletion`. Host SQL: `api/database/manual/2026_10_post_receipts.sql`.
### Leaders thread (D125)
One chat per run between the committee and the people who lead, or have been asked to lead, that run. The shapes
and rules are the group chat's; the thread id the app uses where a group id would go is `leaders:<sessionId>`.
Base path `/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat`.
- **Who is in it:** active `committee`/`admin` (always), confirmed leaders of any group of the run, and members an
  ask went to (`leader_thread_members`). Anyone else: 403 `not_in_thread`; an unknown run: 404.
- `GET /messages?since=` → `{ items, serverTime, closed, muted }`, like a group thread. A message adds
  `kind: "message"|"ask"`, `askFastSPerKm`, `askSlowSPerKm` (an ask's pace range in seconds per km, null for "any
  pace") and `groupId: "leaders:<sessionId>"`. `authorRole` is `committee`, `leader` (leads a group of the run) or `member`.
- `POST /messages { id?, body }`, `DELETE /messages/{id}` (author or committee), `POST /messages/read`,
  `PUT /thread { muted }`: as for a group chat. Closed (409 `thread_closed`) while the run is cancelled and 12
  hours after it ends.
- `POST /ask { id?, fastSPerKm?, slowSPerKm?, note? }` (`committee`/`admin` only, else 403) → `{ message, notified }`.
  - Pace is 150-900 s/km, slow not faster than fast, and a pace needs both ends. None means any leader.
  - Posts an `ask` message, adds everyone who may lead at that pace (`RunNotifier::availableLeaders`: the leaders-needed
    audience, with the ask's pace instead of a group's) to the thread and sends them `leaders_needed` ("Can you lead
    8:25-10:05/mi at 7pm on Thursday?", spoken in their units). `notified` is how many. The rest of the thread hears
    it as a message. It's idempotent on `id` (replay: 200, `notified` 0).
  - **Repeat:** a day later, `app:send-reminders` repeats it once, to the people asked who haven't posted and
    aren't leading, only while a run still has 2+ hours to go, nobody leads a group at that pace, and between 08:00
    and 21:00 local time (it waits for a sensible hour). `leader_messages.renudged_at` marks it done.
- **`GET /threads`** also lists the leaders threads the caller is in that have a message in the last 14 days:
  `kind: "leaders"`, `groupId: "leaders:<sessionId>"`, `label: "Leaders"`. Group threads have no `kind`.
- **Notifications:** messages are `group_messages` (key `leader_msg:<sessionId>`, one inbox row per member, one push
  per 5 minutes); asks are `leaders_needed` (key `leader_ask:<messageId>`, repeat `leader_ask_repeat:<messageId>`).
  All carry `route: /runs/<id>/leaders-chat`.
- Tables `leader_messages`, `leader_thread_states`, `leader_thread_members` are in `AccountDeletion`. Host SQL:
  `api/database/manual/2026_10_leader_threads.sql`.
### Notifications (inbox)
- `GET /app/clubs/{clubId}/notifications?since=` returns:
  ```json
  { "items": [ { "id": "uuid", "category": "club_updates", "title": "…", "body": "…",
                 "data": { "route": "/updates/<postId>" }, "createdAt": "…", "readAt": "…|null" } ],
    "serverTime": "…", "unreadCount": 3 }
  ```
- `POST /app/clubs/{clubId}/notifications/read` with `{ "ids": ["uuid", …] }` or
  `{ "all": true }` → 204.

### Notification preferences
- `GET /app/clubs/{clubId}/notification-preferences` returns
  `{ "categories": [ { "category": "club_updates", "label": "Club updates", "description": "…", "pushEnabled": true, "locked": false } ] }`.
  - Categories are those in data-model.md.
  - `locked` categories can't be turned off: `my_group_changes`, and
    `important` posts are always pushed.
  - `leaders_needed` is listed only for members who can lead. In practice that's
    every member (D12), but it's off by default for members without the `leader`
    role.
- `PUT` the same path with `{ "club_updates": false, … }`. Returns the same
  shape. Locked categories are ignored.

### Push payload (FCM HTTP v1)
- `notification`: `{ title, body }`
- `data` (all strings): `{ notificationId, clubId, userId, category, route }`
- `android.notification.channel_id` is the category, so the app creates one
  Android channel per category.

## Implementation notes (Phase 2)

- All club routes use `club:required`, so an unknown club is 404 `club_not_found` and an unlinked login is
  403 `not_a_member`. Validation errors use the Phase 1 422 shape. A bad `since` is 422.
- **`since` / `serverTime`:** `since` filters on `updated_at >= since`, and `serverTime` is "now" floored to the
  second, so a row written in the same second may come back twice (upsert by `id`). Timestamps are UTC with
  milliseconds, e.g. `2026-10-07T12:00:00.000Z`.
- **Devices:** the token column is 255 chars (FCM tokens are about 160). `DELETE /app/devices/{token}` takes
  tokens containing `:` and percent-escapes. It returns 204 even if the token is unknown or belongs to another
  login (nothing is removed in that case).
- **Posts:**
  - `GET` without `since` omits deleted posts. With `since` it returns changes **and** tombstones
    (`deletedAt` set), filtered by the caller's audiences. If a post's audience is narrowed by `PATCH`, members
    who lose access are not sent a tombstone.
  - `POST` request: `title` and `bodyMd` required. `priority` defaults to `normal` and `audience` to `all`.
    `notify` **defaults to false**. `id`, if given, must be a UUID. `publishedAt` is set by the server.
  - `POST` replay with an `id` that already exists in this club returns **200** with the stored post (not 201),
    does not change it and does not notify again. An `id` used by another club's post returns 409 `conflict`.
  - `PATCH` returns 200 with the post. Missing/deleted post is 404 `not_found`. `pinnedUntil: null` clears it.
  - `DELETE` returns 204 even if the post is missing or already deleted. The 403 check comes first.
  - Notify audience: members of this club with `status = active` whose roles fit the post audience, excluding
    the author. Notification title is the post title, body is the first 140 characters of the markdown with
    formatting characters stripped, `data` is `{ "route": "/updates/<postId>" }`. `priority: important` forces
    the push even for members who turned `club_updates` off.
- **Notifications inbox:** `since` filters on `updated_at`, so marking a row read re-sends it with `readAt` set.
  Without `since` it returns the newest 200, oldest first. `unreadCount` is for the caller's whole inbox.
  `read` needs `ids` or `all` (else 422), and ignores ids that are not the caller's. `data` is always an object.
- **Preferences:** `GET` lists all six categories to everyone (`leaders_needed` is listed for every member but
  defaults to off unless they hold the `leader` role). `locked` categories report `pushEnabled: true`.
  `PUT` ignores unknown and locked categories, and a non-boolean value is 422 with nothing saved.
  Preferences belong to the member, so all of their logins share them.
- **Push:**
  - The inbox row is always written. One `SendPushNotificationsJob` is queued per `notifyMembers` call on the
    `notifications` queue (only when someone is push eligible). It sends to every device of every login of the member.
  - `notifications.pushed_at` is set when at least one device accepted the message. Tokens FCM reports as
    UNREGISTERED, NOT_FOUND or invalid are deleted.
  - If `FCM_SERVICE_ACCOUNT_PATH` is unset or the file is missing, no push is sent and one warning is logged
    per process. Inbox rows still exist.
  - Not done: the "send synchronously if the host can't run the cron" fallback. The queue is drained by
    `schedule:run` every minute (host cron needed).
- **Roles:** granted with `php artisan app:member-role {clubId} {athleteId} {leader|committee|admin} [--remove]`,
  where `athleteId` is `athletes.id` (the same value as `athlete.id` in the API). The member must have linked first.

## Phase 3: club runs schedule

All routes use `club:required` (any linked member can read). Writes need the
`committee` or `admin` role, otherwise 403 `{ "error": "forbidden" }`.
Lists support `?since=` as in Phase 2 (`{ items, serverTime }`, tombstones via
`deletedAt`, upsert by id).

### Time handling
- The club's timezone (`clubs.timezone`, `Europe/London`) is the source of truth
  for a run's time. A 19:00 run is 19:00 for everyone, wherever their phone is.
- Sessions carry both **UTC instants** (`startsAt`, `endsAt`) and **club-local
  strings** (`localDate` `2026-10-12`, `localStartTime` `19:00`,
  `localEndTime` `20:00`). The app groups and displays using the local strings.
- Weekdays are ISO numbers: 1 = Monday … 7 = Sunday.

### Venue
```json
{ "id": "uuid", "name": "Old Elizabethans Cricket Club", "address": "…|null",
  "lat": 52.19|null, "lng": -2.22|null, "notes": "…|null",
  "updatedAt": "…", "deletedAt": "…|null" }
```
- `GET /app/clubs/{clubId}/venues?since=`
- `POST /app/clubs/{clubId}/venues` with `{ id?, name, address?, lat?, lng?, notes? }` → 201 (idempotent on `id`)
- `PATCH /app/clubs/{clubId}/venues/{id}`, `DELETE …/{id}` → 204 (soft delete; refused with 409 `in_use` if an active series or a future session uses it)

### Series (the weekly pattern)
```json
{ "id": "uuid", "title": "Monday club run", "description": "…|null", "venueId": "uuid|null",
  "weekday": 1, "startTime": "19:00", "durationMin": 90, "intervalWeeks": 1,
  "validFrom": "2026-01-01", "validUntil": "…|null",
  "groupMode": "paced|single|open|routes", "cmsSlug": "monday-club-run|null",
  "updatedAt": "…", "deletedAt": "…|null" }
```
- `GET /app/clubs/{clubId}/series?since=`
- `POST /app/clubs/{clubId}/series` (idempotent on `id`) → 201, `PATCH …/series/{id}`, `DELETE …/series/{id}` → 204.
  Every write regenerates that series' sessions straight away (see below).
- Validation: `weekday` 1–7, `startTime` `HH:MM`, `durationMin` 15–600,
  `intervalWeeks` 1–8, `validUntil` ≥ `validFrom`, `groupMode` in the list.

### Sessions (concrete dated runs)
```json
{ "id": "uuid", "seriesId": "uuid|null", "occurrenceDate": "2026-10-12|null",
  "title": "Monday club run", "venueId": "uuid|null", "notes": "…|null",
  "startsAt": "2026-10-12T18:00:00Z", "endsAt": "…",
  "localDate": "2026-10-12", "localStartTime": "19:00", "localEndTime": "20:30",
  "groupMode": "paced", "status": "scheduled|cancelled", "cancelReason": "…|null",
  "coordinatorMemberId": "uuid|null", "coordinatorName": "Jo Bloggs|null",
  "isDetached": false,
  "original": null,
  "updatedAt": "…", "deletedAt": "…|null" }
```
- `original` is `null` unless the session was edited away from its series. When
  set it's `{ "localStartTime": "19:00", "venueId": "uuid|null", "title": "…" }`
  (what the series says), so the app can show "Moved from …" / "Earlier start".
- `GET /app/clubs/{clubId}/sessions?from=&to=&since=`
  - Without `since`: sessions with `localDate` in `[from, to]`
    (defaults: today … today + 60 days, club-local), excluding deleted ones.
  - With `since`: every session changed since then, any date, including
    tombstones. `from`/`to` are ignored.
- `POST /app/clubs/{clubId}/sessions` creates an **ad-hoc** run (no series):
  `{ id?, title, localDate, startTime, durationMin, venueId?, notes?, groupMode, coordinatorMemberId? }` → 201.
- `PATCH /app/clubs/{clubId}/sessions/{id}` edits **this occurrence only**:
  any of `title, localDate?, startTime, durationMin, venueId, notes, coordinatorMemberId`.
  (`localDate` can only change for ad-hoc runs; a series occurrence keeps its date.)
  Sets `isDetached = true` for a series occurrence.
- `POST …/sessions/{id}/cancel` `{ "reason": "Bank holiday" }` and
  `POST …/sessions/{id}/restore` → the updated session. Both detach it.
- `DELETE …/sessions/{id}` → 204: ad-hoc runs only (409 `series_session` for
  series occurrences; cancel them instead).

### Generation rules
- Sessions are materialised from today (club-local) to **today + 8 weeks**.
  `app:generate-sessions` (artisan) does it for every series; the scheduler runs
  it hourly (idempotent) and each series write runs it for that series.
- Occurrence dates: dates with the series weekday within `[validFrom, validUntil]`,
  every `intervalWeeks` weeks counted from the week containing `validFrom`.
- Existing, **non-detached**, future sessions are updated from the series
  (`startsAt/endsAt`, `venueId`, `title`, `groupMode`). `notes` and
  `coordinatorMemberId` are never overwritten.
- Detached sessions (edited, cancelled) are never touched.
- Future non-detached sessions whose date no longer matches the series (weekday
  changed, `validUntil` moved earlier, series deleted) are soft-deleted. A
  soft-deleted occurrence that matches again is restored, not duplicated.
- Past sessions are never changed. `unique(series_id, occurrence_date)`.

### Seed data (BPJ, club 1)
Created by a migration, so it travels in the manual SQL file. Dates and venue
details are best guesses for the committee to correct in the app:

| Series | Day / time | Venue | Mode | Valid |
|---|---|---|---|---|
| Monday club run | Mon 19:00, 90 min | Old Elizabethans Cricket Club | paced | from 2026-01-01 |
| Tuesday Riverside Run | Tue 19:00, 90 min | University of Worcester Riverside building | paced | from 2026-01-01 |
| Track night | Wed 19:00, 75 min | Nunnery Wood track | single | from 2026-01-01 |
| The Mug Run | Thu 18:30, 90 min | Claines Church | open | 2027-04-01 – 2027-09-30 |
| Thursday winter run | Thu 19:00, 90 min | Perdiswell Leisure Centre | paced | 2026-10-01 – 2027-03-31 |
| Sunday long run | Sun 08:00, 150 min | none yet | routes | from 2026-01-01 |

`cmsSlug` values follow the website's club-run slugs (check
`next/apps/cms` for the real ones; leave null if unknown).

### Implementation notes (Phase 3)

- **Tables** are `venues`, `session_series`, `sessions`, created by `2026_10_08_09xx` migrations. The manual SQL is
  `api/database/manual/2026_10_runs_tables.sql` (run after `2026_10_app_tables.sql`). `default_groups` from the data
  model is not created yet (nothing uses it until groups arrive). Eloquent model for `sessions` is `ClubSession`.
- **Seed** (migration `2026_10_08_090300_seed_bpj_runs`): five venues and the six series above, with venue `address`,
  `lat`, `lng` and `cmsSlug` all null (the Sanity slugs live in Sanity, not in the repo, and no addresses were
  invented). Re-running it is a no-op for any venue name or series title that already exists in club 1. **Sessions are
  not seeded**: they appear on the next hourly `app:generate-sessions` run (host cron) or the next series write, or run
  `php artisan app:generate-sessions` once after applying the SQL.
- **Generator:** "future" means `occurrence_date >= today` in the club timezone, so today's run is still regenerated
  until it is edited. A run writes nothing (and leaves `updatedAt` alone) when a session already matches its series,
  so `?since=` stays quiet. `app:generate-sessions` also walks soft-deleted series so their future sessions are removed.
  The 8-week window is inclusive (today + 56 days).
- **Series create:** `validFrom` is optional and defaults to today in the club timezone. `intervalWeeks` defaults to 1.
  A `venueId` that is not a live venue of this club is 422. A replayed `POST` with a known `id` returns **200** with the
  stored row and does not regenerate; an `id` that belongs to another club is 409 `conflict`.
- **Session PATCH detaches only when needed (deviation from "Sets isDetached = true"):** `isDetached` becomes true when
  `title`, `startTime`, `durationMin` or `venueId` actually change on a series occurrence. Editing only `notes` or
  `coordinatorMemberId` leaves it attached, because the generator never overwrites those anyway. `cancel` and `restore`
  always detach. `groupMode` is not editable per occurrence. `localDate` on a series occurrence that differs from its
  date is 422 (sending the same date is fine). `coordinatorMemberId` must be a member of this club (else 422).
- **`original`** is `null` when the session is attached, has no series, or is detached but still equals the series
  (for example a cancelled run at its normal time). It is only filled when a detached session differs from the series
  in start time, venue or title.
- **Deletes:** `DELETE` on venues, series and sessions returns 204 for an already-deleted row (safe to replay), and 404
  `not_found` for an id that never existed in this club. Deleting a series soft-deletes it and its future non-detached
  sessions at once; its detached and past sessions stay.
- **`GET sessions`** orders by `localDate`, `localStartTime` without `since`, and by `updatedAt` with it. `from`/`to`
  must be `YYYY-MM-DD` (else 422). Instants (`startsAt`/`endsAt`) have no milliseconds (`2026-10-12T18:00:00Z`); the
  row timestamps (`updatedAt`, `deletedAt`) keep milliseconds as in Phase 2.
- **Ad-hoc runs** are created with `isDetached: false`. Cancelling/restoring one just sets `status`; no notification is
  sent (not in the contract).

## Phase 4: groups, leaders, attendance, preferences

All routes are under `/app/clubs/{clubId}` with `club:required`. Reads need a
linked membership; writes follow the permission rules per endpoint. Errors use
the earlier shapes. New error codes: `forbidden` (403), `not_found` (404),
`session_cancelled` and `session_past` (409), `validation_failed` (422).

### Group shape (embedded in sessions, returned by group writes)
```json
{ "id": "uuid", "sessionId": "uuid", "kind": "run",
  "label": "Jog/walk|null", "description": "…|null",
  "paceUnit": "mi|km|null", "paceFromS": 570, "paceToS": 600,
  "paceFromSPerKm": 354, "paceToSPerKm": 373,
  "distanceValue": 3.0, "distanceUnit": "mi", "distanceM": 4828,
  "status": "active|needs_leader", "sortOrder": 0,
  "leaders": [ { "memberId": "uuid", "displayName": "Jo Bloggs", "role": "leader|co_leader|backmarker" } ],
  "goingCount": 5, "maybeCount": 1,
  "updatedAt": "…", "deletedAt": "…|null" }
```
- `paceFromS` is the faster end. `paceToS` is null for a single pace, and both are
  null for no pace. `paceFromSPerKm`, `paceToSPerKm` and `distanceM` are derived,
  read-only and used for sorting and matching.
- `leaders` lists only `confirmed` leaders.
- `kind` is one of `run | jog_walk | efforts | route | social | other`.

### Session payload additions (Phase 3 sessions endpoint)
`GET …/sessions` items now also carry:
```json
{ "groups": [ Group… ],
  "summary": { "groupCount": 3, "leaderCount": 4, "goingCount": 12, "maybeCount": 2,
               "myStatus": "going|maybe|not_going|null", "myGroupId": "uuid|null",
               "myLeading": false } }
```
Any change to a session's groups, leaders or attendance bumps that session's
`updatedAt`, so the existing `?since=` sync delivers it. `groups` excludes deleted
groups. `summary` is computed for the caller.

### Groups
- `POST …/sessions/{sessionId}/groups` → 201 with the Group. Body:
  `{ id?, kind?, label?, description?, paceUnit?, paceFromS?, paceToS?, distanceValue?, distanceUnit?, lead? }`
  - **Any linked member** may create a group if `lead` is true (they become its
    leader). `lead: false` (leaderless) needs the committee, an admin or the
    session coordinator.
  - Idempotent on `id`.
  - A cancelled session returns 409 `session_cancelled`; one that has ended
    returns 409 `session_past`.
- `PATCH …/groups/{id}` edits any of those fields (the group's leaders, the
  coordinator or committee only). Fields sent as `null` are cleared.
- `DELETE …/groups/{id}` → 204 (leaders, coordinator, committee). Its attendees
  become unassigned (`groupId` null).
- `POST …/groups/{id}/leaders` with `{ "role": "leader|co_leader|backmarker" }`: the
  caller joins as a leader (any linked member). Returns the Group. A `needs_leader`
  group becomes `active`.
- `DELETE …/groups/{id}/leaders/me` → the Group. Marks the caller's leader row
  withdrawn. If that was the last confirmed leader and the session mode is `paced`
  or `single`, the group becomes `needs_leader`. Groups in `routes` and `open`
  sessions stay `active`.
- Validation:
  - `paceUnit` is required when a pace is given.
  - `paceFromS` and `paceToS` are 180-1800, `paceFromS <= paceToS`, and `paceToS`
    needs `paceFromS`.
  - `distanceValue` is 0.1-200 and needs `distanceUnit`.
  - `kind` must be in the list; `label` max 80; `description` max 1000.

### Attendance
- `PUT …/sessions/{sessionId}/attendance` → 200 with
  `{ "sessionId", "status", "groupId", "paceUnit", "paceFromS", "paceToS", "updatedAt" }`.
  Body: `{ status: "going|maybe|not_going", groupId?, paceUnit?, paceFromS?, paceToS? }`.
  - Upserts the caller's single row for the session. A `groupId` that doesn't
    belong to the session is 422. `not_going` clears `groupId`.
  - The pace override applies to this run only. Omitting it clears an earlier one.
  - 409 `session_cancelled` / `session_past`.
- `GET …/sessions/{sessionId}/attendance` → the caller's own row, or `null`.

### Session plan (online only; the app caches the last response)
`GET …/sessions/{sessionId}/plan` returns:
```json
{ "sessionId": "uuid",
  "groups": [ { "groupId": "uuid",
                "paces": [ { "fromSPerKm": 354, "toSPerKm": null } ],
                "attendees": [ { "memberId": "uuid", "displayName": "Sam Lapsed", "status": "going",
                                 "paceUnit": "mi", "paceFromS": 570, "paceToS": null } ] } ],
  "unassigned": { "goingCount": 4, "maybeCount": 1,
                  "paces": [ { "fromSPerKm": 330, "toSPerKm": 360 } ],
                  "members": [ { "memberId": "uuid", "displayName": "…", "status": "going",
                                  "paceUnit": "mi", "paceFromS": 540, "paceToS": 600 } ] } }
```
- `paces` is an **anonymous** list: the effective pace of each member who is going
  or maybe (their per-run override, otherwise their profile range). Members with
  no pace are left out. Every linked member gets this.
- `attendees` appears only for groups the caller leads, and for every group if
  the caller is committee, admin or the session coordinator. Otherwise the key is
  omitted.
- `unassigned.members` (names) appears only for committee, admin and the session
  coordinator. Otherwise the key is omitted.
- It is not synced by `since`; it's recomputed on every call.

### Preferences (the caller's own, per club)
- `GET …/preferences` returns
  `{ "paceUnit": "mi", "distanceUnit": "mi", "paceFromS": 540, "paceToS": 600, "updatedAt": "…" }`.
  Defaults when never saved: `mi` / `mi`, no range, `updatedAt` null.
- `PUT …/preferences` takes the same fields, all optional, and returns the saved
  preferences. `null` clears the range. `paceFromS` and `paceToS` are in `paceUnit`,
  180-1800, with `paceFromS <= paceToS`. Changing `paceUnit` without sending a range
  clears any stored range, so the app should resend one.

### Members and roles (committee tools)
- `GET …/members?q=&limit=` (committee or admin) returns
  `{ "items": [ { "memberId", "displayName", "status", "roles": ["leader"] } ] }`,
  searchable by name, ordered by name, 50 per page. It feeds the coordinator picker
  and the roles screen.
- `PATCH …/members/{memberId}/roles` with `{ "roles": ["leader"] }` replaces the
  set. Committee or admin can grant or remove `leader`. Only an admin can grant or
  remove `committee` or `admin`. Unknown roles are 422 and insufficient rights are
  403 `forbidden`. Returns the member item.
- The Phase 3 session PATCH accepts `coordinatorMemberId`, chosen with this picker.

### Implementation notes (Phase 4)

- **Tables** are `session_groups`, `session_group_leaders`, `session_attendees`, `member_preferences`
  (`2026_10_09_09xx` migrations). The manual SQL is `api/database/manual/2026_10_groups_tables.sql`, run after
  `2026_10_app_tables.sql` and `2026_10_runs_tables.sql`. Eloquent models: `SessionGroup`, `SessionGroupLeader`,
  `SessionAttendee`, `MemberPreference`.
- **Routes:** group edits are not nested under the session: `POST …/sessions/{sessionId}/groups`, then
  `PATCH|DELETE …/groups/{id}`, `POST …/groups/{id}/leaders`, `DELETE …/groups/{id}/leaders/me`.
- **Check order:** 404, then 403 (permission), then 422 (validation), then 409 (`session_cancelled` / `session_past`).
  Exceptions: group `POST` validates first, and a replayed `id` returns the stored group (200) before any permission or
  409 check; group `PATCH` validates after the permission check. Every group write (create, patch, delete, join,
  withdraw) and attendance `PUT` returns 409 for a cancelled or finished run. A run is past once `endsAt` is before now.
- **`lead` defaults to false** when omitted, so a plain member who forgets it gets 403. A replayed `POST` with a known
  group `id` returns 200 with the stored group; an `id` that belongs to another session or club is 409 `conflict`.
- **Leaderless groups start as `needs_leader`** when the run is `paced` or `single` (a group nobody leads needs one), and
  `active` in `routes` and `open` runs. Joining as leader (or creating with `lead: true`) makes it `active`.
- **PATCH validates the merged result**, so sending `paceFromS` alone is checked against the stored `paceToS`.
  Clearing a pace takes explicit nulls for `paceFromS` and `paceToS` (and `paceUnit` if wanted). `kind: null` resets to `run`.
  `sortOrder` is assigned on create (0, 1, 2…) and is not editable.
- **Joining** again after withdrawing re-confirms the same leader row and updates its role. Joining twice just updates the
  role. Withdrawing when you are not a confirmed leader is a no-op that returns the group (safe to replay). Group `DELETE`
  of an already-deleted group is 204; an unknown id is 404.
- **Embedded groups** exclude deleted groups and list confirmed leaders only (oldest first). `summary.leaderCount` counts
  distinct confirmed leader members across live groups. `goingCount` / `maybeCount` in the summary cover the whole run,
  including people with no group. Session write endpoints (create, edit, cancel, restore) now return the same `groups` and
  `summary`. Sessions deleted by the committee (ad-hoc runs) keep their group rows untouched, but nothing lists them.
- **Attendance `PUT`:** `status` is required. `not_going` clears `groupId` (any pace override sent is still stored).
  `GET …/attendance` returns the JSON literal `null` (not `{}`) when the caller has no row, and works on past runs.
  The row is written with the caller-supplied values only, so omitting the pace fields clears an earlier override.
- **Plan:** `paces` are sorted by `fromSPerKm`, then `toSPerKm`. People in a deleted group, or with no group, are counted in
  `unassigned`. `attendees` and `unassigned.members` hold the effective pace (override, else profile range) in its
  original unit, sorted by name. `not_going` members never appear. Plan works for cancelled and past runs.
- **Preferences:** the first `PUT` creates the row (one per member and club). Clearing `paceFromS` alone clears the whole
  range. A `paceUnit` change with neither range field sent clears the range; re-sending the same unit does not. A
  `null` `paceUnit` or `distanceUnit` is 422.
- **Members list:** `GET …/members` returns every non-deleted member of the club (any `status`), ordered by name then id,
  `limit` 1-50 (default 50), no paging cursor yet. `q` is a substring match on the display name (`%` and `_` are literal).
- **Roles:** `roles` is required (an empty array removes every role) and may only contain `leader`, `committee`, `admin`.
  The caller must be committee or admin (403 otherwise, checked before the 404 for an unknown member). Any change to the
  `committee` or `admin` entries, in either direction, needs an admin, so a committee member can keep `committee` on
  someone while editing `leader`. Roles come back in the order leader, committee, admin. An admin can remove their own
  admin role, so keep a second admin.
- **Generator safety:** a future series occurrence that no longer matches its series (weekday changed, `validUntil` moved,
  series deleted) is soft-deleted only if it has no live group and no `going` / `maybe` attendance. Otherwise it is
  marked `isDetached = true` and left in place, so a series edit never wipes leaders or sign-ups. It then behaves like
  any detached run (the committee can cancel it). Runs with only `not_going` rows or deleted groups are still removed.
- **Queries:** a page of sessions loads groups, leaders, member names and attendee rows with a fixed number of
  queries (no per-session lookups).
- **Canonical values** round half away from zero: 570 s/mi (9:30/mi) is 354 s/km, 600 s/mi is 373 s/km, and 3 mi is 4828 m.
  `distanceValue` is rounded to 2 decimals and may be serialised as `3` rather than `3.0`.

### Update (2026-10-09): leaders attend their own group
- Creating a group with `lead: true`, and joining a group as a leader, now also
  marks the caller as **going** in that group (their attendance row is created or
  updated: status `going`, `groupId` = the group, any per-run pace is kept).
  The group's `goingCount` therefore includes its leaders, and `summary.myStatus`
  and `summary.myGroupId` reflect it.
- Withdrawing as a leader does **not** change attendance: they stay going in the
  group until they leave it or say they can't come.
- Leaderless groups (committee/coordinator, `lead: false`) don't attend anyone.
- Apps should therefore not offer "Join this group" or "Leave group" for a group
  you lead; the leader controls ("Step down") cover it.

## Phase 5: smarter notifications

Decisions: D31-D37 in [decisions.md](decisions.md). Nothing here changes an existing response shape
except where stated; every new notification is an ordinary inbox row (`category`, `title`, `body`,
`data.route`) plus an optional push, written through `NotificationService`.

### Schema (one manual SQL file, `api/database/manual/2026_10_notifications_v2.sql`)
- `notifications`: add `dedupe_key varchar(80) null`, `push_requested_at timestamp null`, index
  `(member_id, dedupe_key)`.
- `member_series_prefs`: `id uuid pk, club_id, member_id, series_id, reminders varchar(4)` (`on`|`off`),
  timestamps, unique `(member_id, series_id)`. No row = `auto`.
- `member_preferences`: add `push_daily_cap smallint unsigned null` (null = the default, 6; 0 = no limit).

### NotificationService changes (backwards compatible)
`notifyMembers(..., bool $force = false, array $options = [])`. Options:
- `dedupeKey` (string, max 80): the same key means the same news for the same member.
  - A row with the same member + key and identical title and body: nothing happens at all.
  - Otherwise `onDuplicate: 'skip'` (default) leaves the existing row alone and sends nothing;
    `'replace'` updates the row in place (new title/body/data, `read_at` cleared, `updated_at` bumped, so
    the app's `since` fetch re-sends it) and pushes again only if the last push for that key is older than
    `repush` minutes (option, default 0 for locked/forced categories, 60 otherwise).
- Daily cap: a push-eligible, non-locked, non-forced notification is **not pushed** when the member already
  has `dailyCap` rows with `push_requested_at` in the last 24 hours (rolling). The inbox row is still
  written. `push_requested_at` is set when a push is queued. Locked categories and `force` ignore the cap
  and do not count towards it.
- `data` may carry `sessionId`, `groupId`, `actions` (e.g. `["going","not_going"]`) and `actionToken`
  (random 32 hex, only for notifications with `actions`). `actionToken` is never returned by the inbox
  endpoint; it only travels in the push.

### Notification settings
- `GET /app/clubs/{clubId}/notification-settings`:
  ```json
  { "dailyPushCap": 6, "defaultDailyPushCap": 6,
    "series": [ { "seriesId": "uuid", "title": "Tuesday run", "weekday": 2,
                  "localStartTime": "19:00", "reminders": "auto|on|off" } ] }
  ```
  `dailyPushCap` is the effective value (0 = no limit). `series` are the club's live series ordered by
  weekday then time.
- `PUT` the same path with any of `{ "dailyPushCap": 0..50, "series": { "<seriesId>": "auto|on|off" } }`;
  returns the GET shape. 422 `validation_failed` for a bad cap, a bad value or a series id that is not a
  live series of this club (nothing is saved). `auto` deletes the row.

### Responding from a notification (no sign-in)
`POST /app/notification-actions` (outside the `auth` group) with
`{ "notificationId": "uuid", "token": "…", "action": "going|not_going" }`:
- Finds the notification, checks `hash_equals(token, data.actionToken)` and that `action` is in
  `data.actions`. Anything wrong: 404 `not_found` (never says which part).
- Writes the member's attendance for `data.sessionId` exactly like `PUT …/attendance` (`going` keeps the
  group they already chose; `not_going` clears the group, as that endpoint does), marks the notification
  read, and returns 200 `{ "status": "going|not_going", "sessionId": "uuid" }`. Replays are fine.
- A cancelled or finished run: 409 `session_closed`.
- Rate-limited loosely (30/min per IP) because it is unauthenticated.

### Push payload for notifications with `actions`
Unless `.env` has `FCM_ACTION_BUTTONS=false`, these go as **data-only** messages (Android can't show
buttons on a `notification` message), with `android.priority = high`: `data` = the normal keys plus
`title`, `body`, `sessionId`, `actions` (comma list), `actionToken`, `tag` (the dedupe key). The `apns`
block still carries `aps.alert` (title/body) and `category: "BPJ_RUN_REMINDER"`. With the flag off they
are ordinary `notification` messages (no buttons; tapping opens the run).

### What sends what
All audiences are **active** members of the club. "Pace fits" means the member's pace (their per-run
override if they answered, else the usual range in `member_preferences`) overlaps the group's pace band,
using the shared tolerance of 15 s/km on single paces. Members with no pace never match. Pace text in
messages uses the recipient's units.

| Trigger | Who | Category | Key (onDuplicate) | Route |
|---|---|---|---|---|
| Morning-of reminder | see below | `run_reminders` (with actions) | `reminder:<sessionId>` (skip) | `/runs/<sessionId>` |
| Group added/paced for a run | pace fits, not `not_going`, not in this group, not already in a group that fits | `group_matches` | `group_match:<sessionId>` (skip) | `/runs/<sessionId>` |
| Last leader withdraws (group → `needs_leader`) | the group's attendees (not the leader) | `my_group_changes` (locked) | `leader_withdrawn:<groupId>` (replace) | `/runs/<sessionId>` |
| Same | `leader`-role members not leading in that run, not `not_going`, pace fits (or no pace set), not already told above | `leaders_needed` | `leaders_needed_group:<groupId>` (skip) | `/runs/<sessionId>` |
| Group with attendees deleted | its attendees | `my_group_changes` | `group_removed:<groupId>` (replace) | `/runs/<sessionId>` |
| Run cancelled / restored / time or venue changed (session endpoints and the generator) | going or maybe attendees, confirmed leaders, coordinator | `my_group_changes` | `session_change:<sessionId>` (replace) | `/runs/<sessionId>` |
| Leaders needed, ≤ 3 days out | `leader`-role members not leading in that run, not `not_going` | `leaders_needed` | `leaders_needed_run:<sessionId>` (skip) | `/runs/<sessionId>` |

**Reminder audience:** a member gets the reminder when they are not `not_going`, the run is scheduled, and
either they are `going`/`maybe` on it, or the series rule says so: for a run in a series the member's
`member_series_prefs` row (`on` always, `off` never), else `auto` = they were `going` at one of the last 6
ended runs of that series. Runs with no series only remind people who are going. Members who lead a
group on the run get a reminder without `actions` ("You're leading …").
**Reminder time (club-local):** runs starting 11:00 or later: from 08:00 on the day; earlier runs: from
18:00 the evening before. The command runs every 10 minutes and sends once the time has passed and the
run hasn't started. Body: going → "You're down for the {group}. Can't make it?"; unanswered → "Are you
coming?". Actions: `going`, `not_going`.
**Group match delay:** the job is queued with a 3 minute delay and re-checks everything when it runs (group
still exists, still has a pace, run still upcoming), so leaders can fix a typo first.
**Leaders needed ≤ 3 days out:** evaluated by the same 10-minute command, only after 09:00 club-local, for
scheduled, non-`routes` runs starting within 72 hours that have either a `needs_leader` group, or going
members whose pace no *led* group covers (the D28 rule, on the server), or no led group but some going
member. One message per member per run.

### Commands
- `app:send-reminders` — reminders + leaders-needed alerts (scheduler: every 10 minutes).
- `app:send-test-push {clubId} {athleteId} [--actions]` — writes a test inbox row for that member
  (category `club_updates`, or `run_reminders` with actions when `--actions` and a session id is given
  via `--session=`), prints how many devices they have and whether FCM is configured, and
  runs the push synchronously so the first real FCM send can be checked from the host console.

### App behaviour for Phase 5
- The Notification settings screen gains a "Daily push limit" choice (3 / 6 / 12 / No limit) and a
  "Run reminders" list, one row per series, `Automatic / Always / Never`.
- A data-only message with `actions` is turned into a local notification by the app (foreground and
  background isolate) with "I'm coming" / "Not coming" buttons. A tap on a button calls
  `POST /app/notification-actions` straight from the background isolate (plain HTTP, no Auth0), then
  replaces the notification with "Thanks, you're down as coming" (or "Couldn't send, open the app" when
  offline). Tapping the notification body opens `data.route` as before.

### Implementation notes (Phase 5a)
- `notifyMembers` returns the rows it created or replaced; a member whose duplicate was skipped or identical
  has no entry.
- `push_requested_at` is set only for pushes that count towards the daily cap (not locked, not forced). The
  re-push window uses the later of `push_requested_at` and `pushed_at`. A replaced row that is pushed again
  gets `pushed_at` cleared so the job sends it.
- `dedupeKey` is cut to 80 characters. The cap setting is stored as given (choosing 6 stores 6, not null).
- Settings: `series` lists every non-deleted series of the club. A 422 for a bad series id names it as
  `errors["series.<id>"]`. Pace preferences are untouched by a settings write.
- Notification actions: a missing or malformed field is 422 `validation_failed` (the 404 rule is only for a
  well-formed request that doesn't match). A deleted or other-club run is 404. `going` keeps the group only
  while that group still exists; both answers keep the per-run pace. The notification is marked read and its
  `updated_at` bumped. The 30/min limit is a fixed window per IP in the default cache store; over it: 429
  `{ "error": "too_many_requests" }` with `Retry-After`.
- Data-only push: `tag` is the dedupe key (empty string when none); there is no `android.notification`
  block, so the Android channel comes from `data.category`.
- `app:send-test-push` writes the row with `force`, so it ignores category settings and the cap. It exits 1
  when `pushed_at` stayed unset. The service also queues the normal job; that job skips rows already pushed.
### Implementation notes (Phase 5b)
- **Where:** `Services/PaceMatcher` (band maths and pace text), `RunNotifier` (request-driven triggers),
  `RunReminderService` (time-driven, "now" injectable), `RunText` (day/time/group wording), `Jobs/NotifyMatchingGroupJob`,
  `Console/Commands/SendReminders` (`app:send-reminders`, `everyTenMinutes()->withoutOverlapping(9)`). No schema changes.
- **Safe to call:** every `RunNotifier` trigger catches `Throwable` and logs a warning, so a notification problem
  never fails the request (or the generator). The job's `matchGroup()` is not guarded; a failure there fails the job only.
- **The actor is never notified**, including for run changes where they are the coordinator or committee member
  who made the change. The generator has no actor.
- **Run changes** notify only for a scheduled-or-cancelling run that has not ended. Endpoints notify only on a real change:
  cancel/restore when the status flips; `PATCH` when `startsAt` or the venue differs (title, notes, duration and
  coordinator edits are silent). The generator notifies for an existing, attached, not-ended run whose start or venue
  changed; new, restored and detached runs say nothing. Text: `Run cancelled: Monday 12 Oct` (reason appended),
  `Run back on: …`, `Run moved: now 19:30 at Riverside` (date included only if the day changed, "Was …" in the body).
  Bodies are cut to 140 characters.
- **Group match:** pace fits and not `not_going`, not in this group, not in a live group that fits their pace, not
  a confirmed leader of this group, not the actor. Members with no pace never match; everyone in the club is
  considered, not only people who answered. Queued 3 minutes (`->delay(180)`) on `notifications` from group create (pace
  given; a replayed id queues nothing) and from `PATCH` when `paceUnit/FromS/ToS` change to a pace. The job carries the
  actor id. Any group mode qualifies.
- **Leader withdraws:** fires only when the group actually flips to `needs_leader`. Attendees = going/maybe rows with
  that `group_id`. Leader-role candidates: active, not leading in the run, not `not_going`, and either no pace on either
  side or overlapping; also not already told as an attendee.
- **Group removed** tells going/maybe attendees as of the moment before the delete turned them unassigned.
- **Reminders:** every scheduled run starting in the next 72 h is considered. Due time is club-local 08:00 that day for
  starts at 11:00 or later, else 18:00 the evening before; a run created after its due time is reminded straight away
  while it hasn't started. Title `Today at 19:00: <run title>` or `Tomorrow at …`. `maybe` gets "You said maybe. Are
  you coming?" (contract only wrote going/unanswered). Leaders get `You're leading <group> and <group>.` with no
  `actions` or token, even without an attendance row. Each member gets their own `actionToken`, so reminders are written
  one `notifyMembers` call per member. `off` never removes someone who answered going/maybe; it only stops the series rule.
  The `auto` rule counts `going` at the last 6 ended, non-cancelled runs of the same series (this run and future ones excluded).
  Members who already hold `reminder:<sessionId>` are skipped before any call, so tokens never change on re-runs.
- **Leaders needed (run level):** needs `now` >= 09:00 club-local and a non-`routes`, scheduled run starting within 72 h
  (inclusive). Triggers: a `needs_leader` group; a `going` member with a pace that no led pace-group overlaps (their per-run
  pace beats their usual range); or going members with no led group at all. `maybe` members don't count. Recipients:
  `leader`-role, active, not leading, not `not_going`, no pace filter, and nobody already asked via
  `leaders_needed_group:<groupId>` for a group of that run (so "one per member per run" holds across both rules).
- **Messages per recipient unit:** pace text uses the recipient's `member_preferences.pace_unit` (default `mi`), so
  withdraw / group-match / reminder messages are sent in one `notifyMembers` call per unit.

## Phase 6: group messaging

Decisions: D39-D44 in [decisions.md](decisions.md). One chat thread per `session_group` (so per run, per
pace group). All routes are under `/app/clubs/{clubId}` with `club:required`; errors use the earlier
shapes. New error codes: `not_in_group` (403), `thread_closed` (409), `too_many_requests` (429).

### Who is in a thread
A member **may read and post** when any of these is true (computed live, nothing is stored):
- they are a confirmed leader of the group;
- their attendance on the run is `going` or `maybe` with `groupId` = this group;
- they are the run's coordinator;
- they hold `committee` or `admin` (read, post and moderate; they are not notified unless also one of the above).

Anyone else gets 403 `not_in_group`. A member who leaves the group or says "not coming" loses access
immediately (the app hides the thread).
**Posting closes** 12 hours after the run ends, and while the run is cancelled: 409 `thread_closed`
(`message` says why). Reading stays open while the group exists. Deleting a group deletes its thread.

### Message shape
```json
{ "id": "uuid", "groupId": "uuid", "memberId": "uuid",
  "authorName": "Sam B.", "authorRole": "leader|coordinator|committee|member",
  "body": "…", "createdAt": "2026-10-12T17:30:00.000Z", "deletedAt": "…|null" }
```
`authorName` is first name + surname initial (`Sam B.`), taken from the athlete record, or `Member` if
unknown. `authorRole` is the author's role **in this thread** (leader of this group beats coordinator beats
committee/admin beats member). A deleted message is a tombstone: `body` is `""` and `deletedAt` is set.

### Endpoints
- `GET /groups/{groupId}/messages?since=` → `{ "items": [Message], "serverTime": "…" }`.
  Without `since`: the newest 100 not deleted, oldest first. With `since`: every message (including
  tombstones) with `updated_at >= since`, oldest first, up to 500 (same `since`/`serverTime` rules as Phase 2).
  Also reports `"closed": true|false` and `"muted": true|false` for the caller.
- `POST /groups/{groupId}/messages` `{ "id"?: "uuid", "body": "…" }` → 201 with the message (200 with the stored
  one on a replay of the same `id` by the same member; another member's id is 409 `conflict`).
  `body` is trimmed, required, 1-1000 characters (422 otherwise). Max 20 messages per member per minute
  (429 `too_many_requests`). Triggers notifications (below).
- `DELETE /groups/{groupId}/messages/{id}` → 204 (also when already deleted). Allowed for the author, the
  group's confirmed leaders, the coordinator and committee/admin; anyone else 403 `forbidden`. Soft delete,
  bumps `updated_at` so `since` fetches deliver the tombstone.
- `POST /groups/{groupId}/messages/read` → 204. Marks the thread read for the caller up to now.
- `PUT /groups/{groupId}/thread` `{ "muted": true|false }` → `{ "muted": …, "unreadCount": n }`. Muting stops
  notifications for the thread (no inbox row, no push); the messages still arrive when the thread is open.
- `GET /threads` → `{ "items": [ { "groupId", "sessionId", "label": "9:00-9:30/mi|…", "sessionTitle",
  "localDate", "localStartTime", "lastMessage": { "authorName", "body", "createdAt" }, "unreadCount": 2,
  "muted": false, "closed": false } ], "serverTime": "…" }`: the caller's threads that have at least one message
  from the last 14 days, newest message first. `label` is the group's pace/label text in the caller's units
  (same text the group card uses; fall back to the group's label or "Group"). `unreadCount` counts messages
  by other people after the caller's last read (deleted ones excluded).
- All of the above need the caller to be a participant (else 403 `not_in_group`), group in this club and not
  deleted (else 404 `not_found`). `GET /threads` just lists the ones the caller is in.

### Notifications for a new message
Category `group_messages`, to every participant except the author and except members who muted the thread:
confirmed leaders, going/maybe attendees of the group, the coordinator. Title = `authorName` + " · " + group
label text (the recipient's units, e.g. "Sam B. · 9:00-9:30/mi"), body = the message clipped to 140 characters,
`data.route = /runs/<sessionId>/groups/<groupId>/chat`, `data.sessionId`, `data.groupId`.
Dedupe key `group_msg:<groupId>`, `onDuplicate: replace`, `repush` 5 minutes: a burst of messages is one inbox
row (the latest) and at most one push per 5 minutes. Daily cap applies (not locked).

### Schema (one manual SQL file, `api/database/manual/2026_10_messages_tables.sql`)
- `group_messages`: `id uuid pk, club_id, group_id, member_id, body text`, timestamps, `deleted_at`; foreign keys
  to clubs, session_groups, club_members; index `(group_id, updated_at)`.
- `group_thread_states`: `id uuid pk, club_id, group_id, member_id, last_read_at timestamp null, muted boolean
  default 0`, timestamps; unique `(group_id, member_id)`.
Follow the hosting constraints in `api/CLAUDE.md` (InnoDB, short indexed varchars, no defaults on TEXT/JSON).

### App behaviour for Phase 6
- **Chat screen** at `/runs/:sessionId/groups/:groupId/chat`: bubbles (own on the right), author name and a small
  role badge (Leader / Coordinator / Committee), date separators, input bar with a 1000-character limit,
  mute switch and a "Chat closed" banner when `closed`. Long-press deletes (own message, or any for
  leaders/coordinator/committee), shown as "Message deleted".
- **Offline-first:** messages are cached in Drift. A sent message appears immediately as *sending*, is stored with
  its client-generated id and retried until the server accepts it (like attendance, D23); a permanent failure
  (403/409/422) marks it *failed* with a "Tap to retry / delete" action. While the screen is open the app
  polls `?since=` every 8 seconds, and refreshes at once when a push for that group arrives. The thread is marked
  read when opened and while new messages arrive in view.
- **Entry points:** a "Group chat" button on a group card when the viewer is a participant (leader, coordinator,
  or in the group), with an unread dot from `GET /threads`; and a "Group chats" section at the top of the
  Inbox tab listing `GET /threads` (label, run date, last message, unread count).
- While the chat for a group is open, a foreground push for the same group is not shown as a notification.

### Implementation notes (Phase 6a)
- **Where:** `AppGroupMessageController`, `Services/ThreadAccess` (participants, moderators, closed, author role, short names), `Services/GroupMessageNotifier`, models `GroupMessage` (soft deletes) and `GroupThreadState`, migrations `2026_10_12_09*`. No deviations from the contract.
- **Check order:** 404 (group missing, other club, group or run deleted), 403 `not_in_group`, 422, replay/409 `conflict`, 409 `thread_closed`, 429. A replay of your own id is 200 even after the thread closed.
- **DELETE** also needs thread access, so a member who left the group gets `not_in_group` even for their own message. A participant who may not moderate gets 403 `forbidden`. Deleting works on closed threads. Repeating it keeps the first `deleted_at`.
- **Rate limit:** counted from `group_messages.created_at` over the last 60 s across all groups, deleted messages included, replays excluded. 429 carries `Retry-After`.
- **GET messages:** `since` mode orders by `created_at` (not `updated_at`), so a tombstone keeps its place; the 500 cap cuts the newest. `closed` uses `ends_at` (else `starts_at`) + 12 h, or a cancelled run.
- **Thread read state:** `last_read_at` is "now" at second precision and unread means `created_at > last_read_at`, so a message in the same second as a read counts as read. Muting keeps `last_read_at`.
- **`label`** (threads and notification title) is `RunText::groupName`: the group's label and pace text together ("Jog/walk 9:00-9:30/mi"), either alone, or "Group".
- **`GET /threads`:** window is 14 days by message `created_at`; deleted messages never count as the last message or towards a thread being listed. Committee/admin see every thread of the club; the coordinator sees those of their runs; everyone else sees groups they lead or are going/maybe in.
- **Notifications:** one `notifyMembers` call per recipient pace unit; active members only; muted members are removed before the call, so they get no row. The notifier is guarded (a failure is logged and the POST still returns 201).

## Update (2026-10-13): optional run length, series images, group label rule, pick-a-group nudge

Decisions D47-D51. Applies on top of Phases 3-5; shapes not mentioned are unchanged.

- **Optional duration.** `session_series.duration_min` and the session `durationMin` input are optional.
  - Series `POST`/`PATCH` and ad-hoc session `POST`: `durationMin` may be omitted or `null` (no end time);
    when given it is still 15-600. Session `PATCH` with `durationMin: null` clears the end time; omitting the
    key leaves it alone. A series `durationMin` of `null` is returned as `null`.
  - A session without an end time returns `endsAt: null` and `localEndTime: null`. The series payload
    returns `durationMin: null`.
  - Internally such a run is treated as lasting **3 hours** for every "has it ended" rule (past, chat closing,
    reminders): `sessions.ends_at` is still filled (start + 3 h) and a new column `sessions.has_end`
    (boolean, default true) says whether to expose it.
- **Series image.** `session_series.image_url` (nullable, ≤ 500 chars, `http(s)://` only, else 422
  `imageUrl`). Series `POST`/`PATCH` accept `imageUrl` (`null` clears) and the series payload returns it. The
  session payload gains `imageUrl` (the series' image, `null` for ad-hoc runs). `GET sessions?since=` also
  returns sessions whose **series** changed since then (`series.updated_at >= since`), so editing the image
  reaches phones. When editing the column straight in the database, also set `updated_at = NOW()`.
- **Group label rule.** A group with no pace (`paceFromS` null once the change is applied) must have a
  non-empty `label` (≤ 80): 422 `validation_failed` on `label`. Applies to group create and `PATCH` (checked
  against the resulting values). Groups with a pace may still have no label.
- **Pick-a-group nudge.** `app:send-reminders` also sends, to members who are `going` on a run, are not in a
  group, and not leading one, when the run has at least one active group: category `run_reminders`, key
  `pick_group:<sessionId>` (skip), title "Pick your pace group", body "Tonight's run has {n} pace group(s). Tap
  to choose yours" (use "Tomorrow"/the weekday as the existing reminders do), route `/runs/<sessionId>`, no
  actions. Time: 3 hours before the start but not before 08:00 club-local, and only while the run has not
  started. Also, when `NotifyMatchingGroupJob` handles a new group and it is already past that time, going
  members with no group **and no usual pace** get the same message (key `pick_group:<sessionId>`, so never
  twice). If no groups exist there is nothing to pick, so nothing is sent.
- **12-hour times.** JSON stays 24-hour `HH:MM`. Everything the server writes for people (notification
  titles/bodies, `RunText`) and everything the app shows uses `h[:mm]am|pm`: no leading zero, minutes dropped
  on the hour (`7pm`, `7:30pm`, `12pm` = noon, `12am` = midnight). Ranges drop the first suffix when both
  ends share it: `7-8:30pm`, but `11am-1pm`. A run with no end time shows just the start.

### Implementation notes (2026-10-13 tweaks)

- **Schema:** migrations `2026_10_13_090000..090200`; manual SQL `api/database/manual/2026_10_runs_v2.sql` (run once after `2026_10_messages_tables.sql`). `sessions.local_end_time` and `ends_at` stay filled for a no-end run (start + 3 h, `SessionGenerator::NO_END_MINUTES`); `has_end=false` only hides them in the session payload.
- **Duration:** Non-integers are 422; `null` or omitted is "no end". Session `PATCH` with the key omitted keeps the current length (or stays no-end). Clearing or adding an end on a series occurrence detaches it, like any other length change. `original` still lists only start time, venue and title.
- **Image URL:** the `^https?://` check is case-sensitive; an empty string is stored as `null`. `GET sessions?since=` adds `OR series_id IN (this club's non-deleted series with updated_at >= since)` in one WHERE (no duplicates); order stays by the run's own `updated_at`, `id`. A soft-deleted series does not re-send its runs.
- **Label rule:** checked after the pace and distance checks, against the resulting values; a label of only spaces counts as empty. An old unlabelled, paceless group has to be given a label on its next edit (any `PATCH`, even of `description`). A replayed create of such a group (same id) also gets 422.
- **12-hour text:** one formatter, `RunText::clock('19:30')` -> `7:30pm`, `RunText::range('19:00','20:30')` -> `7-8:30pm`, `RunText::range('19:00', null)` -> `7pm`; `RunText::time(Carbon, tz)` uses it, so reminders, changes, group-match and leaders-needed text all follow. Server text still prints only start times (no ranges yet).
- **Pick-a-group nudge:** "active group" means `session_groups.status = active` and not deleted (a `needs_leader` group does not count). `n` in the body is that count. The nudge time is start - 3 h, moved up to 08:00 club-local when that falls earlier in the morning; a run starting before 08:00 is never nudged. Body opens with "Tonight's" (start 17:00 or later, today), "Today's", "Tomorrow's" or the weekday. The timed nudge goes to every going member with no group who leads none (usual pace or not); the group-added path (`NotifyMatchingGroupJob` -> `RunNotifier::matchGroup`) only to those with no pace at all (neither on the run nor in preferences) and never to the member who created the group. Both share key `pick_group:<sessionId>`. A new group of any kind now queues the delayed job (before, only groups with a pace did); the job still sends no `group_matches` for a paceless group. `app:send-reminders` prints a third count.

## Phase 6.5: member profile card (photo, bio, goals)

Decisions D59-D63 in [decisions.md](decisions.md). All routes are under `/app/clubs/{clubId}` with
`club:required`, except the signed photo download. Errors use the earlier shapes.

### Schema (one manual SQL file, `api/database/manual/2026_10_member_profiles.sql`)
- `member_profiles`: `id uuid pk, club_id int unsigned, member_id char(36) unique, bio varchar(300) null,
  goals text null, goals_visible boolean default 0, photo_version char(8) null, photo_updated_at timestamp null`,
  timestamps; foreign keys to clubs and club_members.
- `member_photos`: `member_id char(36) pk, club_id int unsigned, image mediumblob, timestamps`; foreign keys
  to clubs and club_members. The blob lives in its own table so ordinary profile reads never load it.
Follow the hosting constraints in `api/CLAUDE.md`.

### My card
- `GET /member-profile` → `{ "bio": "…|null", "goals": "…|null", "goalsVisible": false,
  "photoPath": "/app/clubs/1/members/<memberId>/photo?v=ab12cd34&sig=…|null", "updatedAt": "…" }`.
  A member who has never saved anything gets the same shape with nulls and `goalsVisible: false` (no row is
  created by a read).
- `PUT /member-profile` `{ "bio"?: string|null, "goals"?: string|null, "goalsVisible"?: bool }` (omitted keys are
  left alone; `null` or empty after trim clears a text field). `bio` ≤ 300 characters, `goals` ≤ 1000, plain
  text, trimmed. 422 `validation_failed` otherwise. Returns the same shape.
- `PUT /member-profile/photo`: `multipart/form-data` with one file field `photo`. **JPEG only** (checked by
  magic bytes and `getimagesizefromstring`, not by the client's mime type), at most 400 KB, each side between
  64 and 1024 px (the app sends a 512 px square). Anything else: 422 `validation_failed` on `photo` (with a
  readable message: wrong type / too large / too small / too big). Replaces any existing photo, sets a new random
  `photo_version`. Returns the card shape. No server-side image library is needed (the app crops, resizes and
  re-encodes, which also strips location data).
- `DELETE /member-profile/photo` → returns the card shape (idempotent).

### Signed photo download (no auth header)
`GET /app/clubs/{clubId}/members/{memberId}/photo?v=<version>&sig=<hmac>` is registered **outside** the `auth`
group so image widgets can load it without a token. `sig` = hex `hash_hmac('sha256', "{clubId}|{memberId}|{v}",
APP_KEY)`; wrong or missing `sig`, a `v` that is not the member's current version, or no photo: 404. Success:
`200 image/jpeg`, `Cache-Control: private, max-age=31536000, immutable`. Only authenticated callers ever receive
a `photoPath`, and a new upload changes `v`, so old links die. Paths are relative; the app prepends the API
base URL.

### Other members
- `GET /members/{memberId}/profile` → 
  ```json
  { "memberId": "uuid", "displayName": "Sam B.", "roles": ["leader","committee"],
    "photoPath": "…|null", "bio": "…|null", "goals": "…|null", "isYou": false }
  ```
  `displayName` is first name + surname initial (same helper as chat). `roles` lists only `leader`, `committee`,
  `admin`. `goals` is returned only when that member has `goalsVisible`, or for the caller's own profile.
  404 `not_found` for a member who is not an **active** member of this club. Any linked member of the club may
  call it.
- `DELETE /members/{memberId}/profile` (committee/admin only, else 403 `forbidden`): clears that member's photo,
  bio and goals (moderation). 204. Idempotent.
- `GET /member-cards` → `{ "items": [ { "memberId", "displayName", "photoPath"|null, "roles": [...],
  "hasBio": bool } ], "serverTime": "…" }`: the **full** list (no `since`) of active members who are shown by
  name or choose to be: anyone with the `leader`, `committee` or `admin` role, anyone who is or was a confirmed
  leader of a group on a run in the last 90 days or the future, any run coordinator in that window, and anyone
  who has a photo or a bio. Used by the app to draw thumbnails and names without extra calls. Plain members
  with nothing set are not listed (the app falls back to initials and the name it already has).

### Privacy rules
- Photo and bio are visible to active members of the same club once set (the edit screen says so). Goals are
  private unless the member ticks "Share my goals with other members".
- No other personal data is exposed by these endpoints (no email, date of birth, URN, pace or attendance).
- Removing a photo deletes the blob. Account deletion (Phase 7) must delete `member_profiles` and
  `member_photos`.

### App behaviour for Phase 6.5
- **Avatar + name:** wherever a member is named (group card leaders, run page "Led by", coordinator, chat authors,
  who's-coming names visible to leaders) show a small circular thumbnail (initials when no photo) and the name;
  tapping the name opens `/members/:memberId` with the normal back button returning to where you were.
- **Profile page** (`/members/:memberId`, pushed on the current stack): large photo, name, role badges, bio, goals
  only when shared ("Goals" section), "This is how you appear to other members" note on your own. Committee/admin
  get "Remove photo and bio" in the overflow menu (confirm first).
- **My card** (Profile tab → "My profile card"): choose/take a photo (centre-cropped to a square, 512 px JPEG,
  quality 85, done on the phone), remove photo, bio (300 chars with counter), goals (1000 chars) with a
  "Share my goals with other members" checkbox (off by default), a "See how others see me" button, and consent
  text. Online-only writes; the last card is cached for offline viewing.
- **Cache:** member cards are fetched on start/resume and after saving; profile pages fall back to the last cached
  copy when offline.

### Implementation notes (Phase 6.5a)

No deviation from the contract above; these are the choices it left open.

- **Schema:** migrations `2026_10_14_090000` (`member_profiles`) and `2026_10_14_090100` (`member_photos`); manual SQL `api/database/manual/2026_10_member_profiles.sql` (run once after `2026_10_runs_v2.sql`). Laravel 10 has no `mediumBinary`, so the migration creates `blob` and, on MySQL only, widens it with `alter table ... modify image mediumblob not null` (SQLite's blob is unlimited). No `deleted_at` on either table (the contract lists timestamps only); a removed photo deletes its row.
- **Upload route:** `PUT member-profile/photo` as specified, plus `POST member-profile/photo` as an identical alias. PHP only fills `$_FILES` for POST, so for a multipart PUT the controller falls back to parsing the raw body by hand (field `photo`). Nothing else about the route differs; the app can use either.
- **Photo checks, in order:** file present (422 "Choose a photo to upload."), size over 400 KB (also an `UPLOAD_ERR_INI_SIZE` from PHP), `FF D8 FF` magic, `getimagesizefromstring` says JPEG, each side 64..1024. Every failure is 422 `validation_failed` with the message in `message` and `errors.photo[0]`. Only the header is inspected, so a header-valid but corrupt JPEG is stored as sent (the app re-encodes, and only linked club members can upload).
- **Signing:** `sig = hash_hmac('sha256', "{clubId}|{memberId}|{v}", APP_KEY)` with `APP_KEY` taken verbatim from env, including any `base64:` prefix (not decoded). With an empty `APP_KEY` no link is issued (`photoPath` null) and none is accepted. The signature is checked (`hash_equals`) before the database is touched; `v` and `sig` must be plain strings. Throttle is `ThrottleByIp` at `120,1`, keyed per IP and path, and counts bad links too.
- **Photo version:** `bin2hex(random_bytes(4))`, re-drawn if it equals the previous one. Upload, photo delete, committee clear and text saves all set `updated_at`; delete and clear touch it only when a profile row already exists (a read, or a delete with nothing stored, never creates a row).
- **My card:** `updatedAt` is `null` when no row exists. `PUT member-profile` always upserts the row, even with an empty body. Text is trimmed before the length check (characters, not bytes); `goalsVisible` must be a JSON boolean (`"true"`, `1`, `0`, `null` are 422).
- **Other member profile:** `goals` is always present and is `null` when hidden (so "private" and "none" look the same). Committee/admin do not see private goals. A caller whose own status is not active can still look (only the club link is checked, as everywhere else).
- **Committee clear:** the target may be any member of this club, active or not (404 only for an unknown or other-club id); permission is checked before existence (403 before 404).
- **Member cards:** one SQL query (the leader and coordinator id lists are sub-selects). "Window" is `sessions.starts_at >= now - 90 days` (future included); cancelled runs count, soft-deleted runs and groups and withdrawn leaders do not. Role matching on `club_members.roles` is a `LIKE '%"leader"%'` style match on the JSON text. Sorted by `displayName` case-insensitively, then member id. `hasBio` is true for a non-empty bio; goals alone do not list a member.
- **Tests:** `AppMemberProfileTest`, `AppMemberPhotoDownloadTest`, `AppMemberCardsTest`, base `AppProfilesBase`. Photos are hand-built JPEG headers (the test PHP has no GD); the signing key is set per test through `APP_KEY` in the environment.

## Phase 7b: account deletion

Decision D72. Not club-scoped: it covers every club the caller is linked to.

- `DELETE /app/account` with JSON body `{ "confirm": "DELETE" }`, authenticated (any signed-in user, linked or not).
  - Missing/other `confirm`: 422 `validation_failed` on `confirm`. Nothing is changed.
  - If the caller is the **only** `admin` of any club they belong to: 409 `last_admin` (message: "Make someone
    else an admin first."). Nothing is changed.
  - Otherwise, in one transaction, for the caller's Auth0 user:
    - delete the caller's `devices` and their `member_logins` rows (this login is unlinked from every member);
    - for each member that has **no remaining logins** after that (their last login just left), delete that
      member's app data and then the `club_members` row itself: `member_preferences`, `member_series_prefs`,
      `notification_preferences`, `notifications`, `member_profiles` and `member_photos` (blob), `group_messages`,
      `group_thread_states`, `session_attendees`, `session_group_leaders` (a group left without a confirmed
      leader on a run that expects leaders becomes `needs_leader` and the session is touched with
      `touchForChange()`), `member_link_attempts`; `sessions.coordinator_member_id` and `posts` author references
      are set to null (posts stay, with no author); and anything else keyed on `member_id` that exists by then
      (check every migration for `member_id` columns, don't rely on this list).
    - if the member still has another login, only this login and its devices are removed and the member's data
      stays (they are still reachable from the other login).
  - `users.athleteId` and the athlete/membership records are **not** touched (website account, club records).
  - Returns 204. Replay (already unlinked caller): 204 too.
  - No notification is sent to anyone; log one line without personal data (member id and club id only).
  - Schema note: `posts.author_member_id` became nullable for this (migration `2026_10_15_090000_make_posts_author_nullable`,
    manual SQL `api/database/manual/2026_10_posts_author_nullable.sql`; run it on the host before deploying the endpoint).
    `session_groups.created_by_member_id` is nulled as well (it is a foreign key to `club_members` too).
- App behaviour: Profile tab -> "About & privacy" screen with the app version, a "Privacy policy" link
  (https://bpj.org.uk/privacy-policy) and a red "Delete my account" action. It explains what is deleted and what is
  not (website login and membership stay), asks the user to type `DELETE`, calls the endpoint, then signs out,
  deletes this account's local database and credentials, and returns to the sign-in screen. 409 `last_admin` shows
  the message. While offline the button explains a connection is needed.

### Implementation notes (Phase 7b)

- **Where:** `AppAccountController@destroy` (route `DELETE app/account`, `auth` only, no `club` middleware) and `Services/AccountDeletion`. Tests: `AppAccountDeletionTest`, which also walks every foreign key to `club_members` in the test schema, so a table added later fails the test until the service and the test's `populate()` cover it.
- **Order of checks:** 401, 422 `confirm`, 409 `last_admin`, then the delete. `confirm` must be the string `DELETE` (exact case; `true`, `""`, arrays are 422).
- **`last_admin`:** for any member the caller is linked to (soft-deleted members skipped) that has the `admin` role, 409 unless another member of the same club who is `active` and not soft-deleted also has `admin`. It is judged per login: an admin whose member has a second login is still blocked (stricter than needed, never leaves a club without an admin).
- **Who is removed:** members that have no login left after the caller's logins go, including soft-deleted `club_members` rows. Everything uses the query builder, so soft-deleted `group_messages` and members really go.
- **Delete order, per removed member:** `group_messages`, `group_thread_states`, `session_attendees`, `session_group_leaders` (all statuses), then groups that lost their last *confirmed* leader on a `paced`/`single` run become `needs_leader` (`ClubSession::expectsLeaders()`, moved from `AppGroupController`; applies to past and cancelled runs too), `member_preferences`, `member_series_prefs`, `notification_preferences`, `notifications`, `member_photos`, `member_profiles`; then nulled: `sessions.coordinator_member_id`, `session_groups.created_by_member_id`, `posts.author_member_id`; finally `club_members`. Before all of that: `devices` and `member_logins` of the caller. `member_link_attempts` of the caller are deleted for the clubs whose member was removed.
- **Sync:** every run whose attendance or leaders changed gets `touchForChange()` (so `?since=` clients refresh counts and leader lists); runs that lost a coordinator and posts that lost an author get `updated_at` set to now. A group's own `updated_at` changes only when its status flips.
- **Not touched:** other members' notifications that mention the deleted member in their JSON `data`, `users`, `athletes`, `memberships`. No push or inbox row is written.
- **Logging:** `Log::info` of "removed member {id} of club {id}" after the commit; a failing log sink is ignored so a finished delete never turns into a 500.
- **Replay:** a user with nothing left (no logins, no devices) gets 204.

## Phase 8: parkrun tourism and race events

Decisions D74 and D76-D79. Everything reuses sessions, groups, attendance and chat; shapes not mentioned are
unchanged. All routes are under `/app/clubs/{clubId}` with `club:required`.

### Group modes `events` and `race`
- `groupMode` (series and sessions) gains two values, `events` and `race` (columns are plain strings, no enum
  change). Any place that lists the modes (validation, Swagger, tests) must include them.
  - **`events`** (e.g. a Saturday "parkrun" series): the run is a day on which people go to **different events**.
    Its groups are the individual events (kind `event`). Members create/join them.
  - **`race`** (an ad-hoc one-off such as "Droitwich 10k"): exactly one event. Creating a `race` session also
    creates its single group (kind `event`, `label` = the session title, active, no leaders, not deletable:
    `DELETE groups/{id}` is 409 `race_group_fixed`). People join it with the normal attendance call.
- **Venue is optional** on series and sessions in every mode (the API already allows null; the app must too).
- `ClubSession::expectsLeaders()` stays false for both, so event groups are always `active`.
- Pace fields (`paceUnit`, `paceFromS`, `paceToS`) and `lead` on a group of an `events`/`race` session are
  rejected: 422 on `paceFromS` ("Events have no pace"). `distance*` is allowed (e.g. 5 km) but optional.
- Group `kind` gains `event` (`SessionGroup::KINDS`). The group payload gains `locationId` (`uuid|null`) and
  `createdByMemberId` (`uuid|null`).
- Nothing in an `events`/`race` session sends pace-group notifications: no `group_matches`, no `pick_group`
  nudge, no `leaders_needed` (run level or group level), no leader withdrawal handling. Run reminders only go to
  members who are `going`/`maybe` (or whose series pref is explicitly `on`); the `auto` "went to the last 6" rule
  is not used for these modes. A reminder body for a member who picked an event reads "You're going to
  {event}" instead of "You're down for the {group}". Session-change notifications (cancel/restore/moved) work
  as today (audience = going/maybe attendees). The leader roster ("Lead a run") never lists these sessions
  (`GET sessions` is unchanged; the app filters by mode).

### Event groups (creating and joining)
- `POST /sessions/{sessionId}/groups` on an `events` session, by **any linked member** (not just leaders):
  `{ id?, locationId?, label?, description?, distanceValue?, distanceUnit? }`.
  - `locationId` (a live `event_locations` row of this club, else 422 on `locationId`) or `label` is required.
    If `label` is omitted it defaults to the location name. `kind` is forced to `event`.
  - **De-duplicated:** if a live group on that session already has the same `locationId`, return it with 200
    (not 201) and do not create another. (Free-text events with no location are not de-duplicated.)
  - The creator is marked `going` in the new (or existing) group, like a leader attending their own group.
  - On a `race` session, `POST groups` is 409 `race_group_fixed`.
  - Cancelled/past runs: the existing 409s.
- `PATCH groups/{id}` on an event group: the **creator**, committee/admin and the run's coordinator may edit
  `label`, `description` (meeting point, car-share seats: up to 1000 chars), `distance*`; nobody else (403).
  `locationId` is not editable.
- `DELETE groups/{id}` on an event group: the creator or committee/admin/coordinator (race groups: 409). Attendees
  of a deleted event group are left going with no group (as today); their `my_group_changes` notification
  (`group_removed:<id>`) says "{event} was removed. Pick another or let us know you can't make it."
- Joining and leaving an event is `PUT sessions/{id}/attendance` with `status: going` and `groupId`, exactly as
  for pace groups (no new endpoint). `going` with no `groupId` is still allowed ("going, event not chosen yet").
- Counts: the group's `goingCount` already counts attendees with that `groupId`. The session `summary` is
  unchanged; the app derives "3 going to 2 events" from the groups it already has.
- **Names for event attendees:** `GET sessions/{id}/plan` (Phase 4) returns attendee names only to leaders,
  coordinator and committee. For groups of kind `event`, it also returns the attendee names (member id,
  display name, status) to any member who is **in that same group** (going/maybe with that `groupId`), and only
  for that group. Everyone else still gets counts. (D77.)

### Event locations
- Table `event_locations` (club-scoped, soft deletes): `id uuid, club_id, kind` (`parkrun`|`race`|`other`),
  `name varchar(120)`, `slug varchar(80) null` (parkrun site code, e.g. `worcester`), `country varchar(2) null`,
  `region varchar(80) null`, `lat/lng` (decimal(9,6)) null, `url varchar(255) null`,
  `source` (`import`|`manual`), timestamps. Unique `(club_id, kind, slug)` where slug is not null is enforced in
  code (MySQL NULL-safe unique index on `(club_id, kind, slug)` is fine since NULLs don't collide).
- `GET /event-locations?since=` → `{ items, serverTime }` with tombstones, same sync rules as venues. Without
  `since` returns every live row (a UK parkrun list is about 800 rows; no paging).
- `POST /event-locations` `{ id?, kind?, name, region?, lat?, lng?, url? }`: any linked member may add a
  `race`/`other` location (kind defaults to `other`); `parkrun` kind is committee/admin only (403 otherwise).
  Idempotent on `id`; the same `(kind, name)` case-insensitively returns the existing row (200). `source` =
  `manual`.
- `PATCH /event-locations/{id}` and `DELETE` (soft): committee/admin only. Deleting a location used by a live
  group is allowed (groups keep their label; `locationId` is kept as is).
- **Import (host console):** `php artisan app:import-event-locations {clubId} {file} [--kind=parkrun]
  [--country=97] [--dry-run]`. `file` is either the public parkrun `events.json` (GeoJSON-style
  `{"events":{"features":[{"id":…,"properties":{"eventname":"worcester","EventLongName":"Worcester parkrun",
  "EventShortName":"Worcester","countrycode":97,"seriesid":1},"geometry":{"coordinates":[lng,lat]}}]}}`;
  `--country` filters on `properties.countrycode`, default 97 = UK; accept either a top-level `features` or
  `events.features`) or a CSV with header `name,slug,country,region,lat,lng,url`. Upserts by
  `(club, kind, slug)` (updating name/lat/lng/url/region), never deletes, prints created/updated/skipped counts,
  `url` for parkrun = `https://www.parkrun.org.uk/{slug}/`. `--dry-run` writes nothing. Document where to get
  the file (the owner downloads it from parkrun's site) in `setup.md`.

### Schema (one manual SQL file, `api/database/manual/2026_10_events.sql`)
- `event_locations` as above; `session_groups.location_id char(36) null` (FK to `event_locations`, index) — a
  `session_groups` group of kind `event` keeps the label even if the location is later removed.
Follow the hosting constraints in `api/CLAUDE.md`.

### App behaviour for Phase 8
- **Editors:** the series editor's group-mode choice gains "Events (e.g. parkrun)"; the ad-hoc run editor gains
  "Events (e.g. parkrun)" and "Race (one event)". Venue is optional in all editors (a "No venue" choice; a
  series or run saved without a venue shows no location row). End time is already optional (D47).
- **Runs card** for `events`/`race` sessions: no pace strip, no "needs leader" chips. Summary line: "3 going to 2
  events", "1 going", or "No one has picked a parkrun yet"; for yourself "You're going to Worcester parkrun".
  Never shows "N groups".
- **Run page** for `events`: heading "Where are you running?", the event cards (name, going count, note, your
  fellow attendees with avatars when you are in it, **I'm going / Leave**, **Chat**) and an **Add a
  parkrun/event** button opening a picker (search the club's event locations; recently used first; "Other…" to
  type a name; if the user may add race/other locations they can save it). For `race`: one card ("Who's going":
  counts, names if you're going, I'm going / Can't go, Chat). No pace note, no coverage card, no pick-a-group
  prompt, no leader controls.
- **Lead a run** and the committee coverage view skip these modes.
- **Committee:** can manage event locations (list, add, edit, delete) from the Profile tab's committee area.
- **Offline:** event locations are cached in Drift (new table) and synced with `?since=`; adding a group stays
  online-only like other group writes (D16/D19); attendance changes stay optimistic (D23).

## Implementation notes (Phase 8a)

No deviations from the contract above. Choices made where it was silent:

- **Schema:** `event_locations` has non-unique indexes `(club_id, updated_at)` and `(club_id, kind, slug)`; the
  `(club, kind, slug)` and `(kind, name)` rules are enforced in code (the contract allows this). Migrations
  `2026_10_16_090000`/`090100`; manual file `api/database/manual/2026_10_events.sql` (run after
  `2026_10_posts_author_nullable.sql`).
- **`POST groups` on `events`:** check order is 404, 422, then 409 `race_group_fixed` (race runs), the id replay (200),
  then `session_cancelled`/`session_past`, then the de-duplication. A duplicate on a finished run is therefore 409, not a
  silent join. The creator is marked going with the same helper as a leader (`attendInGroup`), so an existing per-run
  pace on their attendance row is kept. Missing `locationId` and `label` is 422 on `label`. A label longer than 80
  characters is only possible via a long location name, which is clipped to 80 when used as the default.
- **Pace and `lead`:** any non-null `paceUnit`/`paceFromS`/`paceToS`, or `lead: true`, is 422 on `paceFromS` ("Events have
  no pace."), on create and on PATCH. Explicit nulls and `lead: false` are accepted. `kind` is ignored on create and, on
  PATCH, a value other than `event` is 422 on `kind`.
- **Event kind outside event runs:** `kind: event` on a pace/open/routes run is 422 on `kind`; `locationId` on those runs is
  ignored (not stored).
- **Event group PATCH:** `label` can be changed but not cleared (422 on `label`); `description`, `distance*` as for any
  group; `locationId` and `kind` are not editable (a `locationId` in the body is ignored). Creator, coordinator,
  committee and admin may edit and delete; leaders of event groups (the leader endpoints still work, nothing blocks
  them) get no extra rights, and a group of an `events`/`race` run never becomes `needs_leader`.
- **Race:** the single group is created inside `POST sessions` with `created_by_member_id` = the committee member who
  made the run, and its `label` follows the run's title when the run is renamed. `DELETE groups/{id}` is 403 for people who
  may not delete it, otherwise 409 `race_group_fixed` (checked before the closed-run 409).
  A series with `groupMode: race` is 422 on `groupMode` ("Races are one-off runs.") on create and on PATCH.
- **Plan names:** members of the same event group get `attendees: [{memberId, displayName, status}]` for that group only,
  with `displayName` the short "Sam B." form (`ThreadAccess::shortName`) and no pace fields, sorted by name. Leaders,
  coordinator and committee still get the full `names()` shape (full display name, pace) for every group.
- **Notifications:** `RunNotifier::matchGroup`, `nudgePickGroup` and `leaderWithdrawn`, and `RunReminderService::alertLeaders`
  return without doing anything for event-mode runs, and a new event group queues no job. A removed event group's
  `group_removed` keeps the title "Group removed" and uses the body "{event} was removed. Pick another or let us know you
  can't make it." Reminders for these runs go to going/maybe and explicit series pref `on`, minus "not going"; a going
  member in an event gets "You're going to {event}. Can't make it?" (with the going / not going buttons), going with no
  event keeps "You're down for this run. Can't make it?", maybe is unchanged.
- **Event locations:** `POST` checks the parkrun role (403) before validation. A duplicate `(kind, name)` ignores
  soft-deleted rows. `PATCH` edits `name`, `region`, `country` (2 letters), `lat`, `lng`, `url`; `kind` and `slug` are
  fixed. `lat`/`lng` are rounded to 6 decimals; `url` must be http(s).
- **Import:** run inside one transaction. A parkrun JSON row needs `properties.eventname` and a long or short name,
  otherwise it is skipped; rows of another `countrycode` are skipped; the same slug twice in a file counts once. `region`
  is not in parkrun's file (null). `country` is stored as `GB` for code 97 and null for other codes (no reliable
  code table); a CSV's own 2-letter `country` is used. A location the committee deleted stays deleted (counted as
  skipped); rows missing from the file are kept. Output is `Created N, updated N, unchanged N, skipped N.` (`unchanged`
  is an addition, so unchanged rows keep their `updated_at` and are not re-sent to phones). Non-parkrun kinds get no `url`
  unless a CSV gives one.
- **Account deletion:** nothing new is member-keyed. A deleted member's event groups keep existing with
  `created_by_member_id` null (covered by a test).

## Implementation notes (Phase 8c, app only)

No API changes. How the app calls the Phase 8 endpoints:

- **Add an event:** `POST sessions/{id}/groups` with `{ id, kind: "event", locationId }` or `{ id, kind: "event",
  label }` only (no pace, no `lead`). A 200 means the event already existed (de-duplicated by location) and the caller
  was marked going in it; a 201 is a new group. Either way the app merges the returned group and sets its own
  attendance to going in it (`GroupsRepository.addEventGroup`).
- **Edit a note:** `PATCH groups/{id}` with the group's current `kind` (`event`), `label` and `distance*` plus the new
  `description` (null clears it; max 1000).
- **Join / leave:** `PUT sessions/{id}/attendance` as for pace groups: join sends `going` + `groupId`, "Leave" sends
  `going` with no `groupId`, "Can't come" / "Can't go" sends `not_going` (D85).
- **Names:** `GET sessions/{id}/plan` is fetched when the run page opens; `attendees` for an event group are shown
  only while the caller is in that event (or is committee/coordinator).

## Phase 9: club standards

The BPJ club standards scheme (the same Bronze/Silver/Gold/Platinum time table as
https://apps.bpj.org.uk/club-standards/) as one cacheable document, plus the caller's own gender and
age category so the app can open on the right table.

### `GET /app/clubs/{clubId}/standards`

`club:required`: any linked member. Errors: 401 no token, 403 `not_a_member`, 404 `club_not_found`.

**Limitation (BPJ only):** the `standards`, `awards` and `events` tables are the BPJ scheme and have no `club_id`.
The route is club-scoped only so auth works like every other `/app/clubs/{clubId}/...` endpoint; every club gets
the same table. Revisit (add `club_id`) if a second club ever needs its own scheme.

```json
{
  "awards": ["Bronze", "Silver", "Gold", "Platinum"],
  "events": [ { "event": "Mile", "distanceM": 1609.34 }, { "event": "5K", "distanceM": 5000 } ],
  "categories": { "male": ["U20", "U23", "SEN", "V35", "V40"], "female": ["U20", "U23", "SEN", "V35"] },
  "items": [ { "gender": "male", "category": "SEN", "event": "Mile", "award": "Bronze", "time": "7:25", "timeS": 445 } ],
  "mine": { "gender": "male", "category": "V45" },
  "updatedAt": "2026-10-15T09:30:00Z"
}
```

- `awards`: names ordered by `awards.id`, lowest first (Bronze ... Platinum). Use it as the column order.
- `events`: only events that have at least one standard, ordered by distance. `distanceM` is **metres** (the
  `events.distance` column holds metres: 1609.34, 5000, 10000, 21097.5, 42195), so it can be a non-integer. Pace
  is `timeS / distanceM * 1609.344` seconds per mile (or `* 1000` per km).
- `categories`: distinct categories present per gender, ordered U20, U23, SEN, then V35, V40 ... numerically.
  Gender keys are `male` and `female`. The database stores `M`/`W`; they are mapped here (the athlete summary
  elsewhere still says `M`/`W`).
- `items`: one row per gender + category + event + award, ordered male then female, category order as above,
  event distance, then award order. `time` is the text as stored (`25:48`, `1:58:26`); `timeS` is whole seconds,
  taken from `standards.time_parsed` (seconds; it is what the award queries compare against) and, if that is empty,
  parsed from `time` (`mm:ss` or `h:mm:ss`, so `1:58:26` is 7106). `timeS` is null only if neither is usable.
- `mine`: the caller's `gender` and `category` from their linked athlete record, or `null` when the athlete is
  missing, has no gender, or has no category (for example no date of birth). The category is the same
  `Athlete::category` the profile endpoint returns (`U20`, `U23`, `SEN`, `V35`, `V40` ...: age under 20, under 23,
  under 35, then `V` plus the age rounded down to 5). If that band is not in the table for that gender (a V85 when
  the table stops at V80) the oldest `V` band that exists is used; if the gender has no rows at all, `mine` is null.
- `updatedAt`: when the server built the response (the standards tables carry no timestamps). It is not part of the
  ETag, so do not use it to detect changes.

**Caching:** the response carries `ETag: "<sha1 of the body without updatedAt>"` and
`Cache-Control: private, no-cache`. Send the tag back as `If-None-Match` and an unchanged table answers `304` with
no body. The tag includes `mine`, so it differs per caller when their category differs.

**Cost:** two queries on the shared tables (awards; standards joined to events) plus one athlete lookup. No N+1.

### App behaviour for Phase 9

`/profile/standards` (row "Club standards" on the Profile tab): Men/Women control and a chip row of that gender's
`categories`, opening on `mine` (or Men SEN when `mine` is null); one card per event that has `items` for the open
category, with the four awards as tiles showing `time`, or the pace from `timeS` and `distanceM` in the viewer's pace
unit. The document is cached whole in `standards_cache` (schema v9) and revalidated with `If-None-Match` on open and
on resume; a 304 only updates the "Updated ..." time (D90-D93).

### Implementation notes (Phase 9a)

`AppStandardsController@index`. No schema changes and no new SQL. Tests: `tests/AppStandardsTest.php` (creates minimal
`standards`, `awards` and `events` tables, as the legacy tables have no migrations).

## Update (2026-10-17): leader prompts, one group per leader, step down

Decisions D106-D110. Applies on top of Phases 4 and 5.

### Days I may lead (`member_preferences.lead_days`)
- New column `member_preferences.lead_days varchar(20) null`: comma-separated ISO weekdays (`1`=Monday ...
  `7`=Sunday), e.g. `2,4`. `NULL` = the member never chose days; empty string = chose "none".
- `GET /preferences` gains `leadDays`: `null` (never chosen) or an array of ints (`[]` = none, `[2,4]`).
  `PUT /preferences` accepts `leadDays` (array of ints 1-7, deduplicated and sorted; `null` resets to "never
  chosen"; anything else 422 on `leadDays`). Omitted key = unchanged. Existing keys behave as before.

### Who gets "leaders needed" notifications (replaces the Phase 5 audience for both kinds)
Applies to the run-level alert (`leaders_needed_run:<session>`) and the group-level one when a leader withdraws
(`leaders_needed_group:<group>`); the group's attendees still get their own locked notice. A member is a candidate
when they are an active member not already leading in that run and not `not_going`, and:
1. their `lead_days` is **set** (not null): the run's weekday (club-local) is in `lead_days` -> yes, otherwise no
   (an explicit choice always wins, even over history);
2. else they have **led this series before** (any `session_group_leaders` row, any status, on a session of the same
   series in the last 26 weeks; for ad-hoc runs without a series: same weekday) -> yes;
3. else they hold the `leader` role **and have never led anywhere** (a brand-new leader) -> yes;
4. else no.
(Pace fit for the group-level alert is applied on top as before.) Being marked `leader` alone no longer
means "tell me about every run".

### One group per leader per run
- `POST /sessions/{id}/groups` with `lead: true` (or the default), and `POST /groups/{id}/leaders`: if the caller is
  already a **confirmed leader of a different live group of the same session**, 409 `already_leading` with
  `{ "groupId": "<the group they lead>" }`. Re-joining the same group is idempotent as before. Leaderless groups
  created by committee/coordinator (`lead: false`) and event groups are unaffected.
- `POST /groups/{id}/leaders` with `role: "leader"` when the group already has a confirmed leader whose role is
  `leader`: 409 `leader_exists` (message: "This group already has a leader. Join as co-leader or backmarker.").
  Co-leader and backmarker roles are not limited.

### Stepping down (`DELETE /groups/{id}/leaders/me`, optional JSON body `{ "notGoing": bool }`)
Replaces the Phase 4 rule "withdrawing keeps attendance" (D30). In one transaction:
- the caller's leader row becomes `withdrawn`;
- the caller is **removed from the group**: their attendance `group_id` becomes null (status stays `going`; if
  `notGoing` is true the status becomes `not_going`);
- **if the caller created the group (`created_by_member_id`), no other confirmed leader remains and nobody else is
  in the group (no other attendee with this `groupId`)**, the group is soft-deleted (and the session touched) and the
  response is the group payload with `deletedAt` set; no notifications are sent;
- otherwise the group stays; if no confirmed leader remains on a run that expects leaders it becomes `needs_leader`
  and the Phase 5 notifications fire (attendees told, fitting members asked to lead), as before.
Response: 200 with the group payload (the deleted case carries `deletedAt`).

### App behaviour
- **Lead a run screen:** a compact "Days I may be able to lead" panel replaces the filter chips. First time (`leadDays`
  null): a prompt "Which days could you lead?" with day chips (only weekdays that have upcoming runs, plus any
  already chosen) and a **Save** button (saving with nothing selected is allowed and means "none"). After saving it
  shows one line, "Days you may lead: Tue, Thu" with a **Change** link that re-opens the chips. The roster lists only
  runs on the chosen days (runs you already lead always show; a note says how many are hidden). Saved on the
  server through `PUT /preferences`. The old local filter is migrated: if the server value is null and a local
  `leadRosterDays` exists, it pre-selects those days (not saved until the member taps Save).
- **How will you help lead?** sheet: the "Leader" option is hidden when the group already has a leader; only
  "Co-leader" and "Backmarker" are offered.
- **Step down?** dialog: "You'll be removed from this group" plus a checkbox "I can't make this run at all". When
  the viewer created the group and nobody else is in it, the text says the group will be deleted instead. After the
  call the app removes the group locally if `deletedAt` is set and updates the viewer's attendance.
- **One group per leader:** the app does not offer "Offer to lead"/"Join as leader" on other groups of a run you already
  lead in, blocks saving a second group with a clear message (and offers to open the group you lead) and handles
  409 `already_leading` / `leader_exists` the same way.
- **Notification icon (Android):** a monochrome pear silhouette made from the club logo is the small icon
  (`ic_stat_bpj`), orange `#f89829` accent colour, and the club logo is the large icon on notifications the app
  builds itself.

### Implementation notes (2026-10-17)
- **Schema:** migration `2026_10_17_090000_add_lead_days_to_member_preferences_table` (`lead_days varchar(20) null`); manual
  SQL `api/database/manual/2026_10_lead_days.sql` (run once after `2026_10_events.sql`).
- **`leadDays` input:** a JSON list of integers 1-7 only (strings, floats, booleans, nested lists and objects are 422 on
  `leadDays`; `null` resets, `[]` = none). Stored sorted and deduplicated, `[]` as the empty string; unreadable stored values
  are ignored when read.
- **One audience helper:** `Services/LeaderAudience` answers "might they lead this run?" for both alerts; `RunNotifier::availableLeaders`
  (used by both) then applies pace fit, already leading, not going, inactive members and the actor.
- **History window:** 26 weeks back from the run's own start (inclusive at that instant), strictly before the run, so the run
  itself and later runs never count. A leader row of any status counts, including a withdrawn row on a group that was later
  deleted. A run with a series counts only that series; a run without one counts any session (series or ad-hoc) on the same
  club-local weekday. Never-led (rule 3) looks at every leader row of the club at any date.
- **Default for `leaders_needed`:** on when the member has the `leader` role, has `lead_days` set (not null, even "none") or has
  any leader row; an explicit saved preference still wins. The category still shows for everyone.
- **`already_leading`** applies to every role on join (leader, co_leader, backmarker) and to `lead: true` on create; only
  confirmed leader rows on live groups of the same run count. The check order is 404, 422, 409 `session_cancelled`/`session_past`,
  then `already_leading`, then `leader_exists`. A replayed create (same `id`) still returns the existing group first.
  Event-mode runs and `kind: event` groups are exempt from both rules.
- **`leader_exists`** ignores the caller's own row, so the leader re-joining is idempotent and may switch to co_leader; a
  co_leader asking for `leader` while another leader exists is refused.
- **Step down body:** `notGoing` must be a real boolean when present (`null`, `1`, `"true"` are 422 on `notGoing`).
  With `notGoing: true` the caller's attendance is set to `not_going` with no group even if it pointed at another group, and a
  `not_going` row is created if there was none; without it only an attendance pointing at this group is cleared (status kept).
- **Deleting the group:** only when the caller created it, no confirmed leader remains and no attendee row (any status) has this
  `groupId` after the caller is removed. The row is soft-deleted in the same transaction as the leader and attendance changes.
- **Replays:** a step down by someone with no confirmed leader row changes nothing (a `notGoing` on the replay is ignored) and
  returns the group payload. A replay after the group was deleted returns 200 with `deletedAt` set instead of 404.
- **Not touched:** `GroupPresenter` already counts attendees by `group_id`, so `goingCount` and the caller's `summary.myGroupId`
  reflect the removal without changes; `AccountDeletion` is unchanged.
- **Tests:** `AppLeadDaysTest`, `AppLeaderAudienceTest` (both channels), `AppLeaderRulesTest`, `AppStepDownTest`; D30 assertions in
  `AppGroupsLeadersTest` were changed deliberately, and `AppGroupsTest`/`AppGroupsLeadersTest` fixtures that had one member leading two
  groups or two `leader`s now use distinct members or roles.

## Update (2026-10-18): days I run and days I may lead (D115, D116)

Applies on top of the 2026-10-17 update.

### Days I run (`member_preferences.run_days`)
- New column `member_preferences.run_days varchar(20) null`, the same encoding as `lead_days` (`1,3`; `NULL` = never
  chosen, which means every day; empty string = none).
- `GET /preferences` gains `runDays` (`null` or a sorted array of ints). `PUT /preferences` accepts `runDays` with the same
  validation as `leadDays` (422 on `runDays`). Omitted key = unchanged.
- **Lead days stay inside run days** when both are set (you are there when you lead). The list being saved wins:
  - saving `leadDays` adds those days to `runDays`;
  - saving only `runDays` drops lead days it no longer includes;
  - saving both does the first.
  With either list `null`, nothing is aligned. The response always carries both lists, so the app caches what the
  server decided.

### Which run notifications follow the days
Only notifications a member did not ask for by answering are narrowed. A run's weekday is club-local. "Runs on the
day" means: `run_days` is null, or the weekday is in `run_days` or `lead_days`.
- **`group_matches` (new group at your pace):** a member with **no answer** for the run is told only when they run
  on that day. Going or maybe is told as before.
- **Run reminders, series "usually comes" rule (D35):** the automatic audience (went to one of the last 6 runs of the
  series) needs to run on that day. An answer for this run, or the series set to "always", still reminds.
- **`leaders_needed`:** `lead_days` set still decides alone. Without it, a member whose `run_days` is set and leaves
  out the weekday is not asked, before the history and new-leader rules apply (new rule 2 of `LeaderAudience`).
- **Unchanged:** everything sent because you are going, maybe or leading on that run. That covers changes to my runs,
  the leader-withdrew notice, group removed, the pick-a-group nudge and reminders for runs you answered or lead.
  Club updates and group messages are unchanged too.

### App behaviour
- **One shared panel (`MyDaysPanel`)** on the Runs tab (run days) and Lead a run (lead days).
  - **Once a choice is made** it is one line: "Run days: Mon, Wed" or "Lead days: Mon", **Show N more** when runs are
    hidden, and **Change**. Show N more lists every day for this visit (a view, not a save) and becomes **Just my
    days**. **Change** reopens the chips with Save and Cancel.
  - **Runs tab:** until a choice is made it shows "Showing every day" and **Choose days**, and only when there are two
    or more weekdays. Saving needs at least one day, and **Show every day** clears the choice (`runDays: null`).
  - **Lead a run:** asks straight away while `leadDays` is null, as before. The chips start ticked from the old local
    filter, else from the run days. "None" is still a valid choice.
  - **Hints:** each editor says when saving changes the other list too ("Tue will be added to your run days.",
    "You'll stop being asked to lead on Mon.").
- **Runs tab** shows runs on the run days plus any lead day. Runs you're going to, might go to or lead always show,
  whatever the day. A "can't come" run on another day stays hidden.
- **Lead a run** shows runs on the lead days, else on the run days, else every day. Runs you lead always show.

### Implementation notes (2026-10-18)
- **Schema:** migration `2026_10_18_090000_add_run_days_to_member_preferences_table`; manual SQL
  `api/database/manual/2026_10_run_days.sql` (run once, after `2026_10_lead_days.sql`).
- **Code:** `MemberPreference::parseDays`/`formatDays` (renamed from `parseLeadDays`/`formatLeadDays`) and
  `MemberPreference::runsOn($pref, $weekday)`; the alignment is `AppPreferenceController::alignDays`.
- **App cache:** `preferences.run_days` text, Drift schema v11, with an upgrade test from a real v10 file
  (`test/fixtures/db/v10.sqlite`).
- **Tests:** `AppLeadDaysTest` (run days, alignment, validation), `AppGroupMatchTest`, `AppRunRemindersTest`,
  `AppLeaderAudienceTest` (both channels).

## Update (2026-10-19): Runs I follow (D117, D118)

Applies on top of the 2026-10-18 update. Replaces "days I run" as the thing that narrows the Runs tab and the
unasked-for run notifications.

### The model
- **One mode per member and series**: `follow`, `auto` or `hide` in `member_series_prefs.mode`. No row = `auto`.
- **One resolver** decides both effects, `Services/FollowResolver::resolve($rsvp, $mode, $usuallyComes)` on the server
  and `resolveFollow` in the app (`features/runs/logic/follow_resolver.dart`). Both are tested against one case table,
  `api/tests/fixtures/follow_resolver_cases.json`. In order:
  1. RSVP going or maybe (leading counts as going): shown in My runs;
  2. `hide`: not followed, not shown;
  3. `follow`: followed and shown;
  4. `auto`: followed and shown only when the member usually comes (D35: going at one of the last 6 ended,
     not-cancelled runs of the series; never for `events`/`race` series, D79).
  A run with no series (a one-off) is never followed but always shows (open question 5).
- **What "followed" drives on the server:**
  - **Run reminders:** going/maybe/leading on the run, plus everyone the resolver calls followed, minus `not_going`.
    So Hide stops the series reminder but an RSVP still reminds (open question 1).
  - **`group_matches`:** a member with no answer is told only when the run is in their My runs.
  - **`leaders_needed` fallback:** `lead_days` set still decides alone; otherwise a member who hid the series is not
    asked (this replaced the run-days rule of `LeaderAudience`).
- `run_days` no longer narrows anything on the server.

### `GET /app/clubs/{clubId}/follows`
```json
{ "series": [ { "seriesId": "uuid", "title": "The Mug Run", "weekday": 4, "localStartTime": "18:30",
                "groupMode": "paced", "mode": "follow|auto|hide", "usuallyComes": true, "followed": true } ] }
```
Every live series of the club, in week order (weekday, time, title). `followed` is what the mode resolves to with no
RSVP; the app resolves RSVPs itself from the cached session `summary`.

### `PUT /app/clubs/{clubId}/follows/{seriesId}` `{ "mode": "follow|auto|hide" }`
Returns that series' entry. 404 `not_found` for a series that is not a live series of the club; 422
`validation_failed` for a missing or bad mode. Idempotent: the same mode again writes nothing.

### `PUT /app/clubs/{clubId}/follows`
- `{ "seriesIds": ["uuid", ...], "mode": "follow" }`: Follow all (one day) and Follow everything.
- `{ "modes": { "uuid": "auto", ... } }`: Undo, putting each series back exactly.

Returns `{ "previous": { "uuid": "mode", ... }, "series": [every entry, as GET] }`. Nothing is saved when any id is not
a live series of the club (422 naming `series.<id>`) or any mode is bad (422). An empty `seriesIds` is a 200 no-op.

### No `view` parameter on the feed
The plan suggested `GET /sessions?view=mine|all`. The app is offline-first and builds the Runs tab from the Drift
cache, so the feed is filtered on the device with the same resolver, using the cached `/follows` entries and each
session's `summary`. `GET /sessions` is unchanged, and switching views never touches the network.

### Older app versions (kept until step 5 of the rollout)
- `GET /notification-settings` still lists `series[].reminders`, now read from the mode: `follow` = `on`,
  `hide` = `off`, `auto` = `auto`. `PUT` with `series` writes the mode the same way (`auto` stores an explicit `auto`
  row rather than deleting it). New apps no longer show this list.
- `PUT /preferences` with a non-null `runDays` still stores `run_days` (the old app filters on it) and also sets every
  `auto` series on those days to `follow`, the bulk equivalent of Follow all; `hide` and `follow` are left alone.
  `runDays: null` writes no modes. `GET /preferences` still returns `runDays`.

### Migration (`php artisan app:migrate-follows [--dry-run]`)
Per member and live series, first match wins:

| Existing state | Mode | Rule key in the report |
|---|---|---|
| Reminder setting Never (`off`) | `hide`, even on a selected day | `never_to_hide` |
| Always (`on`) | `follow` | `always_to_follow` |
| Automatic, series on a selected day (run days plus lead days, as the old Runs tab showed) | `follow` | `automatic_on_selected_day_to_follow` |
| Automatic, series on another day | `auto` | `automatic_on_other_day_to_auto` |
| No day filter ever saved | `auto` | `no_day_filter_to_auto` |

- Only non-`auto` results (and existing rows) are written. The old `reminders` value and `run_days` are kept.
- Each migrated member gets `member_preferences.follows_migrated_at` (a row is created if they had none), so a second
  run changes nothing. `--dry-run` prints the same counts and writes nothing.
- **Before the migration runs** a member is read through the same mapping on the fly
  (`SeriesFollows::effective`), and any write migrates that member first, so there is no gap where behaviour differs.

### App behaviour
- **Runs tab** has a 48dp **My runs | All runs** switch (selected side orange with a check). It is screen state only,
  never saved, and resets when the app restarts. A member with no choices at all (every series `auto`) starts on
  All runs, since they saw every run before (open question 3); once they choose anything it starts on My runs.
- **My runs:** caption "Followed runs and your RSVPs" with a **Runs I follow ›** link; runs the resolver shows; a bar
  above the navigation "N other runs this week" (else "N other runs coming up") with **Show all runs**, hidden at 0.
  Empty: "You're not following any runs yet" (or "None of the runs you follow are coming up") with **Choose runs** and
  **Show all runs**.
- **All runs:** dashed "Just looking. This doesn't change which runs you follow." banner; every run; hidden runs
  dimmed with a Hidden chip.
- **Card:** time (bold orange), one status chip (Going, Maybe, Can't come, Following, Not following, Hidden; none for a
  one-off), name, meeting point. **Follow** (outlined) for a series run that is not followed and has no RSVP yes;
  it saves at once and the card updates in place. Otherwise **Manage** opens the run.
- **Runs I follow** (`/follows`, also from Notification settings' "Run reminders" row): series by weekday with
  **Follow all** per day, a 44dp **Follow | Auto | Hide** control per series and a status line ("Following",
  "Auto: following (you usually come)", "Auto: not following (you rarely come)", "Auto: not following (choose Follow
  for events)", "Hidden · only shown in All runs"), and **Follow everything**. Every tap saves; Follow all and Follow
  everything show a snackbar with **Undo** that any later change dismisses. A failed write reverts and says so.
- **Notification settings** keeps the categories and the daily push limit; the per-run list is replaced by one row.
- **Lead a run** shows the lead days, else every day (no run-days fallback any more) and no longer warns that saving
  lead days changes the run days.
- The days-I-run panel is gone from the Runs tab. `MyDaysPanel` now serves only Lead a run.

### Implementation notes (2026-10-19)
- **Schema:** migration `2026_10_19_090000_add_follow_mode_to_member_series_prefs_table`; manual SQL
  `api/database/manual/2026_10_follows.sql` (after `2026_10_run_days.sql`).
- **Server code:** `Services/FollowResolver` (the rule), `Services/SeriesFollows` (modes, usually-comes history,
  writes, migration mapping), `AppFollowController`, `Console/Commands/MigrateFollows`. `MemberPreference::runsOn` is
  gone.
- **App cache:** table `series_follows`, Drift schema v12, with an upgrade test from a real v11 file
  (`test/fixtures/db/v11.sqlite`). Writes are online-only and optimistic (`FollowsRepository`): the cache changes at
  once and is put back if the PUT fails.
- **Tests:** `FollowResolverTest` (shared table, plus every row through the real reminder job and `GET /follows`),
  `AppFollowsTest`, `MigrateFollowsTest`, updated `AppGroupMatchTest`, `AppRunRemindersTest`, `AppLeaderAudienceTest`,
  `AppNotificationsV2Test`; app `follow_resolver_test` (same table), `follows_repository_test`,
  `runs_i_follow_screen_test`, `runs_screen_test`.
