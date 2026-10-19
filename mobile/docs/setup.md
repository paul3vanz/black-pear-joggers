# One-off setup (manual steps)

These steps need a human with dashboard access.

## Auth0 Native application (Phase 1)

Tenant: `blackpearjoggers.us.auth0.com`

1. **Applications → Create Application:**
   - Name: "BPJ App"
   - Type: **Native**
2. **Settings → Application URIs.** Add both URLs below to *Allowed Callback URLs* and to *Allowed Logout URLs*. The app uses a custom scheme, so no App Links / Universal Links setup is needed.
   ```
   uk.org.bpj.app://blackpearjoggers.us.auth0.com/android/uk.org.bpj.app/callback
   uk.org.bpj.app://blackpearjoggers.us.auth0.com/ios/uk.org.bpj.app/callback
   ```
3. **Settings → Refresh Token Rotation:**
   - Rotation: **on**
   - Reuse interval: 30s
   - Absolute expiration: **on**, 31,536,000s (365 days)
   - Inactivity expiration: **on**, 7,776,000s (90 days)
4. **Connections tab:** enable the same connections the website uses (Google, Facebook, Username-Password).
5. **APIs → `https://bpj.org.uk` → Settings:** make sure **Allow Offline Access** is on. Without it, no refresh token is issued and users are signed out when the access token expires.
6. Copy the new app's **Client ID** into `mobile/config/dev.json` and `mobile/config/prod.json` as `AUTH0_CLIENT_ID`. Client IDs are public, but `config/**` is git-ignored in this repo, so the files are NOT committed: keep a copy (they are needed to build, see docs/store/release-checklist.md).
7. Sign in on the app, then call `GET /user/token` (e.g. via Bruno) with the app's token. This confirms the API accepts tokens issued to the new client. The API checks HS256 tokens for audience `https://bpj.org.uk`.

### Testing before step 1 is done
Debug builds have a **"Developer: sign in with access token"** option on the sign-in screen:
1. Sign in at https://bpj.org.uk/profile.
2. In DevTools, copy `localStorage['bpj.token']`.
3. Paste it into the app.

The token can't be refreshed, so you'll need a new one when it expires.

## Local API for the emulator

The Android emulator reaches your PC at `10.0.2.2`. Start the API with:
```bash
php -S 0.0.0.0:8000 -t public
```
- Run this from `api/`, with a local `.env` and DB.
- Run `php artisan migrate` first so the `/app` tables exist.
- Dev builds point at `http://10.0.2.2:8000`. To test against production instead, use `config/prod.json`, but only once the `/app` endpoints have been deployed there.

## Deploying the API changes

The FTP deploy doesn't run migrations. After the `/app` endpoints are pushed, run this on the host:
```bash
php artisan migrate --force
```
This creates `clubs` (with BPJ seeded), `club_members`, `member_logins` and `member_link_attempts`. It also links everyone who already registered on the website.

### Phase 5 schema and push settings (manual SQL)

The host applies schema by hand (it can't run `migrate`). For Phase 5 notifications, run
`api/database/manual/2026_10_notifications_v2.sql` **after** the earlier manual files
(`2026_10_app_tables.sql`, `2026_10_runs_tables.sql`, `2026_10_groups_tables.sql`). It adds
`notifications.dedupe_key` and `push_requested_at`, the `member_series_prefs` table and
`member_preferences.push_daily_cap`, and records the three `2026_10_10_*` migrations as run. Run it once only
(the ALTER/CREATE statements fail the second time). Existing rows are untouched.

### Phase 6 schema (manual SQL)

For group messaging, run `api/database/manual/2026_10_messages_tables.sql` **after**
`2026_10_notifications_v2.sql` (and the earlier manual files). It creates `group_messages` and
`group_thread_states` and records the two `2026_10_12_*` migrations as run. Run it once only (CREATE TABLE fails
the second time). Nothing else changes; the "Group messages" notification category already exists.

### Runs v2 schema (manual SQL, 2026-10-13 tweaks)

For optional run length and series images, run `api/database/manual/2026_10_runs_v2.sql` **after**
`2026_10_messages_tables.sql` (and the earlier manual files). It makes `session_series.duration_min` nullable and
adds `session_series.image_url` and `sessions.has_end`, and records the three `2026_10_13_*` migrations as run.
Run it once only (ADD COLUMN fails the second time). Existing rows are untouched. To give a series a picture
straight in the database, set `updated_at` too so phones pick it up:
`UPDATE session_series SET image_url='https://…', updated_at=NOW() WHERE title='Monday club run';`

### Member profile card schema (manual SQL, Phase 6.5a)

For profile photos, bios and goals, run `api/database/manual/2026_10_member_profiles.sql` **after**
`2026_10_runs_v2.sql` (and the earlier manual files). It creates `member_profiles` and `member_photos` (a
`MEDIUMBLOB` holding one small JPEG per member) and records the two `2026_10_14_*` migrations as run. Run it once
only (CREATE TABLE fails the second time). Checks on the host:
- **`APP_KEY` must be set** in the host's env file (any long random string; it is used as written, so a `base64:`
  prefix is simply part of the secret). Photo links are signed with it. With no `APP_KEY` the API issues no photo
  links at all (`photoPath` stays `null`). Changing it later makes every existing photo link stop working until the
  app next refreshes member cards or the profile.
- **PHP upload limits:** `upload_max_filesize` and `post_max_size` must be at least `1M` (the app sends about
  40 KB and the API accepts up to 400 KB, but some hosts default to a tiny limit). Over the limit the API answers
  422 on `photo` ("too large").
- `fileinfo` and `gd` are **not** needed: the API checks the JPEG header with PHP's built-in
  `getimagesizefromstring`, and the phone does the resizing.
- MySQL's `max_allowed_packet` should be at least `1M` (almost always true).

Optional host `.env` setting: `FCM_ACTION_BUTTONS=false` turns the reminder action buttons off. Those
notifications then go out as plain `notification` messages (tapping opens the run). It is on by default.

**First real push check (D37).** FCM has only been tested against mocks so far. Once the SQL is applied, the
service-account file is in place (see Firebase below) and the member has signed in on a phone, run from `api/`:
```bash
php artisan app:send-test-push 1 <athleteId>
php artisan app:send-test-push 1 <athleteId> --actions --session=<sessionId>
```
The second form sends a run reminder with going / not going buttons. Both run synchronously and print how many
devices the member has, whether FCM is configured, and whether `pushed_at` was set. If it says "not set", check
`FCM_SERVICE_ACCOUNT_PATH` and the host log.

### Events schema and parkrun list (manual SQL, Phase 8a)

For parkrun tourism and race events, run `api/database/manual/2026_10_events.sql` **after**
`2026_10_posts_author_nullable.sql` (and so after all the earlier manual files). It creates `event_locations` and
adds `session_groups.location_id`, and records the two `2026_10_16_*` migrations as run. Run it once only (CREATE
TABLE / ADD COLUMN fail the second time). Existing rows are untouched.

The list of parkruns is filled by a host command. You download parkrun's public events file by hand (the app never
fetches it): open `https://images.parkrun.com/events.json` in a browser and save it as `events.json` (about 2 MB;
if that address changes, search for "parkrun events.json"). Put it next to the API on the host, then run from `api/`:
```bash
php artisan app:import-event-locations 1 /path/to/events.json --dry-run   # shows counts, writes nothing
php artisan app:import-event-locations 1 /path/to/events.json             # UK parkruns (country code 97)
php artisan app:import-event-locations 1 /path/to/events.json --country=42   # another country by parkrun code
php artisan app:import-event-locations 1 races.csv --kind=race            # a hand-made list
```
- `1` is the club id. The file may be the usual `{"events":{"features":[…]}}` or a plain `{"features":[…]}`.
- A `.csv` file needs the header `name,slug,country,region,lat,lng,url` (only `name` and `slug` are required).
- It prints `Created N, updated N, unchanged N, skipped N.` Run it again whenever parkrun adds events: it matches by
  `slug`, updates names and positions, and never deletes. A location the committee deleted in the app stays deleted.
- Races and other places are added by members in the app (Phase 8b); only the committee adds `parkrun` locations.

### Days I may lead (manual SQL, leader prompts)

For "days I may lead" and the new leaders-needed audience, run `api/database/manual/2026_10_lead_days.sql` **after**
`2026_10_events.sql` (and so after all the earlier manual files). It adds `member_preferences.lead_days` and records
the `2026_10_17_*` migration as run. Run it once only (ADD COLUMN fails the second time). Existing rows are untouched
(`NULL` = the member never chose days). Deploy the API before the app version that sends `leadDays`.

### Runs I follow (manual SQL and data migration, D117)

Order of work, from the build plan:
1. Deploy the API (FTP on push), then run `api/database/manual/2026_10_follows.sql` **after** `2026_10_run_days.sql`.
   It makes `member_series_prefs.reminders` nullable, adds `member_series_prefs.mode` and
   `member_preferences.follows_migrated_at`, and records the `2026_10_19_*` migration as run. Run it once only.
   From this point the feed endpoint, reminders, group-match notices and the leaders-needed audience all read the new
   modes. Members not migrated yet are read through the migration mapping, so nothing changes for them until step 2.
2. On the host: `php artisan app:migrate-follows --dry-run` prints how many member/series pairs each mapping rule
   covers and writes nothing. When the counts look right, run `php artisan app:migrate-follows`. It is safe to run
   twice: migrated members are skipped. The old `reminders` values and `run_days` stay in place.
3. Ship the app version with My runs / All runs and Runs I follow. Release note: members who chose days now get
   reminders for every run of the series on those days (they were only reminded about runs they usually went to).
4. Later, once older app versions are rare, remove the old `runDays` handling and the `run_days` column (not done yet).

## Sharing test APKs

1. **Create an upload keystore once and back it up.** If it's lost, updates can't be signed.
   ```bash
   keytool -genkey -v -keystore %USERPROFILE%\bpj-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Build the APK:
   ```bash
   flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
   ```
3. Share it either way:
   - **Firebase App Distribution** (free). Testers get an email and are told about updates.
   - Send `build/app/outputs/flutter-apk/app-release.apk` directly. Testers need to allow "install unknown apps".

## Testing the MVP on your phone

The `/app` endpoints have to be live before the app can sign in and link
membership against production:

1. Merge the API changes to `master`. The FTP deploy uploads them.
2. On the host, run `php artisan migrate --force` (see above).
3. Build the APK:
   ```bash
   flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
   ```
   Until `android/key.properties` exists, the release build is signed with the
   debug key. That's fine for a few testers, but those installs won't upgrade to
   a keystore-signed build later without uninstalling first.
4. Copy `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (about 23 MB) to the phone and install it. Modern phones use arm64.

To check whether the API accepts tokens from the new Auth0 client:
1. Sign in on the app.
2. If `/app/me` returns 401, the API's HS256 secret doesn't match the tokens the
   Native app receives. Check that `AUTH0_CLIENT_SECRET` on the host is the
   **API's signing secret** (Auth0 → APIs → `https://bpj.org.uk` → Settings), not
   the SPA's client secret.

## Firebase (Phase 2: push notifications)

Only Firebase Cloud Messaging is used. It's free.

1. In https://console.firebase.google.com, create a project called "BPJ App". You
   can turn Analytics off.
2. Add an **Android app** with package `uk.org.bpj.app`. Add an **iOS app** with
   bundle id `uk.org.bpj.app` (the iOS app is needed later).
3. **App config.** The app reads Firebase settings from `config/*.json` rather
   than from `google-services.json`. Copy these from Project settings → Your apps:
   - `FIREBASE_API_KEY`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_ANDROID_APP_ID`
   - `FIREBASE_IOS_APP_ID`

   These are public identifiers, not secrets. Push stays off while they're empty.
4. **Server key:**
   - Go to Project settings → Service accounts → **Generate new private key**.
   - Upload the JSON to the API host **outside the public web root**.
   - Set `FCM_SERVICE_ACCOUNT_PATH=/absolute/path/to/file.json` in the host's `.env`.
   - **Never commit this file.**
5. **Host cron** must run `php artisan schedule:run` every minute. That drains
   the `notifications` queue and runs `app:send-reminders` every 10 minutes (run reminders and
   leaders-needed alerts; it is safe to run late, twice or by hand). No other setup is needed.
6. **iOS (later):** this needs the Apple Developer Program.
   - Create an APNs auth key (.p8).
   - Upload it in Firebase → Project settings → Cloud Messaging → Apple app configuration.

### Granting committee / leader roles
Posting club updates needs the `committee` or `admin` role. Run this on the host
(see `api/readme.md` for the exact arguments):
```bash
php artisan app:member-role 1 <athlete> committee
```

## Releasing

Signing key backup, version numbers, building the APK and app bundle, Firebase App Distribution, Google Play closed
testing and the pre-release checklist are in [store/release-checklist.md](store/release-checklist.md). Policy and store
text are in [store/](store/README.md).
Note: the upload keystore already exists at `android/upload-keystore.jks` (with `android/key.properties`, both git-ignored),
so the keytool step under "Sharing test APKs" only applies if you ever need to make a new one.
