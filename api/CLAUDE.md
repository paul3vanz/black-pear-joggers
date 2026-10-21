# BPJ API (Lumen 10, PHP 8.2, MariaDB)

Shared backend for the Next.js and Angular sites and the Flutter app. See `readme.md` for
local setup, scheduled jobs and the Power of 10 notes.

## Shape

- **Routes** are all in `routes/web.php`. Controllers are in `app/Http/Controllers`
  and carry Swagger `@OA` annotations. Models are in `app/Models` (Eloquent,
  Compoships for composite keys).
- **Auth:** `AuthServiceProvider` verifies Auth0 access tokens (HS256, audience
  `https://bpj.org.uk`).
  - `Auth::user()` is the **decoded token array**: use `['sub']` for the user id
    and `['permissions']` for RBAC.
  - Admin checks use `Gate::allows('members:read')` etc.
  - `GET /user/token` echoes the decoded token, which helps when debugging.
- **Jobs:** database queue. The schedule lives in `app/Console/Kernel.php`.
- **Membership data:**
  - `memberships` is the EA registration sync, refreshed every 6 hours.
  - `athletes` is the club athletes table (keyed by `id`, with `urn` and `dob`).
  - `users` maps an Auth0 `sub` to `athleteId` (web linking).
- **Requests:** add a Bruno request in `bruno/` for each new endpoint.

## Mobile app endpoints (`/app/...`)

Mobile endpoints live in an `app` route group, separate from the existing
`/clubs/{clubId}` EA lookup routes. Rules for them:

- **New tables:**
  - Include `club_id`; personal rows also include `member_id` (`club_members.id`).
  - UUID primary keys, snake_case columns, `created_at`/`updated_at`/`deleted_at`.
  - Never change existing table conventions.
- **Club scoping:** every query on new tables filters by `club_id`. A `club`
  middleware resolves `{clubId}` and the caller's member row.
- **Sync:** list endpoints support `?since=` and return soft-deleted rows as
  tombstones.
- **Idempotent writes:** writes accept a client-supplied UUID so offline replays
  are safe.
- **Notifying members:** call `app(NotificationService::class)->notifyMembers($club, $memberIds, <category from NotificationCategories>, $title, $body, ['route' => '/…'], $force)`.
  It always writes the inbox row and queues one push job (queue `notifications`, drained every minute by the scheduler).
  Never call FCM directly.
  Pass `['dedupeKey' => …, 'onDuplicate' => 'skip|replace']` as a last argument to collapse repeats per member. Non-locked, non-forced pushes obey the member's rolling 24 h cap (`member_preferences.push_daily_cap`, default 6). A notification whose `data.actions` is set must also carry `data.actionToken` (`NotificationService::newActionToken()`); the presenter never exposes it. Check a real send with `php artisan app:send-test-push {clubId} {athleteId}`.
- **Run notification triggers (Phase 5b):** request-driven ones live in `Services/RunNotifier` (session changes, leader withdraws, group removed, delayed `NotifyMatchingGroupJob`); they are guarded, so call them without try/catch and never let them fail a write. Time-driven ones (`app:send-reminders`, every 10 min) live in `Services/RunReminderService` with an injectable "now". Pace matching is `Services/PaceMatcher`. Times in any text people read go through `RunText::clock/range/time` (12-hour, `7:30pm`); JSON keeps `HH:MM`. The "pick your pace group" nudge is `RunNotifier::nudgePickGroup` (called by both the reminder service and the group-match job). See "Implementation notes (Phase 5b)" in `../mobile/docs/api-contract.md`.
- **Roles:** `php artisan app:member-role {clubId} {athleteId} {leader|committee|admin} [--remove]` (athletes.id).
- **Hosting key lengths:** schema is applied by hand as SQL and prod enforces a 1000-byte index limit, so never index a `varchar(255)`. Index only `char(36)` uuids, ints, dates or strings ≤ 191 chars, and keep each composite key under 767 bytes. Every `Schema::create` sets `engine = 'InnoDB'`, JSON/TEXT columns get no DB default, and seed rows are inserted by the migration so `migrate --pretend` shows them.
- **Club runs:** `SessionGenerator` (`app:generate-sessions`, hourly, and on every series write) materialises `sessions` from `session_series`. It never touches detached or past sessions (a run with no stated end has `has_end=false` and still ends at start + 3 h through `ends_at`), so write session edits through the `/sessions` endpoints and set `is_detached` for anything the series controls.
- **Groups and sign-ups:** `session_groups`, `session_group_leaders`, `session_attendees` and `member_preferences` hang off sessions. Every change to them must call `ClubSession::touchForChange()` so `?since=` delivers it. Never delete a session that has a live group or going/maybe attendance (the generator detaches it instead).
- **Group permissions:** helpers live in `Concerns/ManagesGroups`. Check order is 404, 403, 422, then 409 `session_cancelled`/`session_past`. Plan names and `attendees` keys are omitted, not emptied, when the caller may not see them.
- **Group chat (Phase 6a):** one thread per `session_groups` row, endpoints in `AppGroupMessageController`. Participant, moderator, closed and author-role rules live only in `Services/ThreadAccess`; the notification audience is `Services/GroupMessageNotifier`. See "Implementation notes (Phase 6a)" in `../mobile/docs/api-contract.md`.
- **Profile card (Phase 6.5a):** bio, goals and a JPEG photo per member, in `AppMemberProfileController`; the photo is a MEDIUMBLOB in its own `member_photos` table (never load it except to serve it) and is downloaded through an unauthenticated, throttled, HMAC-signed link built by `Services/MemberPhotoLink` (signs with the raw `APP_KEY` string). See "Implementation notes (Phase 6.5a)" in `../mobile/docs/api-contract.md`.
- **Account deletion (Phase 7b):** `DELETE /app/account` via `Services/AccountDeletion`. Add any new member-keyed table there and to its test (`tests/AppAccountDeletionTest.php`). See "Implementation notes (Phase 7b)" in `../mobile/docs/api-contract.md`.
- **Events and races (Phase 8a):** group modes `events` and `race` make a run's groups the events people go to (kind `event`, no pace, no leaders, no pace-group notifications): `AppGroupController@storeEvent`, `AppEventLocationController`, `ClubSession::isEventMode()`, host import `app:import-event-locations`. See "Phase 8: parkrun tourism and race events" and "Implementation notes (Phase 8a)" in `../mobile/docs/api-contract.md`.
- **Club standards (Phase 9a):** `GET /app/clubs/{clubId}/standards` (`AppStandardsController`) serves the BPJ Bronze-Platinum table from the legacy `standards`/`awards`/`events` tables (not club-scoped; `events.distance` is metres, `time_parsed` is seconds, gender `M`/`W` mapped to `male`/`female`) with an ETag/304 and the caller's `mine` category. See "Phase 9: club standards" in `../mobile/docs/api-contract.md`.
- **Leaders needed (D106):** who is asked to lead (run-level alert and the leader-withdrew alert) is decided in one place, `Services/LeaderAudience` (club-local weekday vs `member_preferences.lead_days`, else no if `run_days` leaves the day out, else series history in the last 26 weeks, else a brand-new `leader`); `RunNotifier::availableLeaders` adds pace fit and exclusions. One group per leader, one `leader` per group and the step-down rules (D108/D109) are in `AppGroupController`. See "Update (2026-10-17)" in `../mobile/docs/api-contract.md`.
- **Runs I follow (D117):** one `member_series_prefs.mode` (follow | auto | hide, no row = auto) per member and series decides both My runs and run reminders. The rule is `Services/FollowResolver` only (the app has a copy, both tested against `tests/fixtures/follow_resolver_cases.json`); read and write modes through `Services/SeriesFollows`, which also reads unmigrated members through the migration mapping (`app:migrate-follows`). Reminders, group-match notices and the leaders-needed fallback use it; anything sent because a member is going, maybe or leading still always goes. `member_preferences.run_days` (D115) is kept only for older apps: saving it follows the auto series on those days. See "Update (2026-10-19)" in `../mobile/docs/api-contract.md`.
- **Update receipts (D123):** `post_receipts` holds each member's `delivered_at` / `read_at` for a club update, reported by their own app through `POST /posts/receipts` (`AppPostReceiptController`) and readable by the committee only. "Delivered" is also the push's `pushed_at` (the post's notifications carry the dedupe key `post:<id>`). It is in `AccountDeletion`. See "Post receipts" in `../mobile/docs/api-contract.md`.
- **Leaders threads (D125):** a chat per run between the committee and the run's leaders, plus members a committee "can anyone lead 8:25-10:05/mi?" ask went to (`AppLeaderThreadController`, access rules in `Services/LeaderThreadAccess`, notifications and the one-day repeat in `Services/LeaderThreadNotifier`, called from `RunReminderService`). It mirrors the group chat; the app addresses it as `leaders:<sessionId>`. Tables `leader_messages`, `leader_thread_states`, `leader_thread_members` are in `AccountDeletion`. See "Leaders thread" in `../mobile/docs/api-contract.md`.
- **Design reference:** `../mobile/docs/data-model.md` (tables) and
  `../mobile/docs/ROADMAP.md` (what's next).

## Deploy

- Pushes to `master` that touch `api/**` are uploaded over FTP.
- `vendor/` and migrations are **not** handled by that deploy. Run composer and
  migrations on the host by hand.
- Never commit `env`, `.env` or `*.pem`.

## Gotchas

- `App\Exceptions\Handler` turns every exception, including `ValidationException`, into a 500 unless the debug cookie is set. For a real 422, use `Validator::make` and return the response yourself. Lumen also has no `now()` helper; use `Illuminate\Support\Carbon`.
