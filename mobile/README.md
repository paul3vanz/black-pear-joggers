# BPJ mobile app

Flutter app for Black Pear Joggers. See [CLAUDE.md](CLAUDE.md) and [docs/](docs/) for the plan.

## Prerequisites

- Flutter 3.47+ (Dart 3.13+), Android SDK with accepted licences (`flutter doctor`)
- Dev API running locally: `php -S localhost:8000 -t public` in `../api`
  (the Android emulator reaches it at `http://10.0.2.2:8000`)

## Run

```sh
flutter pub get
dart run build_runner build      # generate *.g.dart (use `watch` while developing)
flutter run --dart-define-from-file=config/dev.json
flutter test
flutter analyze
```

Use `config/prod.json` for builds against the live API. Config files hold public values only.
`AUTH0_CLIENT_ID` is empty until the Auth0 Native app is created; until then the Sign in
button is replaced by a notice.

## Debug sign-in with a pasted token

Debug builds show "Developer: sign in with access token" on the sign-in screen.

1. Sign in on the website (bpj.org.uk).
2. In browser devtools, Application, Local Storage, copy the value of `bpj.token`.
3. Paste it into the field and tap "Use this token".

The token is stored as an account with no refresh token, so it stops working when it expires.
This option is compiled out of release builds.

## Testing the link flow against a local API

1. In `../api`, run `php -S localhost:8000 -t public` with a migrated database
   (the `clubs`, `club_members` and `member_logins` migrations must have run, and
   there must be an `athletes` row to match).
2. Run the app on an Android emulator (`flutter run --dart-define-from-file=config/dev.json`).
   It reaches the API at `http://10.0.2.2:8000`.
3. Sign in (Universal Login, or the debug token option above). A login with no
   linked member lands on `/link`.
4. Enter an athlete's URN and date of birth from the local `athletes` table.
   A match shows "We think we found you!". "That's me" goes to the profile and
   "Not me" unlinks again. Wrong details show the not-found state. Five failed
   attempts within an hour show the "too many attempts" message.

The profile screen works offline from the cache. Switch the emulator to airplane mode
to see the "Offline — showing saved details" banner.

## Signed release APK

`flutter build apk --release --dart-define-from-file=config/prod.json` signs with the
debug key unless `android/key.properties` exists. To sign properly, create the upload
keystore (see [docs/setup.md](docs/setup.md)) and add `android/key.properties`:

```properties
storeFile=C:\Users\you\bpj-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

`key.properties` and `*.jks` / `*.keystore` are git-ignored. Back the keystore up:
updates can't be signed without it.

## Notes

- `analyzer` is pinned below 14.5 in `pubspec.yaml` because build_runner 2.16.1 doesn't
  compile against analyzer 14.5.0. Remove the pin once build_runner is fixed.

## Push notifications

Push is off until Firebase is configured (see `docs/setup.md` → Firebase). Everything else
(updates feed, inbox, settings) works without it.

To enable it, fill the `FIREBASE_*` values in `config/dev.json` / `config/prod.json` from
Firebase console → Project settings → Your apps (Android app `uk.org.bpj.app`):
`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`,
`FIREBASE_ANDROID_APP_ID` (and `FIREBASE_IOS_APP_ID` later). They're public identifiers.
No `google-services.json` is used: the app builds the Firebase options from these values.

To test end to end (Android):
1. Run the app with the filled config on a device or emulator with Google Play services, sign in
   and link. Accept the notification explainer. The device token is registered for every
   signed-in account.
2. Give your member the `committee` role (`php artisan app:member-role`, see `docs/setup.md`).
3. Tap **New update** on the Updates tab, leave "Send notification" on and post. Another signed-in
   member should get the push (foreground, background or killed). Tapping opens the post.
4. No push? Check the API host has `FCM_SERVICE_ACCOUNT_PATH` set and cron running
   `schedule:run`. The inbox row is created either way.

**iOS (later, on a Mac):** `remote-notification` is already in `UIBackgroundModes`. In Xcode, add the
Push Notifications capability (and Background Modes → Remote notifications), then upload the APNs
key to Firebase. That needs the paid Apple Developer account.

## Phase 4 testing guide (groups, leaders, attendance)

Needs the Phase 4 API tables applied (`api/database/manual/2026_10_groups_tables.sql`) and a local
API. Use two accounts that are both linked to a club member: **A** (plain member, also the leader
below) and **B** (committee). Give B the `committee` role (or admin) in the database.

1. **Member (A):** Runs tab → open an upcoming run. Under *Are you coming?* tap **I'm coming**,
   then join a group (or **My pace for this run** to override your pace). Under *Who's coming* you
   see counts and the anonymous pace spread, no names.
2. **Leader (A):** Runs tab → **Lead a run** (top right) shows the next six weeks. Tap **Offer to
   lead**, fill the editor and save. Next time **Same as last time** creates the group in one tap
   (Undo in the snackbar). Edit or **Step down** from the same card. As leader of the group you now
   see *Who's in this group* with names and paces.
   Creating or joining a group as leader also marks you as going in it, so you see *You're leading
   this group* with only **Step down** (no Join/Leave); after stepping down you stay in it as a member.
   Pace fields are two boxes, **min** and optional **sec** (the Android number pad has no colon).
3. **Committee (B):** at the end of *Who's coming* on the run detail, a **Group coverage** card
   shows the groups that have a leader on a pace strip, the fastest and slowest led group, and gaps
   such as "Nobody leading slower than 10:30/mi" (a jog/walk group softens the slow end). Groups
   with no leader are listed as *Needs a leader*; **Add a group** creates a leaderless one. If
   members have said they're coming that no led group covers, a *People coming with no matching
   group* section appears in the same card. *Who's coming* also lists *Coming, no group yet* with
   names. **Manage** → *Members and roles* (also on the Profile tab) searches members
   and toggles **Leader badge** (committee) or **Committee** / **Admin** (admins only). Edit a
   run → **Coordinator** picks the member who can add routes (best for *routes* runs).
4. **Offline:** turn on airplane mode; the run, groups and last plan still show, with *Updated …*.
   Writes show "You need a connection to do that." or queue (responses only).

## Phase 5 testing guide (reminders and answer buttons)

Needs the Phase 5 API (`api/database/manual/2026_10_notifications_v2.sql` applied) and a real
device or emulator with Google Play services and Firebase configured (see Push notifications above).

1. **Settings:** Profile → Notification settings. Under the category switches, *Daily push limit*
   (3 / 6 / 12 / No limit) and *Run reminders* (one row per series: Automatic / Always / Never).
   Each choice saves at once; turn on airplane mode to see the revert and the snackbar.
2. **Reminder with buttons:** on the API host (or locally) run
   `php artisan app:send-test-push {clubId} {athleteId} --actions --session={sessionId}`. It writes a
   `run_reminders` inbox row for that member and sends a **data-only** push. Put the app in the
   background (or kill it) and the notification appears with **I'm coming** and **Not coming**.
3. **Tap a button:** the notification is replaced by "Thanks, you're down as coming" (or "…you can't
   make it"). Open the run to see your answer; it also shows in the run's *Who's coming* counts.
   "That run has changed - open the app" means the run was cancelled or finished (404/409);
   "Couldn't send - open the app to answer" means no connection.
4. **Tap the body:** opens the run, as for any notification. Re-sending the same reminder replaces
   the notification already showing (same `tag`).
5. No buttons? Check `FCM_ACTION_BUTTONS` isn't `false` in the API `.env`, and that the push has no
   `notification` block (use `adb logcat -s flutter` to see "Background push"). Some phone makers
   kill background delivery for apps that were force-stopped.
