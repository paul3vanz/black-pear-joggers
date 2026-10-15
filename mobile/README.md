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

## Delete account testing note

Profile → **About & privacy** shows the version, the privacy policy, club website and contact
links, and a red **Delete my account** under "Danger zone". It opens a full-screen explanation;
the red button only enables when `DELETE` is typed exactly (capitals).

- **Use a throwaway Auth0 account** (a spare Google login or an email sign-up), linked to a test
  member. Deletion is permanent on the server and needs the API from Phase 7b deployed
  (`DELETE /app/account`, see docs/api-contract.md).
- After deleting you land on the sign-in screen. The website login and the club membership are
  untouched, so signing in again goes through the link flow (URN and date of birth) and starts
  with an empty profile card, chat history and sign-ups.
- A club's only admin gets "Make someone else an admin first." and nothing is deleted.
- Airplane mode: "You need a connection to delete your account."
- With two accounts on the device, only the deleted one is removed; the app switches to the other.

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

1. **Member (A):** Runs tab → open an upcoming run. Under *Are you coming?* tap **I'm coming**; a
   *Pick your pace group?* sheet offers the groups once per run (**Join**, or **I'll decide on the
   day**); with no groups a short note says they are confirmed at the start. You can also join from the
   cards below. The pace line under the buttons reads *Usual pace: 9:00-9:30/mi* with **Change for this
   run**; with no usual pace saved it says *No usual pace set* with **Set your usual pace** (opens the
   Profile tab) and **Set pace for this run**; after you set one it reads *Running at 9:30/mi this run*
   with **Change**. Choose **Can't come** and the pace line disappears. Under *Who's coming* you see
   counts and the anonymous pace spread, no names.
2. **Leader (A):** Runs tab → **Lead a run** (top right) shows the next six weeks. Tap **Offer to
   lead**, fill the editor (there is no "I will lead this group" switch: you lead what you create) and
   save. Next time **Same as last time** creates the group in one tap
   (Undo in the snackbar). Edit or **Step down** from the same card. As leader of the group you now
   see *Who's in this group* with names and paces.
   Creating or joining a group as leader also marks you as going in it, so you see *You're leading
   this group* with a **Step down** button on the same row (no Join/Leave); after stepping down you stay in it
   as a member. A group with no pace needs a label (the editor says so). On *Lead a run*, day chips (only
   the weekdays that exist, remembered) filter the list, **Can't attend** folds a run to one line, and
   *Tips on leading a group* opens the website.
   Pace fields are two boxes, **min** and optional **sec** (the Android number pad has no colon).
3. **Committee (B):** at the end of *Who's coming* on the run detail, a **Group coverage** card
   shows the groups that have a leader on a pace strip, the fastest and slowest led group, and gaps
   such as "Nobody leading slower than 10:30/mi" (a jog/walk group softens the slow end). Groups
   with no leader are listed as *Needs a leader*; **Add a group** opens the editor with an *I will lead this
   group* switch (on by default; turn it off to create a leaderless one). Only the committee, admins and
   the run's coordinator see that switch; **Lead a group** never shows it. If
   members have said they're coming that no led group covers, a *People coming with no matching
   group* section appears in the same card. *Who's coming* also lists *Coming, no group yet* with
   names. **Manage** → *Members and roles* (also on the Profile tab) searches members
   and toggles **Leader badge** (committee) or **Committee** / **Admin** (admins only). Edit a
   run → **Coordinator** picks the member who can add routes (best for *routes* runs).
4. **Offline:** turn on airplane mode; the run, groups and last plan still show, with *Updated …*.
   Writes show "You need a connection to do that." or queue (responses only).

## Pace preferences, clock labels (D86-D89)

1. **Usual pace needs Save:** Profile tab → *Running preferences*. Type a pace under *My usual pace range*:
   **Save** stays disabled until the pace is valid and different from what is saved ("Not saved yet" shows
   under it). Press **Save**: a green check and *Saved* appear, and the Runs → run page pace line shows the
   new usual pace straight away, with no refresh. **Clear** removes a saved pace at once. With airplane
   mode on, Save shows "You need a connection to save your preferences." and keeps what you typed. The
   min/mile and min/km and Miles/Kilometres choices save as soon as you tap them (the pace range is
   converted with the unit).
2. **Stale "Today":** open the Runs tab, leave the app in the background past midnight, then reopen it:
   yesterday's run is gone and tomorrow's reads **Today**. (To test quickly, move the phone clock past
   midnight and bring the app to the front.) "Updated 5 minutes ago" labels move on about once a minute while
   shown.

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

## Phase 6 testing guide (group chat)

Needs the Phase 6 API (`api/database/manual/2026_10_messages_tables.sql` applied) and two accounts that are both
linked to a club member: **A** and **B**, on two devices or emulators (or one device with the account switcher).
For pushes you also need Firebase configured (see Push notifications above).

1. **Make a group (A):** Runs tab → open an upcoming run → **Lead a group** and save. A now leads the group and
   its card has a **Group chat** button.
2. **Join it (B):** open the same run (pull to refresh on the Runs tab), tap **I'm coming**, then **Join this
   group**. B's card for that group now has **Group chat** too. A member who isn't in the group has no button.
3. **Chat:** open the chat on both. Messages from the other person appear within about 8 seconds (or at once when
   a push arrives and the chat is open; no notification is shown for the chat you are looking at). Others show
   their name (first name + initial) and a *Leader* / *Coordinator* / *Committee* badge; your own are on the right.
   Day headings separate the days. The line under the title can be dismissed and stays dismissed.
4. **Unread and Inbox:** leave the chat on B and send from A: B's group card gets an unread dot and the Inbox tab's
   **Group chats** section lists the thread with the last message and an unread badge. Opening the chat clears both.
5. **Delete:** long-press your own message → **Delete** (shown as "Message deleted" for both). The leader of the
   group, the run coordinator and committee/admin can delete anyone's message; a plain member can't delete others.
6. **Mute:** in the chat's ⋮ menu choose **Mute notifications** (bell-off icon appears; needs a connection). While
   muted B gets no push or inbox row for the thread, but still sees messages when the chat is open.
7. **Offline send:** turn on airplane mode on B, send a message: it shows **Sending...** and an offline banner.
   Turn the network back on: it goes out on the next poll (or resume) and the clock text becomes the time.
8. **Failed message:** a message refused for good (for example after the chat closed) shows **Failed - tap to retry
   or delete**; tapping it offers Retry or Delete.
9. **Closed chat:** posting stops 12 hours after the run ends (and while it is cancelled). The input is replaced by
   **Chat closed**; the messages stay readable. To try it without waiting, edit the run's date to the past in the
   database, or cancel the run as committee.
10. **Leave the group:** B taps **Leave group** (or "Not coming") then opens the chat from the Inbox list: it shows
    "You're no longer in this group" and goes back.

## Phase 6.5 testing guide (profile cards: photo, bio, goals)

Needs the Phase 6.5 API (`api/database/manual/2026_10_member_profiles.sql` applied) and two accounts that are both
linked to a club member: **A** and **B** (two devices/emulators, or one device with the account switcher). Use a real
phone for the camera. One account should be **committee** (call it **C**; it can be A).

1. **Open the editor (A):** Profile tab → **My profile card** (the row shows "Add a photo and a few words about you"
   until something is saved).
2. **Photo from the gallery:** **Choose photo** → pick a landscape and a portrait picture in turn. A round preview
   appears (centre-cropped square, upright even for phone photos taken sideways) → **Use photo**. The row's thumbnail
   changes. Pick something tiny (under 64 px) or a non-image file: a message explains and nothing is uploaded.
3. **Photo from the camera:** **Take photo**, accept the permission prompt, take a sideways shot: it comes out upright.
   Deny the permission once and check the message that points to Settings.
4. **Bio and goals:** type a bio (counter stops at 300) and goals (stops at 1000). **Save** is disabled until you
   change something. Save, then leave and reopen: the text is still there.
5. **Sharing (two accounts):** on B open A's profile by tapping A's name or thumbnail where it appears (a group's
   "Led by", the run page coordinator, a leader's "Who's in this group" list, a chat message author, an update author) or
   by **See how others see me** on A's own screen. Back returns to where you were. B sees A's photo and bio but **not**
   the goals. On A tick **Share my goals with other members** → Save; B pulls to refresh the page and now sees a
   **Goals** section. Untick and save: it disappears again.
6. **How others see me:** on A tap **See how others see me**: the page shows "This is how you appear to other members"
   and **Edit my profile card**. Back returns to the editor.
7. **Remove the photo:** **Remove photo** on A; thumbnail goes back to initials.
8. **Offline:** airplane mode on A, open **My profile card**: the saved card shows with an offline banner; **Save**
   says you need a connection and keeps your text. Open B's profile page offline: the last copy shows with a banner.
9. **Committee clear (C):** on A's profile page choose ⋮ → **Remove photo and bio** → **Remove**. A's photo, bio and
   goals are gone for everyone; A can add new ones. Plain members have no ⋮ menu, and nobody has it on their own page.
10. **Not available:** make a member inactive (or use a random id in a deep link): the page says "This member isn't
    available".

## Phase 8 testing guide (parkrun tourism and race events)

Needs the Phase 8 API (`api/database/manual/2026_10_events.sql` applied), a committee account (**C**) and two
member accounts (**A** and **B**) linked to the club.

1. **Add event locations (C):** Profile tab → **Event locations** (committee only: a plain member has no row). The
   screen says "N locations" and "The parkrun list is imported by an administrator on the server (see setup docs)".
   Import the parkrun list on the server first (`php artisan app:import-event-locations {clubId} {file}`), then pull
   to refresh: the parkruns appear. **Add location** → name "Droitwich 10k", kind **Race**, region → **Save**. Tap a
   row to edit, **Delete** asks first. Search and the parkrun/Race/Other chips narrow the list. Offline, saving says
   you need a connection.
2. **Create an events series (C):** Runs tab → manage menu → **Manage series** → **Add series**. Title "Saturday
   parkrun", Saturday, 09:00, **How we run: Events (e.g. parkrun)**. **Venue: No venue** (leave it). The dropdown has no
   "Race" here. Save: one run per Saturday appears on the Runs tab with no venue line.
3. **Ad-hoc race (C):** manage menu → **Add ad-hoc run**: the dropdown has both "Events (e.g. parkrun)" and "Race (one
   event)". Pick Race, title "Droitwich 10k", **No venue**, Save.
4. **Pace machinery stays off:** on those runs there is no pace note, no "Pick your pace group?" sheet after "I'm
   coming", no coverage card (as committee) and the runs do not appear under **Lead a run**.
5. **Runs card wording:** on the Runs tab the Saturday parkrun card shows "No one has picked a parkrun yet" (and
   no "N groups", no pace, no "needs a leader"). The race card shows "No one has said they're going yet".
6. **Add and join events (A):** open the Saturday run. The page says "Where are you running?" with "Nobody has picked
   a parkrun yet." Tap **Add a parkrun / event**: the picker lists recently used parkruns first. Pick one (for
   example Worcester): its card appears with "You're going", "1 going" and a **Chat** button, and a snackbar offers
   **Add a note for car sharing**. Use the card's menu (**Edit note**, hint "e.g. Meeting at 8:15 at the Co-op car
   park, 2 seats spare") and save: the note shows on the card. On the Runs card it now reads "1 going to 1 event" and
   your chip "You're going to Worcester parkrun".
7. **Free text and duplicates (B):** open the same run as **B**. **Add a parkrun / event** → **Other...** → type
   "Hereford parkrun" (leave "Save for next time" off) → **Use this name**: a second card, B is in it. Now add
   Worcester again: no second card, B just joins it ("You're going to Worcester parkrun"). **A** pulls to refresh
   and sees "2 going" on Worcester.
8. **Names only inside the same event:** A and B are both in Worcester, so each sees the other under **Also going**
   with an avatar (tap to open the profile). On the Hereford card nobody sees any names. **Leave** on a card puts you
   back to "going, event not chosen yet" (the page says "N going, event not chosen yet"); **Can't come** at the top
   clears your answer.
9. **Chat for a lift:** A and B tap **Chat** on Worcester and swap messages; the other gets a push and the unread dot
   on the **Chat** button. Someone who is not in Worcester has no Chat button (committee do).
10. **Notes and removing:** only the creator of an event, the committee and the run coordinator see the card menu.
    **Remove event** asks first; people in it are left going with no event and get a notification.
11. **Race (C creates "Droitwich 10k", A and B open it):** one card, "Who's going?", with **I'm going** / **Can't
    go**, going count, **Chat** once you are going, and names of fellow attendees. No Add button, no menu, no "Are
    you coming?" card. The Runs card reads "2 going".
12. **Pace machinery stays off:** on events and race runs there is no pace override, no pace note, no pick-a-group
    sheet, no coverage card (as committee), no "Lead a group", and the runs are not under **Lead a run**.

## Club standards testing note

Needs the Phase 9a API (`GET /app/clubs/{clubId}/standards`) and a member linked to the club. Profile tab → **Club
standards** ("Targets for your age category").

1. **Opens on your category:** the Men/Women control and the category chip row open on your own gender and age
   category (a star on the chip, "Showing your category"). Each event (Mile, 5K, 10K, Half Marathon, Marathon) is a
   card with Bronze, Silver, Gold and Platinum tiles. An event with no standard for the category is not shown.
2. **Pick another:** tap **Men**/**Women** or another chip: the cards change and the caption reads "Showing V50
   women" with **Back to mine**. Leave and reopen the screen: it opens on yours again.
3. **Time / Pace:** switch to **Pace**: the tiles show min/mile or min/km according to the pace unit in Profile →
   running preferences (for example 5K in 25:48 is 8:18/mi and 5:10/km). Change the unit in Profile and come back to
   see it follow. The choice is kept after you close the app.
4. **No category known:** a member whose athlete record has no date of birth or gender opens on Men SEN with a hint
   to link the membership.
5. **Offline:** open the screen once online, then turn on flight mode and reopen: the saved table shows with
   "Offline — showing saved standards. Updated ..." (and "Updated 3 days ago" under the cards when online). With no
   saved copy and no network it says it could not load and offers **Try again**.
6. **Revalidation:** the second visit sends `If-None-Match` and the server answers 304 (check the API log); an edit to
   the `standards` table changes the ETag and the new times appear on the next open.
7. **Claim:** **Claim an award on the website** opens https://bpj.org.uk/claim-award in the browser.
8. **Small phone:** at 320 px wide (or large system text) the award tiles go two by two and nothing overflows.

## Releasing

Beta builds (Firebase App Distribution), the Google Play steps, version numbers and the pre-release checklist are in
[docs/store/release-checklist.md](docs/store/release-checklist.md). Store text, the privacy policy draft and the Play
Data safety answers live next to it in [docs/store/](docs/store/README.md). Quick beta: `scripts/distribute-android.sh`.
