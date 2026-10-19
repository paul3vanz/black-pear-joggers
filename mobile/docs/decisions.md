# Decisions

This is a short architecture decision log. Add an entry whenever a choice would
be expensive to reverse or isn't obvious from the code. Newest entries go at the
bottom. Superseded entries are marked rather than deleted.

**D1 — Extend the existing Lumen API (2026-10-06).**
New endpoints live under an `/app` route prefix, so they don't clash with the
existing `/clubs/{clubId}` EA lookup routes.
- Same MariaDB, hosting and Auth0 audience (`https://bpj.org.uk`).
- Follow the existing controller, Swagger-annotation and Bruno conventions.

**D2 — Flutter stack (2026-10-06).** Riverpod, go_router, Drift, dio,
json_serializable and auth0_flutter. Prefer plain Dart 3 features (sealed
classes, records) over freezed. See [architecture.md](architecture.md).

**D3 — Auth0 Native app with per-account credentials (2026-10-06).**
- Social and email login use Universal Login.
- Sessions last a long time via rotating refresh tokens.
- Credentials are stored per Auth0 `sub`, so several people can share a device.
- Each account gets its own SQLite file.

**D4 — Push via FCM only; the server targets; the inbox is the source of truth (2026-10-06).**
- FCM is free and is required for Android push anyway.
- No other Firebase products are used.
- Every push is backed by a `notifications` row, so missed pushes aren't lost.

**D5 — Offline-first (2026-10-06).**
- Reads: Drift streams in the UI, refreshed from the API with `?since` deltas.
- Writes: optimistic local write, then an outbox replayed with client UUIDs.

**D6 — Every new table is club-scoped (2026-10-06).**
- Rows carry `club_id`, and personal rows also carry `member_id`
  (`club_members` = user × club).
- UUID primary keys, soft deletes and snake_case columns.
- Roles live on `club_members`, not in Auth0 permissions.

**D7 — Recurring runs are materialised (2026-10-06).**
- `session_series` generates concrete `sessions` 8 weeks ahead.
- Editing a single occurrence sets `is_detached`.
- Cancelled runs keep their row with `status = cancelled`.

**D8 — Paces are stored as entered, with their unit (2026-10-06).**
- Columns are `pace_unit` + seconds.
- Values are converted only for display and matching, so 8:00/mi never comes back
  as 7:59/mi.

**D9 — Linking membership is one verified server call (2026-10-06).**
- `POST /app/clubs/{id}/link {urn, dob}` checks the details and links in a single
  step. The web flow does this in two steps, and `PUT /user` trusts any
  `athleteId`.
- Existing web links are backfilled from `users.athleteId`.

**D10 — Push and club updates come before runs and groups (2026-10-06).**
- Notifications are the infrastructure every later feature needs.
- Club updates prove that infrastructure with the least extra scope.

**D11 — Many logins can map to one member (2026-10-06).**
- `club_members` is one *person* per club, unique on athlete.
- `member_logins` maps any number of Auth0 subs to that member.
- The legacy `users` table is still written, for the web apps.

**D12 — Anyone can lead; `leader` is a badge (2026-10-06).**
- Any linked member can offer to lead a group.
- The committee awards the `leader` role to qualified leaders.

**D13 — Attendee names are for leaders only (2026-10-06).**
- Group leaders, coordinators and committee see attendee names.
- Members see counts and pace spreads.

**D14 — Members only, for now (2026-10-06).**
- Club features need a linked membership.
- Trial runners and parkrun come later.
- Sunday long runs are in scope, using the `routes` group mode.

**D15 — Firebase is configured from `config/*.json`, not `google-services.json` (2026-10-07).**
- The app builds `FirebaseOptions` at runtime from `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`,
  `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_ANDROID_APP_ID` and `FIREBASE_IOS_APP_ID`.
- There's no `google-services.json`, no google-services Gradle plugin and no flutterfire CLI.
  The values are public identifiers, the same as the Auth0 client id.
- While they're empty, push is skipped silently and the feed, inbox and settings still work.
- It also keeps dev and prod Firebase projects a one-line config change.

**D16 — Committee posting is online-only for now (2026-10-07).**
- Creating a post is a direct `POST` with a client UUID, not an outbox write. Offline shows a
  clear message and keeps the draft on screen.
- It's rare, small and needs the server to notify members, so queueing it buys little.
- The client UUID already makes a manual retry idempotent. Move it to the outbox if committee
  members ask to draft offline.
- Marking notifications read is the opposite: it updates locally first and retries on the next refresh.

**D17 — Session times are club-local strings plus UTC (2026-10-07).**
- Sessions carry `startsAt` (UTC) and `localDate` / `localStartTime` in the
  club's timezone. The app displays the local strings, so a 19:00 run is 19:00
  wherever the phone is, and no timezone database is needed on the device.

**D18 — Sessions regenerate from the series; edits detach (2026-10-07).**
- Editing, cancelling or restoring one occurrence sets `is_detached`, and the
  generator never touches it again.
- The generator runs hourly from the scheduler and on each series write, so no
  shell access is needed on the host to bring runs into existence.

**D19 — Runs: everyone syncs series, "today" is the device date (2026-10-07).**
- `RunsRepository.refresh` pulls sessions, venues and series for every linked
  member (the contract lets any member read them), so the session detail can
  join the series for `cmsSlug` (the "More about this run" link) without
  copying it onto the session row.
- "Today" for grouping and pruning is the device's local date compared with the
  club-local `localDate` strings. Good enough while members and the club share
  a timezone; revisit if the app is white-labelled for another zone.
- Committee run/venue/series writes are online-only, like posts (D16). A series
  write is followed by a sessions refresh because the server regenerates them.

**D20 — A group is optional pace + optional distance + kind + text (2026-10-08).**
- There's no fixed list of group formats. A group has an optional pace (single or
  range), an optional distance, a `kind` and a description, so jog/walk, efforts,
  social runs and future formats need no schema change. See `data-model.md`.

**D21 — Distance and pace units are separate preferences, shown in the viewer's units (2026-10-08).**
- Members choose a pace unit and a distance unit (mi or km) independently.
- Values are stored as entered with their unit (extends D8). The API adds derived
  canonical values (sec/km, metres) for sorting and matching.

**D22 — Groups ride along with sessions; names come from a separate online plan call (2026-10-08).**
- Session payloads embed their groups, leaders and counts, so the existing `?since`
  sync and offline cache cover the Runs list and the roster.
- Attendee names and the committee gap view come from `GET …/plan`, which is never
  synced and checks permissions on every call (D13).

**D23 — Attendance writes are optimistic with a pending retry (2026-10-08).**
- "I'm coming" / "Not coming" update the local row first and retry on the next
  refresh, like inbox reads. Creating or editing groups, and role changes, stay
  online-only (D16, D19).

**D24 — The committee manages roles from the app (2026-10-08).**
- A members search and roles endpoint replaces the `app:member-role` shell command,
  since the host has no shell. Only an admin can grant `committee` or `admin`.

**D25 — Phase 4 app data layer: shared session store, attendance revert by GET (2026-10-08).**
- Group and attendance writes edit the cached session's `groupsJson` / `summaryJson`
  through one `SessionLocalStore` (counts are best effort; the next sessions refresh
  is authoritative). A sessions refresh without `groups`/`summary` keeps stored ones.
- Pending attendance is re-applied over the server `summary` after each refresh so it
  doesn't flicker back. A 4xx on the PUT (409 `session_cancelled`/`session_past`, 422)
  drops the pending row and reverts to the server's row (`GET …/attendance`); network
  errors and 5xx keep it pending.
- Converted paces round to the nearest second: 9:00/mi is 5:36/km (not 5:35),
  matching the API's `paceFromSPerKm`.
- The running-preferences repository is `RunPreferencesRepository`, to stay apart
  from the notification `PreferencesRepository` in `features/settings`.

**D26 — Group screens: read-only once a run is closed, status changes keep the per-run pace (2026-10-09).**
- A cancelled or finished run (`endsAt` before the device clock) shows its groups
  read-only: no respond, join, lead, edit or delete controls. The server still
  answers 409 (`session_cancelled` / `session_past`), which the app maps to text.
- The server clears the per-run pace when an attendance `PUT` omits it, so every
  response change (status, join, leave) re-sends the pace override already stored
  locally. Only the pace sheet changes it ("Use my usual pace" sends none).
- Ordinary members can't turn off "I will lead this group" (the server 403s a
  leaderless create). Committee, admin and the session coordinator can; "Add route"
  opens the editor as a `route` with it off. (D86 narrows where the switch shows.) The `leader` badge grants nothing here (D12).

**D27 — Phase 4c-2 choices (2026-10-10).**
- **Last group per series** is kept in the per-account Drift DB's small key/value table
  (`sync_cursors`, keys `lastGroup:<club>:<seriesId|any>`), not secure storage: `AccountStore`
  flags are booleans, and the DB is already one per account. No schema bump.
- **Pace spread** counts a range once, in the bucket of its middle (30 s/mi or 20 s/km); the
  "usually a-b" text uses the outer ends. Spread shows on each group in the "Who's coming"
  section, and on each route card in `routes` runs.
- **Gaps:** a member is covered when some group's pace band overlaps theirs (single paces use the
  shared tolerance); groups with no pace cover nobody; members with no pace are listed apart.
- **Coordinator** is sent in the session PATCH only when changed (`null` clears it). Members and
  roles: committee toggles `leader`; only admins can toggle `committee`/`admin`.

**D28 — Committee coverage view is based on led groups, not RSVPs (2026-10-11).**
The committee's "Group coverage" card (`buildCoverage`, `logic/coverage_report.dart`) looks only at
groups that have at least one confirmed leader. A single pace covers the pace plus or minus 15 s/km, a
range covers its ends; the axis defaults to 7:00-12:00/mi (4:15-7:30/km) and widens for groups outside it.
Gaps of 20 s/km or more are listed ("No led group between 8:45 and 9:30/mi", "Nobody leading slower than
10:30/mi"); a led no-pace jog/walk group turns the slow-end gap into information. Why: members RSVP late,
while the committee plans leaders weeks ahead, so RSVPs can't be the signal. The old attendee-based gap
report stays as a secondary section ("People coming with no matching group"), shown only when there is
something to say. Groups with no leader are listed as "Needs a leader" and cover nothing. The card is
hidden for Sunday `routes` runs.

**D29 — Pace is entered as separate minutes and seconds fields (2026-10-11).**
The Android number pad has no colon, so `m:ss` can't be typed. `PaceTimeField` (two digits-only boxes,
"min" and optional "sec", seconds 0-59, empty seconds = 0) is used for the group editor, the per-run pace
sheet and the profile's usual pace. `PaceTimeController.text` gives `m:ss`, so `Pace.parse` and
`checkPaceFields` (3:00-30:00, slow not faster than fast) are unchanged. Switching min/mile and min/km
converts what is already typed.

**D30 — Leaders attend their own group (2026-10-11).** (The last sentence, withdrawing keeps you going in the group, is superseded by D109.)
Mirrors the API (`docs/api-contract.md`, "leaders attend their own group"): creating a group with `lead`
or joining as a leader also marks the caller going in it, and withdrawing as a leader keeps them going.
`GroupsRepository` writes the local `MyAttendance` row and the cached summary straight away (a per-run
pace override is kept; the merged group already carries the server's counts). A group you lead has no
"Join this group" / "Leave group"; the card says "You're leading this group". After stepping down you
are an ordinary member of it (Leave available). Deleting a group you just created leaves you going,
unassigned, as on the server. Superseded by D109: stepping down now removes you from the group.

**D31 — Notification triggers use delayed queue jobs and one 10-minute command, not an events table (2026-10-10).**
Things that happen because of a request (group added, leader withdraws, run changed) call
`NotificationService` directly, or queue a delayed job on the `notifications` queue when a pause helps (group
match: 3 minutes, so a typo fix doesn't notify twice). Things that happen because time passes (reminders,
leaders-needed) are found by `app:send-reminders` every 10 minutes. Idempotency comes from dedupe keys (D33),
so the command can run late or twice. Why: the host only has cron + the DB queue; an outbox table would add a
moving part for no benefit.

**D32 — Reminders carry action buttons through unauthenticated one-time-per-notification tokens (2026-10-10).**
Android only shows buttons on notifications the app builds itself, so reminders are data-only messages, and the
background isolate can't easily run Auth0. Each such notification stores a random `actionToken`; the isolate
POSTs `{notificationId, token, action}` to `/app/notification-actions`. The token is scoped to one member, one
run and two answers, is only sent in the push (never the inbox API), and the endpoint refuses finished runs.
Trade-off: if an OEM kills background delivery the reminder may not appear; `FCM_ACTION_BUTTONS=false` turns
the buttons off server-side and falls back to plain notifications. Leaders get no "Not coming" button; they
step down in the app (D30 ties attendance to leading).

**D33 — Dedupe keys collapse repeats; same news is never pushed twice (2026-10-10).**
`dedupe_key` per member (see the table in api-contract.md). Identical content = no-op; `skip` keeps the first
row; `replace` updates it in place and re-pushes (always for locked categories, at most hourly otherwise). A
cancel followed quickly by a restore must both push, so `session_change` is locked and replaces.

**D34 — Daily push cap is rolling 24 h and counts only capped categories (2026-10-10).**
Default 6, member-configurable (3/6/12/none). The inbox row is always written, so nothing is lost, only the
buzz. Locked categories (`my_group_changes`) and `important` posts ignore the cap and don't count towards it.

**D35 — Reminders: auto-audience from recent attendance, per-series override, no per-weekday setting (2026-10-10).**
"Never Wednesdays" = turn off the Wednesday series (`member_series_prefs`), so one mechanism covers series and
weekday and survives a series moving day. `auto` reminds anyone who was `going` at one of the last 6 ended runs
of the series, plus everyone going to this run. Timing is fixed per club-local rule (morning of, or the evening
before for runs before 11:00); a per-member lead time is backlog.

**D36 — Leader withdrawal asks the group, then the leaders (2026-10-10).**
The group stays `needs_leader` (existing behaviour). Its attendees get a locked `my_group_changes` notice that
the group needs someone to step in; `leader`-role members whose pace fits (or with no pace set) get
`leaders_needed`. Anyone can lead (D12) so the route opens the run, where Join as leader already exists.

**D37 — First real FCM send is checked with `app:send-test-push` (2026-10-10).**
FCM auth/sending has only been tested against mocks. The command sends a real push from the host console and
reports devices and result, before any Phase 5 behaviour depends on it.

**D38 — App side of action notifications (2026-10-10).**
- A push is an action notification only if it is data-only (no `notification` block), has title, body,
  notification id and token, and at least one known action (`going`, `not_going`). Anything else is left to the OS.
- The local notification id is FNV-1a of `tag` (fallback notification id), not `String.hashCode`, which isn't
  promised to match across isolates or runs, so a re-sent reminder replaces the one on screen.
- Buttons use `showsUserInterface: false` and `cancelNotification: false`; the answer is POSTed from the
  background isolate with a bare Dio (15 s timeouts, no Auth0, no Riverpod), then the same notification slot is
  replaced by a short confirmation that clears itself after 15 s. 404/409 and network failures say so and ask the
  user to open the app. The notification payload keeps the token, so tapping the confirmation still routes.
- A foreground answer also refreshes sessions for the active account; a background answer waits for the next sync.
- Settings are online-only like the category switches (no cache); each control saves immediately, reverts with a
  snackbar on failure, and merges the server's reply per control so quick changes don't overwrite each other.

**D39 — A group's thread is a shared chat for everyone in that group, names shown as first name + initial (2026-10-12).**
Roadmap wording was "between its leader(s) and attendees". Making attendee messages visible only to leaders would
make it a help desk rather than a chat, and leaders already see attendee names (D13). **This amends D13:** people who post in a group chat are named to the others in that group; members who never post stay anonymous (counts only). Being in the group means
being in its chat; members can leave the group to leave the chat. Not shown: email, DOB, anything beyond first
name + surname initial. Committee/admin can read, post and moderate every thread (needed for moderation; said
plainly in the app).

**D40 — One thread per run-group, closes 12 h after the run (2026-10-12).**
Groups are per run, so threads are naturally short-lived; the main use is "running 5 minutes late", "meet at the
back car park", "who's got the route?". Closing stops late-night noise and stale threads; reading stays.

**D41 — Delete, no edit (2026-10-12).**
Messages can be deleted (soft, tombstone synced through `since`) by the author, the group's leaders, the
coordinator and committee/admin. Editing is left out: it would need an edited marker, a second sync path and
notification rules for little gain in short threads.

**D42 — Delivery is poll-when-open plus push, no websockets (2026-10-12).**
Unchanged from the original plan: `?since=` delta every 8 s while the screen is open and an immediate refresh on
a push for that group. Pushes collapse per thread (dedupe key, 5 min re-push window) so a lively thread is one
inbox row and at most one buzz per 5 minutes; mute is per thread and per member, enforced on the server.

**D43 — Messages are offline-first with a local outbox (2026-10-12).**
Same pattern as attendance (D23): client-generated UUID ids make retries idempotent; pending/failed state is
local only. Chat is the first feature where an optimistic write can be refused permanently (access lost, thread
closed), so failed messages stay visible with Retry/Delete instead of vanishing.

**D44 — Moderation is deletion + server-side limits, no reporting flow yet (2026-10-12).**
20 messages/min/member, 1000 characters, plain text only (no links preview, no images, no mentions). A report
button and member muting/blocking are backlog; misbehaviour is dealt with by the committee outside the app (roles
screen can't remove members yet) while leaders can delete messages.

**D45 — Chat outbox rules and local copy of a thread (2026-10-12).**
- A send is stored `pending` and POSTed at once; offline, timeouts, 5xx and 408 keep it pending and it is re-POSTed
  (same id, so idempotent) on the next refresh/open, on app resume and by the 8 s poll. Any other refusal
  (403, 404, 409, 422) makes it `failed` for good until the user taps Retry or deletes it. 429 stays pending but
  waits 20 s in memory before the next try, so a burst doesn't hammer the server.
- Local rows are the server's own once confirmed (including its `createdAt`, so ordering can shift by a moment).
  A tombstone for a message this device never had is dropped rather than shown as "Message deleted".
- When access is lost (403/404 on a refresh, or `GET /threads` no longer lists it) the thread's messages, state and
  cursor are deleted from the device.
- Delete, mute and "mark read" are not queued: delete and mute need a connection (delete shows the tombstone at
  once and reverts on failure); mark read zeroes the local count and retries on the next poll if offline.

**D46 — Open chat is a provider; polling is a screen Timer (2026-10-12).**
`openChatGroupIdProvider` holds the group whose chat screen is mounted. `PushService` reads it so a foreground
push for that group shows no notification and refreshes the thread straight away (other pushes also refresh
`GET /threads` for the unread dots). The 8 s poll is a `Timer.periodic` owned by the screen (cancelled on dispose,
interval injectable for tests), not a provider, so it only runs while the screen is visible. The "everyone can
see your name" line is dismissed once per account, stored in the small key/value table (like D27).

**D47 — A run's end time is optional; internally it still ends after 3 hours (2026-10-13).**
Many runs have no fixed end because the groups vary. Making `ends_at` nullable would touch every "is it over"
query (reminders, chat closing, past checks, generator). Instead `ends_at` stays filled (start + 3 h) and
`sessions.has_end` hides it in payloads. The app shows only the start time when there is no end.

**D48 — Times are shown 12-hour, `7pm` / `7:30pm` (2026-10-13).**
The club writes times this way. APIs keep 24-hour `HH:MM`; only display (app and server-written notification
text) changes. One formatter per side, used everywhere.

**D49 — Series images are URLs, not uploads (2026-10-13).**
Committee pastes an image URL (from the website's club-runs page) into the series, or sets the column in the
database. The app caches the image on the device (`cached_network_image`). The image appears full width above
each run card and is hidden when unset. No upload, storage or moderation to build; a broken URL just hides the
image.

**D50 — A "pick your pace group" nudge exists for people who said they're coming but chose no group (2026-10-13).**
Three touch points: the app asks right after "I'm coming" when groups exist; `app:send-reminders` nudges 3 hours
before the start (not before 08:00); and a group added after that point nudges people with no group and no usual
pace (people with a usual pace already get `group_matches`). Nothing is sent when no groups exist yet; the run
page says groups will be confirmed at the start.

**D51 — Palette: club orange `#f89829` on black/white/grey, no browns (2026-10-13).**
Primary is the website's orange; the old brown tones become neutral black-to-grey. Orange is for actions and
highlights, not large fills.

**D52 — Drift schema v6; `sessions.endsAt` stays non-null, `localEndTime` is the "has an end" flag (2026-10-13).**
v6 makes `session_series.duration_min` and `sessions.local_end_time` nullable and adds `image_url` to both. SQLite
cannot relax NOT NULL in place, so the migration uses `alterTable(TableMigration(...))` (rebuild and copy rows),
only for databases from v3 up (older ones create the tables in the v6 shape). The `endsAt` instant is not made
nullable: when the payload has none, the app stores start + 3 h (the same rule as the server, D47), so every
"has it finished" check (roster, group access) keeps working untouched. Display and editors use `localEndTime`
(null = no end time) and `durationMin` (null = none).

**D53 — Series images: `cached_network_image`, and the banner only takes space once it has loaded (2026-10-13).**
`SeriesImage` resolves the image itself and renders nothing while loading, when the URL is empty, and if loading
fails, so a dead link never leaves a placeholder, error icon or gap (the cost: the card grows when a good image
arrives, softened by a 250 ms fade). It sits flush inside the top of each run card and at the top of the run page
(150 px, cover). The `ImageProvider` comes from `seriesImageFactoryProvider` so tests use an in-memory image and no
HTTP. The editor validates http/https and 500 characters like the server and previews the URL when the field
loses focus.

**D54 — Palette is a hand-written `ColorScheme`, orange text uses a darker shade (2026-10-13).**
`ColorScheme.fromSeed` from orange tints every surface brown, so light and dark schemes are spelled out (neutral
greys, `#f89829` primary with black on-primary). Orange on white is only 2.2:1, so text buttons and focused field
borders use `#b56406` in the light theme (orange itself in dark); orange fills (buttons, selected nav item,
segmented buttons, badges, switches) carry black text. A test checks the contrast pairs and that surfaces are
neutral.

**D55 — App half of the pick-a-group nudge: ask once per run per device, only after "I'm coming" (2026-10-13).**
Right after "I'm coming" on the run page (not for the notification buttons, not after Maybe or "Can't come") the app
offers a "Pick your pace group?" sheet (heading, label, leaders, going count, Join; "I'll decide on the day"). It is
skipped when the viewer leads a group or is already in one, when the run is closed, and for `routes` runs. Only
`active` groups count (as on the server, D50): with none the app shows a snackbar instead ("Pace groups are
confirmed at the start...") and no flag is stored, so a later group can still prompt. The flag
`pickGroupPrompted:<club>:<session>` is written *before* the sheet opens, so swiping it away counts as asked and
toggling the answer never nags. It lives in the small key/value table (`SmallKvStore`, like D27), so it is per
account and device, and the server's timed push (D50) still reaches people who dismissed it. The run page also
shows a muted note under the group list on open `paced`/`single` runs, even when the list is empty, and the
runs list hides "You're going" for a leader (leading already implies going, D30).

**D56 — Lead a run: a remembered weekday filter that never hides a run you lead (2026-10-13).** (Replaced by the server-held "Days I may lead", D107/D111; runs you lead still always show.)
Chips are built only from weekdays present in the loaded runs and appear only when there are two or more (one
weekday has nothing to filter). Selection is multi-select, none = all, stored per club as `leadRosterDays:<club>`
(`1,3`, Monday = 1) in the key/value table. A remembered day that no longer occurs is ignored for filtering (so a
stale filter can't empty the page) but stays stored. Runs where the viewer leads a group are always shown, and
a small "N runs hidden by your day filter" note appears when the filter hides any, so the filter is never
silently losing information. "Show all" clears the selection and the stored key.

**D57 — "Can't attend" on the roster has no Undo because the API cannot clear an answer (2026-10-13).**
The attendance API only stores `going`, `maybe` or `not_going` (there is no delete), so a true "back to no answer"
is impossible, and quietly restoring `maybe` or `going` would tell the club something the member never said. The
card therefore collapses to one line (date and time, "Can't attend") in its normal chronological place, with a
**Change** button that opens the run page, where the three-way answer can be set again. The answer itself is the
normal optimistic write (D23). Not offered on runs you lead (stepping down is a separate action, D30).

**D58 — A group with no pace needs a label, in the editor and on the card (2026-10-13).**
The editor mirrors the server rule: with pace None the label is required ("Label (required)", inline "Add a
label, e.g. Jog/walk or Efforts"); with a pace it stays optional. A 422 with an `errors.label` entry is also shown on
the field (`ApiException.fieldErrors` keeps the first message per field). The card has one heading: `pace · distance`
with the label as a subtitle, or, with no pace, the label (then the distance) as the heading; the generic "Pace
group" text is gone (a kind name only appears as a fallback for old unlabelled groups). "Step down" sits beside
"You're leading this group" as a small error-coloured outlined button, distinct from the tonal Join.

**D59 — Photo and bio are visible to club members once set; goals are private unless shared (2026-10-12).**
Photo and bio exist only because the member chose to add them (the edit screen says who sees them), so no second
switch. Goals are personal, so they carry an explicit "Share my goals with other members" checkbox, off by
default. Everything is club-members-only and stays inside the app. Name stays first name + surname initial
everywhere (same as chat, D39); the profile page adds no further identifying data.

**D60 — Photos are stored in the database as a small JPEG, served by a signed link (2026-10-12).**
The host is shared PHP hosting deployed by FTP: no object storage, unknown file permissions, no guaranteed image
library. A 512 px JPEG (about 40 KB) in a `mediumblob` table is backed up with the database and needs no
filesystem. The phone crops, resizes and re-encodes (so location metadata is stripped); the server only validates
(JPEG magic bytes, size, dimensions). Images are fetched through an HMAC-signed, versioned link that needs no
auth header, so a normal cached image widget can load it; a new upload changes the version and kills old links.

**D61 — Member cards are one small full list, not per-member lookups (2026-10-12).**
`GET /member-cards` returns every member who is already shown by name (leaders, coordinators, committee) or has a
photo/bio, as `{id, name, photo, roles}`. The app keeps it in a Drift table and draws avatars and names from it
everywhere, so cached session and chat payloads never go stale when someone changes their photo. A full list
(tens of KB) is cheaper than a delta protocol with tombstones for this size of club.

**D62 — Tapping a name opens a pushed profile page, never a tab switch (2026-10-12).**
`/members/:memberId` is pushed onto the current navigation stack so the back button returns to the run, chat or
group the viewer came from. Names stay compact (thumbnail + name) in cards and chat; the page holds the detail.

**D63 — Committee can clear someone's photo, bio and goals (2026-10-12).**
Moderation without a reporting flow yet (D44). One action clears all three; the member can add new content again.

**D64 — Member cards and profiles live in their own `members` feature and two small tables (2026-10-12).**
`MemberCards` (one row per `GET /member-cards` item, a club's rows replaced in one transaction on every refresh) and
`MemberProfiles` (last fetched JSON per member, so the profile page works offline). The caller's own editable card is
the same table under the fixed key `me`. Avatars read one `memberCardsProvider` map with `.select` per member, so
a list of 50 names opens one query, not 50. Cards refresh at app start (AppShell), on resume, after an account switch
and after the caller saves anything; failures other than an expired session are ignored (cached cards keep working).

**D65 — Avatars never show a spinner; initials are the base layer (2026-10-12).**
`AvatarCircle` draws initials on a neutral grey disc, and the photo (cached by `CachedNetworkImage`, decoded at
display size) fades in on top only once loaded. A missing, slow or failed photo leaves the initials, so layout never
moves. A photo already in memory appears with no fade. Initials: first letter of the first and last word of the name
(`Sam B.` -> `SB`). A `null` member id renders the same avatar and name without a tap.

**D66 — Profile photos are processed on the phone, rejected under 64 px, upscaled under 512 px (2026-10-12).**
`processProfilePhoto` (pure Dart `image` package, run through `compute`): decode, bake the EXIF rotation, centre-crop
to a square, resize to 512 px, JPEG quality 85. No EXIF is written, so location data is stripped. The picker is not
asked to downscale (`maxWidth`), to avoid platform-specific double rotation. Input under 64 px on the short side (the
server minimum) or that cannot be decoded throws a `ProfilePhotoException` with a readable message; 64-511 px photos
are upscaled so the upload is always exactly 512 x 512. The member sees a round preview and confirms before upload.

**D67 — Profile page and card editor writes are online-only; reads fall back to the cache (2026-10-12).**
No outbox for these (they are rare and the server validates). `fetchProfile`/`fetchMine` return the cached copy
flagged `fromCache` on a network failure (the screen shows an offline banner), or throw `MemberOfflineException` when
there is nothing cached. A 404 for a member deletes their cached profile and shows "This member isn't available".
Saves send only the keys that changed (an empty string clears a field); 422 `errors.bio` / `errors.goals` appear under
the field. The editor keeps unsaved text if a background fetch lands meanwhile. There is no unsaved-changes prompt on
leaving the editor (the codebase has no `PopScope` pattern yet).

**D68 — `/members/:memberId` is a top-level route on the root navigator (2026-10-12).**
`context.push('/members/<id>')` from any tab, chat or editor lays the page above the bottom bar and Back returns to
where you were. If the page is opened with nothing to go back to (a deep link), the app bar shows a Home button
instead of a back arrow. Committee/admin get "Remove photo and bio" (with a confirm dialog) on other members only.

**D69 — Where a member's name is a link, where it is only an avatar, and where it stays plain text (2026-10-12).**
Avatar + tappable name (`MemberLink`, pushes `/members/:id`) on: group card and leader roster card leaders
(`LeadersLine`, a `Wrap` of 24 px avatar + name + role tag so several leaders flow onto a second line on a 320 px
phone), the run page coordinator row, who's-coming attendee rows (still only where the plan already carries names) and
the update post detail author. Avatar only (the row's own tap action wins): committee/coordinator member search rows
and the roles sheet header. Plain text on purpose: the pick-a-group sheet and coverage card (whole row is one tap
target or a dense summary), the threads list "last author", and the update list card (whole card opens the post). A
person without a member id (older cached payloads) renders as the same avatar + text with no tap.

**D70 — Chat shows the avatar on the LAST bubble of a run, names on every bubble (2026-10-12).**
For others' messages a 28 px avatar sits bottom-left of a run of consecutive messages from the same author (the last
one, like WhatsApp/Messenger; a day heading ends a run, a missing author id always shows one). Earlier bubbles in the
run get an empty slot of the same width so bubbles line up. The author name stays above every bubble (existing
behaviour, kept so a bubble read alone still says who wrote it) as a tappable `MemberNameLink` (name only, no second
avatar) next to the role badge. Own messages are unchanged (no avatar, no name). The rule lives in the pure function
`endsAuthorRun` over the reversed list, so pending/failed rows and the reverse ListView are untouched.

**D71 — Android release path: upload key + Play App Signing, Firebase App Distribution for betas (2026-10-12).**
Release builds are signed with an upload keystore (`android/upload-keystore.jks` + `android/key.properties`, both
git-ignored and backed up by the owner). On Google Play, Play App Signing holds the real signing key, so a lost
upload key can be reset by Google. Until Play approval and the 12-tester closed test, betas go through Firebase
App Distribution (same APK/AAB, tester group, email invite). Debug-signed and release-signed builds can't update
each other in place: moving to the release key needs one uninstall.

**D72 — "Delete my account" removes the app's data, not the website login (2026-10-12).**
The Auth0 login is shared with the website, and the membership/athlete records belong to the club (EA
registration). The app deletes what the app itself holds for the member: logins linked to the app, devices,
notifications and preferences, profile/photo/goals, chat messages, attendance, leader sign-ups, and the
club-member link (the member must link again to come back). Authored club posts stay but lose their author. The
screen says so plainly and points to the club for the website account and membership. The last admin can't
delete (409) so the club is never left without one. Why: satisfies the Play/App Store in-app deletion rules
without needing Auth0 Management API credentials on the host.

**D73 — Store text and policies are drafted in `docs/store/` and owned by the club (2026-10-12).**
Privacy policy draft, Play data-safety answers, listing text and a release checklist live next to the code so
they stay true to what the app does. The owner publishes the policy page on bpj.org.uk and fills in the Play
Console forms; the docs say exactly what to enter.

**D74 — parkrun and race events reuse sessions and groups, they don't add a second schema (2026-10-12).**
A series gets a `type`: `run` (today) or `events`. An events series (e.g. a Saturday "parkrun") has an optional
venue and produces ordinary weekly sessions, so the Runs tab shows one card per Saturday. Its **groups are the
individual events** (kind `event`, with a name such as "Worcester parkrun", optional place), so chat (Phase 6),
attendance ("I'm going", with a `group_id`) and counts already work. A club-managed `event_locations` list (manual
import of the public parkrun events file at first) feeds the "add an event" picker; groups are created from it.
Pace, leaders and coverage rules are switched off for events sessions, and no group-match, pick-a-group or
leaders-needed notifications are sent for them. The card summary counts people and events ("3 going to 2 events")
instead of groups. Races are ad-hoc events sessions, with or without pace groups. Built in Phase 8.

**D75 — Account deletion screen: a real route, rows emptied not file deleted, and the same sign-out as normal (2026-10-12).**
Profile > "About & privacy" (`/profile/about`) holds the version, privacy policy, club website, contact link and a
"Danger zone" with "Delete my account", which opens `/profile/about/delete` (a go_router route on the root navigator,
so the sign-out redirect replaces it cleanly). The red button needs the exact, case-sensitive text `DELETE`, and Back is
blocked while the request runs. Nothing local changes until the server answers 204. Then the app empties this
account's Drift rows (`clearAll`, while the connection is open; deleting a SQLite file under an open connection is
unsafe, and an empty file holds nothing personal), empties the downloaded-image cache (member photos), and calls the
normal `AccountsController.remove` (push token, credentials, Auth0 browser session if it was the last account). With a
second account on the device the app switches to it. 409 `last_admin` shows the server's message inline; offline says
a connection is needed; `session_expired` uses the usual expiry handler; other errors show a message and "Try again".

**D76 — Events and races are group modes, not a new series type (2026-10-13). Amends D74.**
The design in D74 holds, but the switch is the existing `groupMode` (new values `events` and `race`) rather than a
separate `type` column: both columns are plain strings, every screen already branches on the mode, and nothing in
the schema changes for sessions or series. `session_groups` gains only a nullable `location_id`.

**D77 — Event attendees can see each other's names inside their own event (2026-10-13).**
Car sharing needs names, and the chat already reveals the names of people who post (D39). Inside an `events`
group, members who are going/maybe to that event see the others going to the same event; nobody sees names for
events they are not in. Leaders/coordinator/committee keep their existing view. Counts stay public.

**D78 — Any member can add an event; parkrun locations come from an import, races from members (2026-10-13).**
Anyone can add an event to a Saturday (that is the point: tourism), from the club's location list or as free
text. The list of parkruns is imported by the committee from parkrun's public events file with a host command
(manual to start, a scheduled feed later). Members can add `race`/`other` locations themselves; `parkrun`
locations are committee-only so the official list stays clean. Duplicates on the same day collapse onto one
group per location, so there is one chat per parkrun per Saturday.

**D79 — No pace-group machinery for events (2026-10-13).**
Pace, leaders, coverage, group-match, pick-a-group and leaders-needed all stay off for `events`/`race` sessions.
Reminders only go to people who are going (the "usually comes" rule would remind the whole club about a parkrun
most of them will not run). The Lead-a-run roster skips these sessions.

**D80 — Event modes are guarded by one small helper file (2026-10-13).**
`features/runs/logic/run_modes.dart` answers "is this events/race?" (`isEventsMode`, `isRaceMode`, `isEventLikeMode`)
and "does this run use pace groups?" (`usesPaceGroups`: paced, single, open only; routes, events and race are false).
Screens ask the question instead of comparing mode strings, so the pace note, pick-a-group prompt, coverage card,
per-group pace spread and the Lead-a-run roster each have a one-line guard. The series editor offers `seriesGroupModes`
(everything but `race`, which the server rejects); the ad-hoc editor offers `adHocGroupModes`. The editors themselves
have no pace controls, so there was nothing to hide there (the group editor is the 8c agent's).

**D81 — Event locations keep tombstones, and the picker reads recents from cached sessions (2026-10-13).**
Unlike venues, `event_locations` rows deleted on the server stay in Drift with `deletedAt` set and are filtered out of
the live stream, which keeps the `?since=` merge a plain upsert (about 800 rows are written in one batch). "Recently
used by the club" is computed from the cached sessions' embedded groups (event groups with a `locationId`, one count per
run, cancelled runs ignored, last 12 weeks). The session cache is pruned after about two weeks (D17), so in practice it
ranks the last fortnight plus the runs already scheduled; that is enough to float this month's tourist parkruns to the
top and works offline. A separate kv "recents" store was not worth a second source of truth.

**D82 — The picker returns a pick, it does not write the group (2026-10-13).**
`showEventPicker` returns `EventPick(locationId?, name)`; the run page adds the group (`locationId` or free-text
`label`) and joins it, because that is a group write with its own errors. The only write the picker does itself is
"Save for next time" under "Other...", which POSTs a `race` (default) or `other` location online-only and returns it as a
normal pick; a failure keeps the sheet open with the reason and a hint to untick the box. Locations already on the run
are greyed with "Already added" but stay selectable (choosing one just joins it, as the server de-duplicates, D78).

**D83 — Event locations are managed from the Profile tab; add/edit is a bottom sheet (2026-10-13).**
The committee screen is `/profile/event-locations`, linked from the Profile tab next to "Members and roles" for
committee/admin (hidden otherwise; the screen also refuses non-committee). The list is a `ListView.builder` with a
search box and parkrun/Race/Other filter chips; add, edit and delete share one bottom-sheet form, so there are no
extra routes. Kind defaults to `race` for a new location (the import fills parkruns).
**D84 — The Runs card for events and races counts people and events, never groups (2026-10-14).**
The line is a pure function of the groups embedded in the session and the caller's `summary`
(`features/events/logic/event_summary.dart`). "Going" is the larger of `summary.goingCount` and the sum of the event
groups' going counts (so people who are going but have not picked an event still count, and a summary a moment behind the
groups never shows less than the groups). "Events" counts only event groups someone is going to, so an empty event does
not inflate it: "3 going to 2 events", "1 going to 1 event", "1 going" when nobody picked an event. With nobody going it
asks the question the series is for: "No one has picked a parkrun yet" (events) or "No one has said they're going yet"
(race). Your own chip becomes "You're going to {event}" when you are in an event group; on a race it stays "You're
going" (the race is the event). The "You're leading" chip never shows for these modes.

**D85 — Leaving an event goes back to "going, no event"; "Can't come" is the run-level answer (2026-10-14).**
"Leave" on an event card mirrors "Leave group" on pace groups exactly: `going` with no `groupId`, so you are still
counted and still get reminders, and the page shows "N going, event not chosen yet". The way to opt out is the run-level
"Can't come" (the same `RespondCard` the other runs use), which is kept on the events page for that reason. A race has no
event to leave, so its card has **I'm going** (going plus the race group's id, so you land in its chat) and **Can't go**
(`not_going`); the run-level card is hidden on an open race and only appears to explain a cancelled or finished one. If
the race group were missing from the cache, the card falls back to a plain going / not going with the run-level count.
Names under "Also going" come from the plan only while you are in that event (or you manage the run), so a plan cached
before you left an event never keeps showing its people (D77). The event note editor and "Remove event" live on the card
(creator, committee, coordinator), and the pace group editor refuses event and race runs.

**D86 — "I will lead this group" is only asked on an "add a group" action by someone who may go leaderless (2026-10-15).**
The editor has an intent (`GroupIntent`, route query `?intent=lead|add`, default `lead`). **Lead** actions ("Offer to
lead" on the roster, "Lead a group" on the run page) never show the switch: whoever presses them leads what they create
(`lead: true`), committee included. **Add** actions ("Add a group" on the coverage card, "Add route") show it only when
`canCreateLeaderless` is true (committee, admin, or the run's coordinator, the server's rule); "Add a group" starts it
on, "Add route" off (`&lead=false` only sets that start state). Anyone else arriving with `intent=add` still creates a
group they lead, because the server would 403 a leaderless one. The old always-visible switch locked on for members read
as noise ("You lead the groups you create"). "Same as last time" and the editor pre-fill follow the lead intent only
(an added group is not "mine"); editing an existing group is unchanged. The router and the tests build the screen with
`GroupEditorScreen.fromUri`, so the query parameters have one meaning.

**D87 — One clock provider; labels and filters watch it, nothing caches "today" (2026-10-15).**
`core/util/clock.dart` holds `clockProvider` (the injectable `DateTime Function()`; tests override it, replacing the old
`groupsClockProvider`), `clubTodayProvider` (the club-local date; recomputed by a one-shot `Timer` at the next local
midnight and on every app resume; equality is by date, so watchers rebuild only when the day changes) and `nowProvider`
(auto-disposed; ticks every minute and on resume, for "5 minutes ago" and "is this run still open"). The stale "Today"
had two causes: `RunsScreen` computed `DateTime.now()` in `build` and `watchUpcomingSessions` baked "today" into a Drift
query when the stream was created (and the provider family is never disposed), so past runs stayed in the list after
midnight. The query now takes `since` from `clubTodayProvider`, so the stream restarts on a new day. Day labels, grouping,
the roster, chat day headers and thread dates watch `clubTodayProvider`; open/closed checks, `relativeTime` labels and
post pin expiry watch `nowProvider`. Cached rows are untouched (offline-first); only labels and filters recompute. Time
zone: the app has no club zone setting, so "today" is the device's local date, as `localDateString` always was; it is
documented there. Left as is on purpose: `todayString()` (the default date of the run editors, read once when the form
opens), repository `_now` clocks (they stamp writes and prune old rows).

**D88 — The usual pace is saved with an explicit Save; units save at once (2026-10-15).**
The "usual pace set in Profile still says no pace" report traced to the form, not the stores: `RunPreferencesCard` kept
the typed numbers in local widget state with one generic Save at the bottom of the card, and the shell's `IndexedStack`
keeps the Profile tab alive, so typed-but-unsaved numbers looked saved when the tab was revisited while the PUT had never
been sent and the Drift row (the single source every screen watches via `runPreferencesProvider`) was unchanged. Now the
usual-pace section has its own **Save**, enabled only when the pace is valid (3:00-30:00, slow end not faster) and
different from the stored one, with "Not saved yet", a "Saved" check, and server or offline errors shown inline (typed
numbers are kept). **Clear** removes a stored pace straight away. The pace and distance units save as soon as they are
tapped (a unit change also sends the stored range converted, because the server clears a range when only the unit
changes) and revert with a snackbar if the PUT fails. Saving is online-only, as before (there is no outbox for
preferences); a successful save also invalidates the cached plan loads, so an open "Who's coming" refetches and shows
the new pace.

**D89 — The pace line in "Are you coming?" says which pace the club sees (2026-10-15).**
`MyPaceTile` shows one of: **Usual pace: 9:00-9:30/mi** + "Change for this run" (a usual pace is saved, none for this
run); **Running at 9:30/mi this run** + "Change" (a pace was set for this run); **No usual pace set** + "Set your usual
pace" (`context.go('/profile')`; the pace boxes are on the Profile tab) + "Set pace for this run". Paces are in the
viewer's units (the stored unit in brackets when it differs). Nothing shows after "Can't come", and none of it shows on
event and race runs (D84, D85). The usual pace comes from `runPreferencesProvider`, so a pace saved on the Profile tab
appears here at once. The sheet keeps "Use my usual pace" for going back.

**D90 — Club standards are one cached JSON document, revalidated with the ETag (2026-10-15).**
`standards_cache` (schema v9) holds one row per club: the response body as JSON text, the `ETag` and `fetchedAt`. The
table is small, read as a whole and never queried by column, so normalising it into Drift tables would only add
migrations. `StandardsRepository.watch` parses the row into `StandardsData` (tolerant DTOs: `distanceM` may be an int or a
double, missing optional fields get defaults, an item with neither `time` nor `timeS` is dropped). `refresh` sends
`If-None-Match`; a 304 keeps the body and only moves `fetchedAt` (dio treats 304 as an error unless `validateStatus`
allows it), a 200 replaces body and tag. It refreshes when the screen opens, on pull-to-refresh and on app resume while
the screen is open (the screen is a `WidgetsBindingObserver`, not the shell, because nothing else needs this data). The
ETag differs per caller (it covers `mine`), which is fine: there is one database per account.

**D91 — The screen opens on your own category every time; only the Time/Pace choice is remembered (2026-10-15).**
Gender (Men/Women) and the category chips come from the API; the default is `mine` (marked with a star, "Your category",
and "Showing your category"). Picking something else shows "Showing V50 women" with **Back to mine**, and the pick is
not saved: a member looking at a friend's table should not find the screen opening there next week. With `mine` null (no
date of birth or gender on the athlete record) it opens on Men SEN and says to link the membership to see your own
category. Going back to a gender lands on `mine` if it is that gender, else the open category if that gender has it, else
SEN. The Time/Pace choice is saved in the small key/value store (`standardsShowPace`, per account like the rest) and
the "How it works" card is open only the first time (`standardsIntroSeen`). Events with no standard for the open category
are hidden, not shown as blanks.

**D92 — Pace is shown instead of the time, in the viewer's pace unit, rounded to the nearest second (2026-10-15).**
Pace is `timeS / distanceM * unit.metres` (1609.344 per mile, 1000 per km) from `runPreferencesProvider`'s pace unit,
the same preference every other screen uses. It replaces the time in the tile (no second line) and the screen says
awards are based on finish times, not pace, as the website does. The website's pace pipe floors the seconds; we round.
Both give 25:48 over 5K as 8:18/mi (498.25 s) and 5:10/km (309.6 s). Race times use a small `formatRaceTime`
(`m:ss`, `h:mm:ss`), because `formatClock` is for times of day.

**D93 — Awards are tinted tiles in a 4-up row, or 2x2 on a narrow phone (2026-10-15).**
One card per event, one tile per award: bronze, silver, gold and platinum tints (pale with dark text in the light theme,
deep with pale text in the dark one; silver is neutral grey and platinum cool blue-grey so they stay apart) with a medal
icon. The tile grid is four columns when the card is at least 290 px wide and two otherwise, so 1:58:26 never has to shrink
on a 320 px phone, and the text scales down rather than overflowing at large font sizes. Claiming stays on the website:
the screen ends with "Claim an award on the website" (`https://bpj.org.uk/claim-award`, the same link the profile API
returns).

**D100 — An on-device diagnostics log that members can copy and send; what it holds and what it never holds (2026-10-17).**
Some users (a Samsung S25 after a Play update) ended up with every API-backed screen failing, nothing in the server or
Auth0 logs, and only Android's "Clear data" fixed it. Nobody can run `adb logcat`, so the app keeps its own short log
(`core/diagnostics/`): a ring buffer of the last 100 events in one small JSON file in the app support directory (no new
package). It is loaded lazily, written about 2 s after the last change, and a corrupt file is discarded silently.
Each entry is a UTC time, level, area (`api`, `auth`, `db`, `startup`, `ui`, `push`), a short message and optionally an
HTTP status and a path. Repeats of the same event within 60 s become a counter on one line. Logged: failed requests
(method, path WITHOUT its query string, status, a label such as timeout / network / bad certificate / server error),
the first success after a failure ("recovered"), `session_expired` and token-read failures, sign-in outcomes, uncaught
Flutter and async errors, providers that fail with a local error, database open / upgrade (from and to versions) /
failure, and one line per cold start (version and build). **Never logged:** request or response bodies, headers, tokens,
emails, names, login ids, query strings, record uuids (replaced by `:id`). Everything passes through `redact()`
(bearer tokens, JWTs, emails, `provider|id` logins and any 32+ character opaque string become `[redacted]`), and error
messages are only kept for a few types that never quote user content (a `FormatException` quotes its input, so only its
type is logged). The log leaves the phone only if the member taps "Copy report" and pastes it into an email
(`/profile/about/diagnostics`, linked from About & privacy as "Diagnostics"). The interceptor sits before the auth
interceptor so it sees raw errors; failures the auth interceptor creates itself are reported to it directly, because a
reject in `onRequest` skips every error interceptor. Why "Copy" and not "Share": `share_plus` is not a dependency.

**D101 — Self-heal for an unusable local database, and two manual resets (2026-10-17).**
*Automatic.* The router waits for `dbGuardProvider` before showing any screen for a signed-in user. It opens the active
account's database and reads the `memberships` table. If that throws, the failure is logged, the account's
`bpj_<hash>.sqlite` (plus `-wal`, `-shm`, `-journal`) is deleted after the connection is closed, and the check is tried
ONCE more. If it fails again the router shows `/recover`: "The app couldn't load its saved data", with **Reset and try
again** and **Copy diagnostics**, outside the shell and without opening the database. The cost is the cache plus any
unsent outbox rows; everything else is re-downloaded. The guard only ever touches the active account's file.
*Manual.* Diagnostics > **Reset local data** (confirm, then rows cleared if the file opens, file deleted, image cache
emptied, credentials kept, `/app/me` refresh re-run, back to `/`) is also offered from the "Couldn't load your
membership" screen. **Sign out and clear everything on this phone** does that for every account and then signs each
out with `AccountsController.sessionExpired`, the local-only removal: unlike `remove` it makes no push-token call to the
server and doesn't open the Auth0 browser sheet, which is the point when the app can't reach either. Deleting files under
an open SQLite connection is unsafe, so both paths invalidate and close `appDatabaseProvider` first
(`closeAndDeleteDatabase`). A database that never opened can throw when closed, so the provider swallows that error.

**D102 — "Something's not working" banner: when it appears (2026-10-17).**
`HealthTracker` (plain Dart, injectable clock) watches outcomes and `HealthBannerScope` shows a non-blocking banner at
the top of the app shell, "Something's not working. Tap to fix", which opens the diagnostics screen (it has a close
button). It trips when, inside 2 minutes, either (a) 4 or more consecutive requests fail with the SAME class, where the
classes are `5xx` and a local exception raised inside the HTTP layer, or (b) 3 or more local exceptions (TypeError,
database errors, uncaught errors, failed providers) are seen. It never trips for plain offline or timeouts (network
errors), for 401s (normal token renewal) or for ordinary 4xx answers (404, 409, 422 are the server working). A request
that succeeds resets (a); only a successful database open or Reset clears (b), because "the request worked but the
screen still can't read it" is exactly the failure this exists to catch.

**D103 — Token renewal can no longer wait on itself, and failures are classified (2026-10-17).**
*Root cause of "every API-backed screen fails, nothing in the server or Auth0 logs, Clear data fixes it".*
`AuthService.getValidAccessToken` shared one renewal per account with
`_renewals[sub] ??= _renew(..).whenComplete(() => _renewals.remove(sub))`. The callback returned the map entry, which is
the very future `whenComplete` was about to complete; `whenComplete` waits for a future its callback returns, so it waited
for itself and never settled. Any request that needed a renewal (stored access token expired or about to expire) hung
inside the auth interceptor before reaching the network, whether the renewal would have worked or not, and the
`session_expired` error that sends the user back to sign-in was never raised. When the account has no refresh token, no
Auth0 request is even attempted, so nothing shows in Auth0's logs either. It was present since the first release (`c197b6f`)
and shows after the stored access token has expired, which is why it looks like "after an update": the app is reopened
after a gap. Signing in again (or Clear data) stores a fresh token, which hides it for a day. Fix: `_renewShared` removes
the entry in a separate `then` with block bodies, and the Auth0 call has a 30 s timeout. Also: a renewal failing with no
answer (network, statusCode 0, Auth0 5xx or 429, timeout, or any local exception) now throws `AuthRenewalException`
(retryable, account kept, "offline" wording only for real network errors) instead of an anonymous error or a sign-out;
only a 4xx answer (invalid_grant and friends) or a missing refresh token ends the session. A new token that cannot be
saved is still used for the request. `AuthService` takes `isConfigured` so tests can drive the renewal path (the build-time
`AUTH0_CLIENT_ID` is empty in tests).

**D104 — Unreadable secure storage means "signed out", never an error state (2026-10-17).**
flutter_secure_storage on Android defaults to `resetOnError: true`: when an operation fails it wipes the store and
`result.success("Data has been reset")`, which the Dart side returns as the VALUE of a `read`; reads that fail outright
throw `PlatformException`. `AccountStore` now funnels every read through `_read`, which maps a throw, an empty value and
that sentinel to null; credentials or an accounts list that are valid JSON of the wrong shape (a `TypeError`, not the
`FormatException` the old code caught) are discarded and the key deleted; one bad account entry no longer hides the
others. `AccountsController._load` never ends in an `AsyncError` (the router waits on `/splash` for a value, so an error
there was a permanent spinner): it falls back to a signed-out state, which routes to `/sign-in`. We did not turn
`resetOnError` off: after a Keystore key change the data is unrecoverable and a clean reset is the right outcome.

**D105 — Real on-disk upgrade fixtures; every schema bump adds one (2026-10-17).**
Migrations had in-memory tests built from hand-written SQL. `test/fixtures/db/v4|v6|v7|v8.sqlite` are files written by the
OLD code of each shipped schema (commits `c197b6f`, `b65ca58`, `139282a`, `8cd3e50`, in throwaway `git worktree`s) with
every table populated (recipe: `test/fixtures/db/generate_fixture.dart.txt`). `test/db_upgrade_fixtures_test.dart` copies
each, opens it with the current `AppDatabase`, and checks the version, `integrity_check`, a `select` over every table,
row counts, a clean second open, and one `watch*` + `refresh()` of every repository. No commit ever wrote schemaVersion 5
(Phase 6 went straight to 6), so there is no `v5.sqlite`; v4 exercises the same `alterTable` steps. The last test of the
file fails when `schemaVersion` moves past 9 without a fixture for the previous version, so a bump cannot be forgotten.
Result: all four fixtures migrate cleanly, so the schema is NOT the cause of the reported failure.

**D106 — "Leaders needed" asks people who have said they might lead that day, not every leader (2026-10-17).**
Marking someone a `leader` (committee badge) should not mean being prompted about every run. The audience is: an
explicit "days I may lead" choice if the member made one, else people who have led that series before, else
brand-new leaders who have never led anywhere (so a newly badged leader still hears about gaps). The day choice
lives on the server (`member_preferences.lead_days`) because the server sends the notifications; it is set from the
Lead a run screen.

**D107 — Days I may lead replaces the roster's day filter (2026-10-17).** (Refined by D115/D116: days I run sit beside it and both screens get Show N more.)
The filter chips looked like a view setting. It is now a one-time commitment ("select the days you may be able to
lead") that collapses to a single "Days you may lead: Tue, Thu - Change" line, drives which runs the roster lists
and who is asked to lead. "None" is a valid explicit choice and silences the prompts.

**D108 — A leader leads one group per run, and only one group has the leader role (2026-10-17).**
Two groups led by the same person on the same run is a mistake, so the server refuses it (`already_leading`) and the
app hides the offers. Within a group there is one `leader` plus optional co-leaders and backmarkers
(`leader_exists`).

**D109 — Stepping down removes you from the group, and an unused group disappears (2026-10-17). Supersedes D30's
"withdraw keeps attendance".**
People step down because they cannot come or want another group, so they are removed from the group (still going,
or not going if they say so). If they created the group and nobody else joined, the group is deleted instead of
being left as "needs a leader", which also covers accidental sign-ups.

**D110 — Android notification icons: a pear silhouette small icon plus the logo as large icon (2026-10-17).**
Android draws the small icon as a white silhouette from the alpha channel only, so the coloured launcher icon showed
as a white square. A monochrome pear (from the round club logo, thickened so thin lines survive at 24 px) is the
status-bar icon, tinted club orange, and the round logo is the large icon on notifications the app builds.

**D111 — "Days I may lead" is cached as a nullable text column on `preferences`, schema v10 (2026-10-17).**
The server owns the choice (it decides who gets "leaders needed" pushes), so the app only caches it next to the other
preference fields: `preferences.lead_days` text, `null` = never chosen, `''` = chose none, `'2,4'` = Tue and Thu (ISO
weekdays, Monday = 1). There is no JSON column on that table, and a plain column is the same shape as `paceFromS`. The
v9 to v10 step adds the column with `addColumn` for databases from v4 up (older ones create the table with it), and
first looks at `PRAGMA table_info(preferences)` so a half-built file can't abort the upgrade. `test/fixtures/db/v9.sqlite`
was generated by the v9 code (D105). `PUT /preferences` for this field sends only `{leadDays: [...]}` (omitted keys mean
unchanged on the server), is online-only like every preference write, and the response (which echoes `leadDays`) is
what gets cached. The panel waits for the first preferences refresh before offering the prompt, so a saved choice
never flashes as "Which days could you lead?". The old local `leadRosterDays` key is only read to pre-select chips
while the server value is null; it is removed after a successful Save. An explicit empty choice shows only the runs you
lead (plus the hint) because "none" is a real answer, unlike the old filter where none meant all.

**D112 — The notification small icon is generated from the logo by `tool/make_notification_icon.dart` (2026-10-17).**
The script (the `image` package, no Photoshop step) thresholds the logo at luminance 128, labels the white blobs
(8-connected, breadth-first) and keeps the biggest blob whose bounding-box corners are within half the image width of
the centre: the pear, leaf and stem outline. The white square and outer ring have box corners about 640 px out and the
lettering is far smaller, so the rule needs no coordinates. The outline is thickened by 22 px (1000 px scale) so it
survives at 24 px, cropped, centred with 12% padding and area-averaged down to 24/36/48/72/96 px as pure white with
coverage in alpha. The large icon is the logo with the white corners made transparent (background found by flood
fill from the border, rim pixels get alpha from their darkness). The colour is a manifest/`@color/notification_accent`
(`#F89829`) and the same orange is passed to notifications the app builds; `res/raw/keep.xml` stops release resource
shrinking from removing `ic_notification_large`, which only Dart refers to. Re-run the script if the logo changes.

**D113 — Leader roster, role sheet and step-down details (2026-10-17).**
The "How will you help lead?" dialog does the join itself, so a 409 `leader_exists` stays visible inside it, refreshes
the run and removes "Leader" (co-leader and backmarker remain); with no `leader` in the group all three roles show.
The step-down dialog says the group will be deleted when the viewer created it, no other leader remains and
`goingCount + maybeCount - 1 <= 0` (maybes count as people in the group, and the server deletes only when nobody else is
in it); the checkbox "I can't make this run at all" sends `notGoing`. After the call the repository drops a deleted
group or merges the returned one, clears the viewer's attendance group and sets `not_going` only when ticked, which
replaces D30's local "keep going in the group" mirror. A leader who steps down is then an ordinary non-member, so the
group card needs no special case.

**D114 — One group per leader is enforced in the UI first, the server second; the editor can't double-submit (2026-10-17).**
Other groups of a run you lead show "You're already leading the {heading} group" instead of Offer to lead / Join as
leader / "I'll lead this group too" (and "Lead a group" is hidden), the editor refuses a second led group with "You're
already leading a group on this run" plus **Open it** (the editor of the group you lead; there is no group page), and a
server 409 `already_leading` (body `groupId`, kept in `ApiException.body`) is shown the same way. Leaderless adds
(`lead: false`) and event or race runs are not affected. The same screen gets a fix for a reported duplicate: the new
group's client UUID is made once per editor and reused by every save or retry, Save ignores taps and shows a spinner
while a request runs and re-enables only on failure, and a 200 (the server replaying that id) closes as a success, so
pressing Save twice can never create two groups even before the server's 409 backstop.


**D115 — Days I run, next to days I may lead; both narrow their screen and the unasked-for notifications (2026-10-18).
Refines D107.**
The Runs tab listed every run, including ones a member never does, and the Lead a run choice read like a notification
setting. Members now choose two things. **Days I run** narrows the Runs tab. **Days I may lead** narrows Lead a run.
Someone who leads Mondays and runs Wednesdays sees both days on Runs and only Mondays on Lead a run.
- **Stored on the server** (`member_preferences.run_days`), because the server decides who is notified.
- **Lead days stay inside run days.** Leading a day means being there. The server enforces it, so the two lists can
  never disagree on another device: saving lead days adds them to the run days, and narrowing run days drops lead days
  outside them. The editors say so before Save.
- **Notifications** follow the days only where the member gave no answer for that run: new matching groups, the series
  "usually comes" reminder and the leaders-needed fallback. Going, maybe or leading on a run always wins. An explicit
  series "always" or explicit lead days also still win. A member who is going on a day they don't lead is not asked to
  lead, because lead days are an explicit choice.
- **Fallback:** Lead a run uses the run days when no lead days are chosen (nobody leads on a day they don't run), and
  so does the server's leaders-needed fallback.

**D116 — One compact days panel for both screens, with a per-visit Show all (2026-10-18).**
`MyDaysPanel` (`features/runs/ui`) serves both kinds.
- **Once chosen** it is one line, "Run days: Mon, Wed", with **Show N more** and **Change**, not a row of chips.
- **Show N more** is screen state, not saved. It is a peek, and saving one would quietly undo the choice. It turns
  into **Just my days**.
- **Before a choice:** the Runs tab stays quiet ("Showing every day", **Choose days**, hidden with fewer than two
  weekdays). Lead a run keeps asking up front, as in D107, because the answer matters for leader prompts.
- **Run days** need at least one day. "None" would empty the tab, and **Show every day** is the way back to no
  filter. Lead days may still be none.
- **The Runs tab** hides "can't come" runs on other days, but runs you are going to, might go to or lead always show.
  The old "N runs hidden by the days you chose" note and the "Only runs you already lead" hint are folded into the
  Show N more button.

**D117 — One saved choice per series drives My runs and reminders; days become a shortcut (2026-10-19). Replaces
D115's "days I run" and D35's reminder-only override.**
Members could not tell which controls saved and which only changed the view, and the feed (days) and reminders (per
series Always/Automatic/Never) disagreed: Perdiswell on Never still showed, and a day filter could not show "only the
runs I picked".
- **The series is the unit:** `member_series_prefs.mode` is `follow`, `auto` or `hide` (no row = `auto`). The old
  `reminders` value maps to it (Always = follow, Automatic = auto, Never = hide); there is no second copy.
- **One resolver**, written twice and pinned by one shared case table: RSVP yes shows; hide never; follow always; auto
  when the member usually comes (D35's history rule, still off for events and races, D79). One-off runs always show
  but are never followed. The reminder job, the group-match notice and the leaders-needed fallback use it on the
  server; the Runs tab uses the Dart copy.
- **The feed stays on the device.** The plan suggested a `view` parameter on the sessions feed; the app is
  offline-first (it renders the Drift cache), so it caches `GET /follows` and resolves locally. The shared table is
  what keeps the two sides equal.
- **Open questions, answered with the plan's assumptions:** (1) an RSVP beats Hide, in the feed and for that run's
  reminder; (2) the view resets to My runs on every start; (3) members who never chose days get auto everywhere and
  start on All runs until they make any choice; (4) "usually comes" is D35's rule, exposed per series as
  `usuallyComes`; (5) one-off runs always show in both views; (6) Maybe gets a tonal chip with a question-mark icon;
  (7) the empty state uses the suggested copy. Change any of these if the testers disagree.
- **Migration** (`app:migrate-follows`, dry run first): Never = hide even on a selected day, Always = follow,
  Automatic on a selected day (run or lead day) = follow, otherwise auto. Unmigrated members are read through the same
  mapping and any write migrates them first, so deploying the server before running the command changes nothing.
  It keeps the old data and skips migrated members, so it is safe to run twice. Side effect worth a release note:
  members who chose days now get reminders for every run of those series, not just ones they usually attend.
- **Older apps keep working:** notification settings read and write the mode, and saving run days follows the auto
  series on those days (hide is left alone, like the migration).

**D118 — Settings look like settings, views look temporary (2026-10-19).**
- **My runs | All runs** is a 48dp pill with the selected side orange and checked; switching is instant, writes
  nothing and is not stored. All runs carries a dashed "Just looking" banner; dashes mean temporary.
- **Runs I follow** (`/follows`, above the shell like a member profile) is the only place modes are edited: a
  Follow | Auto | Hide control per series with a status line that makes Auto readable, Follow all per day and Follow
  everything. Every tap saves; the two bulk buttons offer Undo through the restore form of `PUT /follows`, and any
  later change dismisses it. The cache is updated optimistically and put back on failure, with a snackbar.
- **The three-way control is 44dp**, not the 42dp the mockup drew, because the plan also requires every control to
  be at least 44dp. Its outline (and the view switch's) is painted as a foreground decoration so each segment's tap
  area is the full height. Each segment is a selectable button in a mutually exclusive group for screen readers.
- **Cards** carry one status chip (Going, Maybe, Can't come, Following, Not following, Hidden) and a trailing
  **Manage** or **Follow**. "Can't come" stays (the old Runs tab showed it). The response chip moved out of the
  summary row; "You're leading" stays there. Hidden cards in All runs use the dimmed fill and border.
- **Feed colours** that the `ColorScheme` has no slot for live in a `RunFeedColors` theme extension, with the plan's
  dark values and matching light ones.
- The days-I-run panel and its Show N more / Just my days peek are gone; `MyDaysPanel` remains for Lead a run, which
  now falls back to every day instead of the run days.
