# BPJ app roadmap

**Goal:** an app that members and leaders actually open. Club updates must not get
lost, and arranging pace groups for club runs should be easy. It is built on the
existing Lumen API and Auth0 tenant. Data is kept per club so it can be
white-labelled for other clubs later.

Tick items as they land. Each phase ends with a build in testers' hands. Add
decisions to [decisions.md](decisions.md), not here.

---

## Phase 0: Foundations

- [x] Agree this plan and the [open questions](#open-questions)
- [x] Choose the app id **before the first shared build**. It can't change after a
      store listing. Proposed: `uk.org.bpj.app`, display name "BPJ".
- [x] Tidy the scaffold: make `mobile/` the Flutter root (flatten `mobile/bpj`),
      and drop the `windows/` platform because Auth0 and FCM plugins don't
      support it
- [x] Add core packages (riverpod, go_router, drift, dio, auth0_flutter,
      flutter_secure_storage, json_serializable, build_runner), stricter lints,
      and the feature-first folder skeleton
- [x] Add `config/dev.json` and `config/prod.json`, read with
      `--dart-define-from-file`. Locally, the Android emulator reaches the PHP
      dev server at `http://10.0.2.2:8000`.
- [x] Theme: BPJ colours and logo, taken from the Next.js Tailwind config
- [x] Add `api/env` to `.gitignore`. It holds live secrets and is currently
      untracked but **not ignored**.
- [x] CLAUDE.md files (root, `mobile/`, `api/`)

## Phase 1: MVP: sign in, link membership, profile

**Auth0 dashboard (manual):**
- [x] Create a **Native** application in the existing tenant and enable the Google,
      Facebook and Username-Password connections on it
- [x] Add callback and logout URLs for Android and iOS, following the auth0_flutter
      setup docs
- [ ] Turn on refresh-token rotation, with an absolute lifetime of ~365 days and an
      inactivity lifetime of ~90 days. Confirm "Allow Offline Access" is on for the
      `https://bpj.org.uk` API.
- [ ] Check that a token from the new client passes the API's HS256 verification
      (`GET /user/token`)

**API:**
- [x] Migrations: `clubs` (seed BPJ, EA club 1606), `club_members` (one per
      person per club) and `member_logins` (many Auth0 logins → one member)
- [x] Backfill `club_members` and `member_logins` from existing `users.athleteId`,
      so people who registered on the website are linked automatically
- [x] `app` route group with `auth` middleware, plus a `club` middleware that
      resolves `{clubId}` and the caller's member row
- [x] `GET /app/me`: the user plus their club memberships (club, status, roles,
      athlete summary)
- [x] `POST /app/clubs/{clubId}/link {urn, dob}` checks the details against
      `athletes` **and links in a single call**:
      - Also sets `users.athleteId`, so the web profile stays in step
      - Returns 404 if no athlete matches
      - Several logins may link to the same athlete
      - Rate-limits failed attempts per user
      - Contract: [api-contract.md](api-contract.md)
- [x] `GET /app/clubs/{clubId}/profile` returns the member's own athlete details
      and membership status (active/affiliated/category)
- [x] Bruno requests and Swagger annotations for the new endpoints

**App:**
- [x] Sign-in screen → Universal Login (Google / Facebook / email). Debug builds
      also allow pasting an access token, for testing before the Auth0 Native app
      exists.
- [x] `AccountStore`: credentials per user in secure storage, silent renewal, and
      the dio auth interceptor
- [x] Drift database per account, caching `me` and the profile (works offline)
- [x] Link flow:
      - URN + DOB form, with help on where to find the URN
      - "We think we found you" confirmation
      - Not-found state that suggests waiting a day if recently joined, with a
        contact link
      - Join the club → https://bpj.org.uk/membership
- [x] Profile screen: name, category, membership status, links (results, Power
      of 10, claim award); sign out
- [x] Signed release APK: upload keystore created 2026-10-12 (`android/key.properties`, git-ignored;
      **back both files up**). Sharing through Firebase App Distribution: see Phase 7.

**Done when:** a tester installs the APK, signs in with Google, links their
membership, sees their profile in airplane mode, and is still signed in a week later.

## Phase 2: Push notifications & club updates

Push comes before runs because every later feature depends on it. Club updates
are the simplest way to prove push end to end, and they address the original
problem of updates being missed.

- [x] Create a Firebase project with Cloud Messaging only (config comes from
      `FIREBASE_*` in `config/*.json`; first real push verified 2026-10-11)
- [x] API (see "Implementation notes (Phase 2)" in api-contract.md):
      - `devices` table with `POST` and `DELETE /app/devices`
      - `notifications` (inbox) and `notification_preferences` tables
      - `FcmClient` sending through the FCM HTTP v1 API. A service-account JWT is
        signed with phpseclib, so no new composer package is needed. It deletes
        tokens that come back UNREGISTERED.
      - A `notifications` queue drained every minute by cron. Host cron runs
        every minute, so no synchronous fallback is needed.
      - `app:member-role` artisan command to grant leader/committee/admin
      - `posts`: list with `?since`, and committee create/edit. `important` posts
        go to everyone.
- [x] App (built and unit/widget-tested; real push verified 2026-10-11):
      - Permission prompt after linking
      - Token registration
      - Foreground display
      - Deep links (switching context if the push is for another account or club)
      - Offline Updates feed
      - Inbox with unread badge
      - Notification settings screen
      - Committee "new post" screen
- [ ] iOS: push needs the paid Apple Developer account and an APNs key uploaded to
      Firebase. Android works now.

**Done when:** the committee posts from the app and testers get a push. Posts can
still be read offline later.

## Phase 3: Club runs schedule

- [x] API:
      - `venues`, `session_series` and `sessions` tables
      - A generator command that runs nightly and whenever a series changes,
        keeping sessions materialised 8 weeks ahead
      - Endpoints: `GET sessions?from&to&since`; committee CRUD for series; edit
        or cancel one occurrence (detaches it); ad-hoc session
- [x] Seed BPJ series:
      - Mon 19:00 OECC (paced)
      - Tue 19:00 Riverside (paced)
      - Wed 19:00 Nunnery Wood track (single)
      - Thu 18:30 Mug Run, Claines, summer (open)
      - Thu 19:00 Perdiswell, winter (paced)
      - Sun 08:00 long run (routes, with a coordinator)
- [x] App:
      - Runs tab listing upcoming sessions by day, with cancelled/changed banners
      - Session detail with venue, map link, notes and a link to the
        `/club-runs/{slug}` page
      - Committee screens to edit or cancel an occurrence, edit a series, and add
        an ad-hoc run

## Phase 4: Pace groups, leaders & attendance (headline feature)

Contract: [api-contract.md](api-contract.md#phase-4-groups-leaders-attendance-preferences).
Model: [data-model.md](data-model.md#groups-leaders-attendance) (D20-D24).

**4a: API**
- [x] Tables `session_groups`, `session_group_leaders`, `session_attendees`,
      `member_preferences`, applied as a manual SQL file like earlier phases
- [x] Groups embedded in the sessions payload, with a `summary` for the caller
- [x] Group create / edit / delete, join and withdraw as leader (`needs_leader`)
- [x] Attendance upsert, with per-run pace override
- [x] `plan` endpoint: anonymous pace spread for everyone, names for leaders,
      the coordinator and committee, unassigned members for the gap view
- [x] Preferences endpoint (pace unit, distance unit, ideal pace range)
- [x] Members search and roles endpoints (committee grants the `leader` badge)

**4b: App foundations**
- [x] `Pace` and `Distance` value objects: parse and format `m:ss`, mi/km
      conversion, single or range, display in the viewer's units
- [x] Drift schema v4 for groups, attendance and the cached plan
- [x] Repositories: groups, attendance (optimistic with a pending retry),
      preferences, members
- [x] Profile: pace unit, distance unit and ideal pace range

**4c: App screens**
- [x] **Session view:** groups sorted by pace with their leaders, each showing pace
      and distance in your units
- [x] Responses: "I'm coming" (no group yet), join a group, "Not coming", plus a
      pace override for this run
- [x] **Group editor:** pace none / single / range, distance optional, units,
      kind, description. "I'll lead this group" is on for members.
- [x] **Leader roster:** the next 6 weeks of runs, tap to lead a group, and withdraw
- [x] Leaders see the names in their group; members see counts and the pace spread
- [x] **Committee coverage view (D28):** the spread of led groups on a pace axis with gaps;
      members coming without a matching group, bucketed by pace, as a secondary section
- [x] Mug Run: informal "I'll run about X, join me" groups
- [x] Sunday long runs ("Add route", "I'm doing this route", the pace sheet and the
      per-route pace spread): the coordinator adds route groups (e.g. 10 mi, 16 mi);
      attendees pick a route and their pace for that run
- [x] Committee: set a session's coordinator, search members and grant the
      `leader` badge

This follows the patterns grassroots-club apps (Spond, Team App) and parkrun's
volunteer roster use: a roster grid for volunteers to commit ahead of time, and a
per-event page where members RSVP with an optional sub-group.

## Phase 5: Smarter notifications

Contract: [api-contract.md](api-contract.md#phase-5-smarter-notifications). Decisions D31-D37.

**5a: API foundation**
- [x] Manual SQL file: dedupe key and push-request columns, series prefs, daily cap (`api/database/manual/2026_10_notifications_v2.sql`)
- [x] NotificationService: dedupe keys, daily cap; FCM data-only mode for action notifications
- [x] Notification settings endpoints; unauthenticated notification-actions endpoint
- [x] `app:send-test-push`: first real FCM send from the host console (works, 2026-10-11)

**5b: API triggers**
- [x] `app:send-reminders` (every 10 min): morning-of reminders, leaders needed 3 days out
- [x] Group added that matches your pace (delayed job)
- [x] Leader withdraws: attendees and fitting leaders asked to step in; group removed
- [x] Run cancelled, restored or moved: tell attendees, leaders and coordinator

**5c: App**
- [x] Settings: daily push limit and per-series reminders
- [x] Action buttons ("I'm coming" / "Not coming") from foreground and background
- [x] Real-device check of push end to end (tested 2026-10-12)

## Phase 6: Group messaging

Contract: [api-contract.md](api-contract.md#phase-6-group-messaging). Decisions D39-D44.

**6a: API**
- [x] Manual SQL file: `group_messages`, `group_thread_states`
- [x] Thread endpoints: list/post/delete, read marker, mute, `GET threads`
- [x] Push for new messages: one inbox row per thread, collapsed pushes, mute respected

**6b: App**
- [x] Drift v5 (messages cache with local outbox, thread state) and chat repository
- [x] Chat screen, delete, mute, closed state; polling while open
- [x] "Group chat" button on group cards with unread dot; "Group chats" list on the Inbox tab
- [x] Real-device check with two accounts (tested 2026-10-12)

## Tweaks after first real use (2026-10-13)

API (D47-D50, see the "Update (2026-10-13)" contract section):
- [x] Optional run duration (series and sessions), image URL on series, label required for no-pace groups,
      pick-a-group nudge, 12-hour times in server text; one manual SQL file (`2026_10_runs_v2.sql`)

App:
- [x] Palette: club orange #f89829 on black/white/grey (D51); website link first in Profile links
- [x] 12-hour times everywhere, optional duration in editors, series image above run cards (cached)
- [x] Runs: hide "You're going" when leading; note on the group list that other pace groups are confirmed at the start (D55)
- [x] Prompt to pick a group after "I'm coming" (D55, app half of D50)
- [x] Pace group card: heading merged with label and pace, "Step down" beside "You're leading", label required when pace is None
- [x] Lead a run: day filter (only days that exist), "Can't attend" collapses the card, link to bpj.org.uk/leading-a-group

## Phase 6.5: Member profile card (photo, bio, goals)

Contract: [api-contract.md](api-contract.md#phase-65-member-profile-card-photo-bio-goals). Decisions D59-D63.

**6.5a: API**
- [x] Manual SQL file: `member_profiles`, `member_photos` (`api/database/manual/2026_10_member_profiles.sql`)
- [x] My card: get/update bio, goals and goals visibility; JPEG upload/remove; signed photo download
- [x] Other members: profile endpoint, full member-cards list, committee "clear profile"

**6.5b: App foundations and screens**
- [x] Drift tables for member cards and cached profiles; cards sync; avatar + name widgets (`MemberAvatar`, `MemberLink`)
- [x] Profile page for other members (pushed, back returns); committee remove action
- [x] "My profile card" screen: photo pick/crop/resize, bio, goals + share checkbox, preview

**6.5c: Use it everywhere**
- [x] Thumbnail + name (tap opens profile) on group cards, run page "Led by", coordinator, chat, who's coming (also post detail author, committee lists)
- [x] Real-device check (photo from camera and gallery, two accounts) (tested 2026-10-12)

## Phase 7: Store release & pipeline

Docs for this phase live in [store/](store/) (release checklist, privacy policy draft, Play listing and
data-safety answers). Decisions D71-D73.

**7a: Release engineering (Android first)**
- [x] Upload keystore + `key.properties` (git-ignored); release builds are signed with it
- [x] App bundle (`flutter build appbundle`) builds and is signed with the upload key (checked 2026-10-12); version/build number convention in store/release-checklist.md
- [ ] Firebase App Distribution for beta testers (`scripts/distribute-android.sh`; needs the Firebase CLI
      login once, see store/release-checklist.md)
- [ ] Google Play Console ($25 one-off; paid 2026-10-12, awaiting approval). New personal accounts must run a
      **closed test with 12+ testers for 14 days** before production. An organisation account needs a
      D-U-N-S number.
- [ ] CI builds: Codemagic, the nearest thing to EAS for Flutter (hosted macOS, signing, free tier), or GitHub Actions

**7b: Store compliance**
- [~] **In-app account deletion** (API `DELETE /app/account` + Profile -> About & privacy -> Delete my account), D72.
      (built and tested; verify against production after the API is deployed and the SQL applied)
      Both stores require it when users can create an account.
- [ ] Privacy policy page on bpj.org.uk (draft: store/privacy-policy.md), Play data-safety form
      (answers: store/data-safety.md), content rating, store listing text and screenshots
- [x] About screen: version, privacy policy link, delete account (Profile -> About & privacy, D75)

**7c: iOS (needs the paid Apple Developer account, not started)**
- [ ] Apple Developer Program ($99/yr): TestFlight, then the App Store
- [ ] **Sign in with Apple**. Apple guideline 4.8 expects it when Google or Facebook login is offered.
      Auth0 has an Apple connection.
- [ ] APNs key uploaded to Firebase (iOS push), iOS action category check, App Store privacy labels

## Phase 8: parkrun tourism and race events

Contract: [api-contract.md](api-contract.md#phase-8-parkrun-tourism-and-race-events). Decisions D74, D76-D79.
One Saturday "parkrun" series gives one Runs card per Saturday; its groups are the individual events, each with
its own chat for car sharing. Races are ad-hoc one-event sessions.

**8a: API**
- [x] Manual SQL file: `event_locations`, `session_groups.location_id` (`api/database/manual/2026_10_events.sql`)
- [x] Group modes `events` and `race`; event groups (any member creates/joins, de-duplicated per location);
      race auto-group; pace machinery and pace notifications off for these modes
- [x] Event locations endpoints and `app:import-event-locations` (parkrun events.json or CSV)
- [x] Plan names for fellow attendees inside an event group; reminder wording

**8b: App foundations**
- [x] Drift table + sync for event locations (schema v8, `?since=` cursor, refresh on start/resume/club switch)
- [x] Group modes `events`/`race` in every editor and helper (`features/runs/logic/run_modes.dart`); the pace
      helpers, the pick-a-group prompt, coverage and the Lead-a-run roster skip them
- [x] Venue optional ("No venue") in the series and ad-hoc editors; null venue renders cleanly everywhere
- [x] Committee screen `/profile/event-locations` (list, search, kind chips, add/edit/delete)
- [x] "Add a parkrun/event" picker `showEventPicker` (search, recently used first, free text, save for next time)

**8c: App screens**
- [x] Runs card summary ("3 going to 2 events"), events run page (event cards, add an event, notes, remove,
      fellow attendees, chat per event), race page ("Who's going?" card), pace/leader controls hidden (D84, D85)
- [x] Lead-a-run and coverage skip these modes (done in 8b, with tests)
- [ ] Real-device check

Later: a feed for the parkrun events list, "who's visiting us", distance/travel hints, car-share seats.

## Tweaks (2026-10-18): days I run and lead

Contract: "Update (2026-10-18)" in [api-contract.md](api-contract.md). D115, D116.
- [x] API: `member_preferences.run_days`, `runDays` on `/preferences`, lead days kept inside run days; matching-group
      notifications, series auto reminders and the leaders-needed fallback follow the days unless you answered
      (manual SQL `2026_10_run_days.sql`)
- [x] App: shared `MyDaysPanel` on Runs (run days) and Lead a run (lead days) with Show N more; Drift schema v11
- [ ] Real-device check

## Tweaks (2026-10-19): Runs I follow

Contract: "Update (2026-10-19)" in [api-contract.md](api-contract.md). D117, D118. Replaces the days I run panel.
- [x] API: `member_series_prefs.mode` (follow/auto/hide), one `FollowResolver` for reminders, group matches and the
      leaders-needed fallback; `GET/PUT /follows` with bulk set and restore; old notification settings and `runDays`
      saves write modes (manual SQL `2026_10_follows.sql`)
- [x] API: `app:migrate-follows` with `--dry-run` counts per rule, safe to run twice
- [x] App: My runs | All runs on the Runs tab, status chips, inline Follow, Runs I follow screen with Undo;
      Notification settings links to it; Drift schema v12
- [ ] Host: run `2026_10_follows.sql`, then `app:migrate-follows --dry-run`, check the counts, then run it
- [ ] Real-device check (TalkBack on the three-way control)
- [ ] Later: remove `runDays` handling and `member_preferences.run_days` once older app versions are rare

## Phase 9: Club standards

Contract: [api-contract.md](api-contract.md#phase-9-club-standards). The BPJ Bronze/Silver/Gold/Platinum
standards table, defaulting to the member's own gender and age category.

**9a: API**
- [x] `GET /app/clubs/{clubId}/standards` (one cacheable document with ETag/304, `mine` from the athlete record)

**9b: App**
- [x] Club standards screen (category picker defaulting to yours, awards table, pace toggle): `/profile/standards`, D90-D93
- [ ] Real-device check

## Review round 1 (2026-10-21)

Done (see D119–D122): can't-come runs leave My runs, half-height banners, leader-first cards, side-by-side
Join/Chat, no "already leading" note (Join is blocked with a Step down offer), Save button no longer covered by a
snackbar, usual-pace nudge, Inbox tabs, coverage as a pace ladder.

Still to build. Each needs new server tables and endpoints, so they're designed here for review before any
migration is written. Suggested order: 1, 3, 2 (3 reuses the chat screen from 2).

1. **Read receipts on updates** (tick = delivered to a device, double tick = opened and read): **built (D123)**.
   - Always on, not a setting. Only the committee sees who; members never see each other's state.
   - API `post_receipts` + `POST /posts/receipts` + `GET /posts/{id}/receipts`; the app reports delivered after every
     posts refresh and read when the update has been open 2s and scrolled to the end.
   - [ ] Host: run `api/database/manual/2026_10_post_receipts.sql` before deploying the API.
   - [ ] Later: a per-update summary on the committee's Updates list, and "nudge those who haven't read it".
2. **Chat on updates** (members ask, committee replies)
   - Reuse the group-chat tables with a thread kind: `threads(id, kind: group|post|leaders, ref_id, club_id)` and
     move `group_messages` to `thread_messages`, or add `post_id` beside `group_id`. The second is a smaller
     migration; the first avoids a third copy of the thread code for item 3.
   - Everyone sees the whole thread (it's a Q&A), committee replies carry a "Committee" badge (decided). Committee get a push for new
     questions, members who've posted or opened the thread get one for replies. A per-post mute, and committee can
     close comments on a post.
   - Inbox: a "Chats" tab entry per update thread, using the tabs added in D121.
3. **Committee ↔ leaders threads and "Can you lead?"**: **built (D125)**.
   - One thread per run for the committee, the run's leaders and anyone asked; the coverage card's gaps and unled
     groups have **Ask leaders**, the ask is a `leaders_needed` push and repeats once after a day if still uncovered.
   - Inbox has a **Leaders** tab; leaders get a **Leaders thread** link on the run page.
   - [ ] Host: run `api/database/manual/2026_10_leader_threads.sql` before deploying the API.
   - [ ] Later: **I can lead** could pre-fill the pace in the group editor, and a leader signing up could post "Sam is
     now leading 9:00/mi" into the thread automatically. Move the ask's pace/note out of `body` into columns at the
     next schema bump.

## Backlog

- PBs and Magic Mile results on the profile (API already has these)
- Standing leader patterns ("I usually lead 9:00/mi on Mondays") pre-filling the
  roster
- Calendar export (ICS) for runs you're attending
- Multi-club onboarding and white-label flavors
- Admin web screens for runs and posts (Next.js `admin` app)
- Move Auth0 API signing from HS256 to RS256 (JWKS, no shared secret)
- Trial runners (3 free sessions) using the app before joining

---

## Open questions

1. **API host:**
   - Cron can run every minute, so notifications will go through the queue.
   - Still to confirm: is there SSH to run `composer install` (needed for
     `google/auth`) and `php artisan migrate` on the host?

Resolved on 2026-10-06; see decisions D11–D14.
