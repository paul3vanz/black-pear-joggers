# Release checklist: BPJ app (Android first)

For the owner. Do the sections in order. Commands run from `mobile/` in Git Bash unless it says otherwise. Decisions behind this: D71 (signing, Play App Signing, Firebase App Distribution), D72 (account deletion), D73 (these docs). Roadmap: [Phase 7](../ROADMAP.md).

Two kinds of build:

| | Beta build | Play build |
|---|---|---|
| For | Testers before Play is ready (and quick fixes) | Google Play (closed test, then production) |
| File | `app-arm64-v8a-release.apk` | `app-release.aab` (an "app bundle") |
| Delivered by | Firebase App Distribution | Google Play Console |
| Signed by | Your upload key | Your upload key, then Google re-signs with its own key |

**The two are signed with different keys once Play is involved, so a phone cannot upgrade from a Firebase beta to the Play version (or back). The tester uninstalls first.** Say so in the invite.

---

## A. Back up the signing key now (10 minutes, do not skip)

You already have two files, both git-ignored (so git does not hold them):

- `mobile/android/upload-keystore.jks` (the key, alias `upload`)
- `mobile/android/key.properties` (the passwords, and the path to the key)

Also worth saving: `mobile/config/prod.json` and `mobile/config/dev.json`. They are git-ignored too (`mobile/.gitignore` has `config/**`). They hold only public ids, but if your PC dies you would have to rebuild them from the Auth0 and Firebase dashboards.

1. Copy those files to **two** places: the password manager (store the `.jks` as an attachment, the passwords as a note) and an encrypted USB drive or cloud storage that is not the same machine.
2. Open the backup and check the file sizes match (the `.jks` is a couple of KB).
3. Write down, in the password manager: the alias (`upload`), the store password, the key password, and that the keystore file is called `upload-keystore.jks`.
4. Never email these, never paste into chat, never commit them. (Claude and the other tools never need the passwords.)

### Play App Signing: what it means and what if you lose the key

When you create the app on Play, Google offers **Play App Signing** (it is the default and the only option for new apps). Google keeps the real "app signing key". You sign your uploads with the **upload key** (the keystore above) to prove it is you. Google strips your signature and signs the app that users get with its own key.

If you **lose the upload key**: the app is not lost. In Play Console -> your app -> **Test and release -> Setup -> App signing** (or "App integrity"), use **Request upload key reset**. You generate a new keystore, export its certificate (`keytool -export -rfc -keystore NEWKEY.jks -alias upload -file upload_cert.pem`), upload the `.pem`, and Google (after a few days) accepts the new key for future uploads. Update `key.properties` and back the new file up. Beta APKs signed with the old key won't update over new ones; testers reinstall.

If you lose the key **before** the first Play upload, simply make a new one: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`, in `mobile/android/`, and update `key.properties`. Nothing is published yet, so nothing is lost except that old beta installs must be uninstalled.

---

## B. Version numbers

`mobile/pubspec.yaml` has one line:

```yaml
version: 1.0.0+1
```

- `1.0.0` is the version name people see (use `major.minor.patch`).
- `+1` is the **build number** (the Android "version code"). **It must be higher for every upload to Play**, even a rejected one. Bump it every time you build something to upload: `1.0.0+2`, `1.0.0+3`. The visible name only changes when users should notice.
- **You do not bump by hand:** `bash mobile/scripts/build-release.sh` raises the build number by one and builds the Play bundle and the phone APKs (`--aab-only`, `--apk-only`, `--no-bump`, `--name 1.1.0` to change the visible name too). `scripts/distribute-android.sh` bumps too (unless `--no-bump`). `scripts/bump-version.sh` does only the bump. **Commit `pubspec.yaml` after each build** so the number keeps rising (Play already has 1; the next upload is 2).
- Suggestion: bump the build number for every Play upload and the patch (`1.0.1+4`) for each public release. Keep them rising together.
- Split APKs (the beta build) add a number for the phone type on top (arm64 phones show 2000 + N), so beta and Play version codes are not comparable. That is another reason not to mix beta and Play installs on one phone.

Commit the bump (`pubspec.yaml`) so the history shows what each number was.

---

## C. Building

### Beta APK for testers (arm64 phones, about 23 MB)

```sh
flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (also `armeabi-v7a`, `x86_64`; modern phones need arm64). The Firebase script in section D builds just this one for you.

### App bundle for Google Play

```sh
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`. This is the file you upload to Play.

### Check it is signed with your key (not the debug key)

```sh
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The "Owner" must not say `Android Debug`. (If `key.properties` is missing the build silently falls back to the debug key; this check catches it.)

### One uninstall when switching to release-signed builds

Phones that still have an old **debug-signed** build (from `flutter run` or an APK built before the keystore existed) cannot update to the release-signed build. Uninstall the old app once, then install the new one. Same rule if a phone goes from Firebase beta to Play. After that, updates install in place. You lose the local cache, nothing else (data is on the server).

### Before you hand anything to anyone

```sh
flutter analyze
flutter test
```

Both should pass. Check `config/prod.json` points at the production API (`API_BASE_URL`), not a dev address.

---

## D. Beta testers: Firebase App Distribution

Free, quick, no Play review. **For beta testing only**: not a way to publish to the public.

### One-off setup

1. Install the Firebase CLI (needs Node, already installed):
   ```sh
   npm install -g firebase-tools
   firebase login
   ```
   `firebase login` opens a browser; sign in with the Google account that owns the Firebase project ("BPJ App").
2. In the Firebase console (https://console.firebase.google.com), open the project -> **Release & Monitor -> App Distribution**. Click **Get started** if you see it.
3. **Testers & Groups** tab -> **Add group** -> name it `testers` (the group alias is what the script uses; `testers` is the default). Add testers' email addresses (the Google accounts they use on their phones).
4. Check the Android app listed is `uk.org.bpj.app`. Its app id is already in `config/prod.json` (`FIREBASE_ANDROID_APP_ID`); the script reads it, you do not paste it anywhere.

### Each beta release

1. Bump the build number (section B).
2. Run the script:
   ```sh
   scripts/distribute-android.sh --notes "What changed in this build"
   ```
   It builds the arm64 APK with `config/prod.json`, finds the app id, checks `firebase` is installed and logged in, and uploads to the `testers` group. Options: `--group NAME`, `--no-build` (re-upload the APK you already built), `--help`.
3. Testers get an email. They accept the invite, then either install **Firebase App Tester** (from the link in the email) or open the link in the phone's browser and download the APK (they must allow "install unknown apps" for that browser once). Later builds appear in the App Tester app with a notification.

If something goes wrong: "firebase: command not found" means step 1 of the setup; "Failed to authenticate" means run `firebase login` again; a 403 error means your Google account lacks a role on the project (ask the Firebase owner to make you Editor or App Distribution Admin).

---

## E. Google Play (new account steps)

Your account was created 2026-10-12 and paid for ($25 one-off). A **personal** account has extra rules for new apps (below).

### 1. Wait for the account to be approved

Google verifies your identity (ID, address, phone and email; sometimes a video call or confirmation with a real Android device). You can't create an app until this clears. It can take a few days. Do the section G tasks meanwhile.

### 2. Create the app

Play Console -> **Create app**:
- Name: `BPJ` (see [play-listing.md](play-listing.md))
- Default language: English (United Kingdom)
- App (not game); **Free**
- Accept the declarations.

### 3. Do the "Set up your app" tasks (Dashboard, or App content)

All the answers are in [data-safety.md](data-safety.md) and [play-listing.md](play-listing.md).

- [ ] **Privacy policy** URL: https://bpj.org.uk/privacy-policy (page must be live)
- [ ] **App access**: needs login (give the test account, data-safety.md section 4)
- [ ] **Ads**: no ads
- [ ] **Content rating** questionnaire
- [ ] **Target audience and content**: 18+ (data-safety.md section 3)
- [ ] **Data safety** form
- [ ] **Data deletion / account deletion** form
- [ ] **Government apps**: no
- [ ] **Financial features**: none
- [ ] **Health**: the app has no health features (it does not record workouts or give health advice); if the Console wording makes you unsure, read the options and pick what is true (data-safety.md section 3.1)
- [ ] **Advertising ID**: the app does not use it
- [ ] **Select an app category and contact details**: Sports, club email, website
- [ ] **Main store listing**: text and graphics from play-listing.md

### 4. Create the closed testing track and upload the bundle

1. Build the AAB (section C).
2. Play Console -> **Test and release -> Testing -> Closed testing** -> **Create track** (or use the default "Closed testing - Alpha"), name it `members`.
3. **Create new release** -> upload `app-release.aab`. Accept Play App Signing if asked. Add release notes (template in play-listing.md). **Save, then Review release, then Start rollout to closed testing.** The first review often takes a few days.
4. **Testers** tab: create a list (**Create email list**, paste the Google-account emails, one per line) or use a **Google Group** (add the group's email address). Save.
5. Copy the **opt-in link** ("How testers join your test") and send it to the testers. Each tester must open it **on a phone signed into the Google account on the list**, tap **Become a tester**, then install the app from the Play Store link. If they only install it without opting in, they don't count.

### 5. The 12-tester, 14-day rule (personal accounts)

New personal developer accounts must run a closed test with **at least 12 testers who stay opted in for 14 continuous days** before they can apply for production. (Organisation accounts are exempt but need a D-U-N-S number.)

- Get **15 or so** testers to be safe, so a few dropping out doesn't restart the clock.
- Testers must **stay opted in the whole time** (leaving the test removes them from the count). It is the **opt-in** that is counted, but active testers are better: ask them to open the app now and then and give feedback.
- **How to count**: Play Console -> **Dashboard** -> the "Get production access" / "Apply for production" card shows how many testers have opted in and the days completed. Under **Closed testing -> Testers** you also see the number opted in. The card says "14 days" and a progress bar once you have 12.
- If the number drops below 12 the progress resets, so tell testers to stay in the test until you have applied.

### 6. Apply for production access

When the Dashboard shows the requirement is met, click **Apply for production**. Questions you will be asked (answers to adapt):
- *About your app and testers*: a members' app for a running club; the 12+ testers were club members; how you recruited them; how long they tested.
- *What you changed after feedback*: note a couple of fixes from the beta.
- *Production readiness*: how the app will be supported (`webmaster@bpj.org.uk`).

Google replies in a few days (usually under a week). Then create a **Production** release from the same AAB (or a newer build; bump the build number) and roll out.

### 7. After production

Updates: bump the build number, build the AAB, add a new release on the Production (or Closed testing) track, wait for review (a few hours to a few days). Use a **staged rollout** (for example 20% first) for any change you are nervous about.

---

## F. iOS and the Apple App Store (not started)

Nothing here is done. See [ROADMAP Phase 7c](../ROADMAP.md) and Phase 2's iOS push item. You need:

- **Apple Developer Program**: $99 a year (individual) or an organisation account (needs a D-U-N-S number). Needed for TestFlight and the App Store.
- **A Mac with Xcode**, or a hosted Mac build service (Codemagic is the one in the roadmap). Flutter cannot build iOS on Windows.
- **Sign in with Apple**: the app offers Google and Facebook sign-in, and Apple's guideline 4.8 expects an equivalent privacy-friendly option, which in practice means Sign in with Apple. Auth0 has an Apple connection; enable it for the Native app and test it.
- **APNs key** (a `.p8` file) created in the Apple Developer account and uploaded in Firebase -> Project settings -> Cloud Messaging -> Apple app configuration. Without it iOS gets no push. Also add the Push Notifications capability in Xcode (see mobile/README.md "Push notifications").
- **App Store privacy labels** (the iOS equivalent of the Data safety form): the answers are the same as data-safety.md, redone in App Store Connect.
- **Account deletion in the app** is required by Apple too (guideline 5.1.1(v)); the same Profile -> About & privacy -> Delete my account covers it.
- Test on a real iPhone via **TestFlight** first.

---

## G. Pre-release checklist (tick all before the first upload, and re-check each release)

### Legal and Play pages
- [ ] `[CONFIRM]` markers in [privacy-policy.md](privacy-policy.md) resolved and the page is **live and public** at https://bpj.org.uk/privacy-policy (open it in a private window)
- [ ] The page has a section titled "Deleting your account and data", and the URL with `#deleting-your-account-and-data` jumps to it (or use the plain URL everywhere)
- [ ] Contact email in the policy and the listing (`webmaster@bpj.org.uk`) is real and monitored
- [ ] The Play target audience is **18 and over only** (the club has no members under 18) and the policy "Children" section says the app is for adults
- [ ] Every Play form task in section E.3 is ticked

### API on production
- [ ] The latest `master` is deployed (GitHub Actions `deploy-api.yml` uploaded it over FTP; `vendor/` is installed on the host)
- [ ] The manual SQL files have been applied **in this order, each once only** (`api/database/manual/`):
  1. `2026_10_app_tables.sql`
  2. `2026_10_runs_tables.sql`
  3. `2026_10_groups_tables.sql`
  4. `2026_10_notifications_v2.sql`
  5. `2026_10_messages_tables.sql`
  6. `2026_10_runs_v2.sql`
  7. `2026_10_member_profiles.sql`
  8. `2026_10_posts_author_nullable.sql` (account deletion; harmless to re-run)
  9. `2026_10_events.sql` (parkrun and race events, Phase 8; **not** safe to run twice; then import the parkrun list, see `docs/setup.md`)

  Running one twice fails (CREATE/ALTER errors) and does no harm; just don't re-run to "check". To see what has been applied, look at the `migrations` table: the files record their migration names there. The folder also has `2026_10_leaders_attend_backfill.sql`: an optional one-off, safe to run more than once, that marks existing leaders as going in their own group. Run it once if leaders signed up before that change; it is not part of the ordered list.
- [ ] Host settings from `docs/setup.md`: `APP_KEY` set (photo links), PHP upload limits at least 1 MB, `FCM_SERVICE_ACCOUNT_PATH` set, cron runs `php artisan schedule:run` every minute
- [ ] The Firebase service-account JSON is **only on the host**, outside the web folder, and never committed (a copy sits in the `api/` folder on the developer PC; make sure git ignores it)
- [ ] **Account deletion works against production**: `DELETE /app/account` is deployed, and a throwaway account can use Profile -> About & privacy -> Delete my account end to end. Check the data really goes (member row, photo, messages) and the app signs out. **Do not submit to Play until this passes.**
- [ ] The test reviewer account from data-safety.md section 4 exists and can sign in and link

### Build
- [ ] `pubspec.yaml` build number is higher than any previous upload
- [ ] `flutter analyze` and `flutter test` pass
- [ ] Built with `--dart-define-from-file=config/prod.json`, signed with the upload key (`keytool -printcert -jarfile ...` check in section C)
- [ ] The About screen shows the right version and a working privacy policy link

### Test on real phones
- [ ] **Clean install** on a phone that never had the app (or after uninstalling), **and an upgrade** from the previous release over the top (shows database upgrades work). Both with the release-signed build.
- [ ] Smoke test (about 15 minutes, airplane mode for the offline items):
  1. Sign in with email, then with Google, then Facebook (each on a fresh install).
  2. Link with a test URN and date of birth. Wrong details show the not-found message. Five wrong tries are blocked.
  3. Profile tab: details show; airplane mode still shows them with the offline banner; sign out and in again.
  4. Allow notifications. Send a test push (`php artisan app:send-test-push 1 <athleteId>`) with the app open, in the background and swiped away. Tap it: the right screen opens.
  5. Updates: committee posts an update with notify on; a second phone gets it.
  6. Runs: open a run, tap "I'm coming", join a pace group, set a pace for this run. Cancel the run as committee: the attendee is told.
  7. Reminder with buttons: `app:send-test-push ... --actions --session=<id>`, answer from the notification.
  8. Group chat: two phones, send, delete, mute, offline send then reconnect.
  9. Profile card: add a photo (gallery and camera), bio, goals with and without sharing; another phone sees what it should.
  10. Settings: daily push limit, per-series reminders.
  11. Sign out removes the notification token (no pushes to a signed-out phone).
  12. Events (if Phase 8 is deployed): add a parkrun to a Saturday, say you are going, and on a second phone see the first member's name once it is also going to the same event; open the event chat.
  13. **Delete my account** with a throwaway account; sign in again and confirm it lands on the link screen.
- [ ] No crashes, no red error screens, no stuck spinners. Check with `adb logcat -s flutter` on a connected phone if something looks wrong.

### Last look
- [ ] Release notes written
- [ ] Screenshots, icon (512 x 512) and feature graphic (1024 x 500) uploaded, see [play-listing.md](play-listing.md)
- [ ] Keystore and `key.properties` backed up in two places (section A)
