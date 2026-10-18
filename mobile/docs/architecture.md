# App architecture

## Stack

Each tool is listed next to the nearest thing in the React/TS world.

| Concern | Choice | Closest React/TS equivalent |
|---|---|---|
| Language | Dart 3 (sound null safety, records, sealed classes, pattern matching) | TS in `strict` mode, with discriminated unions + exhaustive `switch` |
| UI | Flutter widgets, Material 3 | React components. `build()` ≈ render, `StatelessWidget` ≈ pure function component |
| State / data fetching | **Riverpod** (`flutter_riverpod` + `riverpod_generator`) | React Query + Zustand/Context. `ref.watch` ≈ `useQuery`/`useContext`, `AsyncValue` ≈ `{data, error, isLoading}` |
| Routing | **go_router** | React Router / Next routes. `redirect` ≈ middleware auth guard |
| Local DB | **Drift** (typed SQLite, migrations, reactive `.watch()` queries) | Drizzle/Prisma on SQLite, plus live queries |
| HTTP | **dio** with interceptors | axios with interceptors |
| JSON models | `json_serializable` | zod-generated types (codegen, no runtime validation) |
| Auth | **auth0_flutter** (Universal Login in system browser, PKCE, refresh tokens) | `@auth0/auth0-react` |
| Secrets on device | `flutter_secure_storage` (Keychain / Android Keystore) | none (the web uses localStorage) |
| Markdown | `flutter_markdown_plus` (the successor to the discontinued `flutter_markdown`) | `react-markdown` |
| Push | **Firebase Cloud Messaging** (`firebase_messaging`) + `flutter_local_notifications` | Web Push / Expo push |
| Codegen | `build_runner` (`dart run build_runner watch -d`) | graphql-codegen / prisma generate |
| Lint / format | `flutter_lints`, `dart format` | ESLint / Prettier |
| Tests | `flutter_test` (unit + widget), `integration_test` | Jest + RTL / Playwright |
| Package manager | `pubspec.yaml`, `flutter pub add x` | `package.json`, `npm i x` |

Prefer plain Dart 3 features (sealed classes, records, `switch` expressions) over
extra codegen packages such as freezed. Only add a package once it's clearly
paying for itself.

## Folder layout (feature-first)

```
lib/
  main.dart                 bootstrap: Firebase, Drift, ProviderScope
  app/                      app.dart (MaterialApp.router), router.dart, theme.dart
  core/
    config/                 ClubConfig + env (API base URL, Auth0 ids), via --dart-define-from-file
    api/                    dio client, auth interceptor, error mapping
    auth/                   Auth0 wrapper, AccountStore (multi-account credentials)
    db/                     Drift database (one file per signed-in account), tables, migrations
    sync/                   outbox + sync service, connectivity hints
    units/                  pure-Dart `DistUnit`, `Pace`, `PaceSpec` (none/single/range), `Distance` (D21)
    notifications/          PushService: Firebase init from config, channels, permission, token registration for every account, foreground display, tap routing
  features/
    <feature>/
      data/                 repository, DTOs, Drift table(s)
      domain/               models (plain Dart), pure logic (e.g. pace maths)
      ui/                   screens, widgets, providers
```

Features: `auth`, `membership`, `profile`, `updates`, `notifications`, `runs`,
`groups`, `settings`, `messages` (group chat: Drift outbox + thread state, chat screen, Inbox list),
`members` (Phase 6.5 profile cards: `MemberCards`/`MemberProfiles` tables, `MemberProfileRepository`, `MemberAvatar` and
`MemberLink` widgets, the `/members/:memberId` page, the `/profile/card` editor and the pure-Dart `processProfilePhoto`),
`events` (Phase 8: `EventLocations` table, `EventLocationsRepository`, the reusable `showEventPicker` sheet and the committee
`/profile/event-locations` screen; `runs/logic/run_modes.dart` holds the events/race mode helpers).

## Offline-first

Every read follows **stale-while-revalidate, persisted**:

1. The UI watches a **Drift stream** (`repository.watchUpcomingSessions()`), so
   cached data shows immediately, even with no signal.
2. The repository **refreshes from the API** when a screen opens, on
   pull-to-refresh, when the app resumes, and when connectivity returns. It
   upserts the results into Drift, and the stream pushes the new rows to the UI.
3. List endpoints accept `?since=<updated_at>` and return changed rows plus
   tombstones (`deleted_at`), so each refresh is cheap.

Every write (RSVP, "not coming", leader sign-up) goes through an **outbox**:

1. Write optimistically to Drift and add an `outbox` row (client UUID, endpoint,
   payload).
2. `SyncService` drains the outbox whenever it's online, retrying with backoff.
   Endpoints are idempotent on the client UUID.
3. The server's response is canonical and overwrites the local row. If the server
   rejects the write (e.g. the run was cancelled), the local row is rolled back
   and the user is told.

Use `connectivity_plus` only as a hint about when to retry. Actual success is
whatever the request returns.

## Auth & accounts

- Universal Login runs in the system browser. The provider buttons (Google,
  Facebook, email/password) come from the Auth0 tenant, as on the web.
- Request `audience=https://bpj.org.uk` and scopes `openid profile email offline_access`.
- **Long sessions:** use refresh-token rotation with a long absolute lifetime and
  an inactivity timeout (e.g. 365 days / 90 days). The dio interceptor renews the
  access token before it expires and retries once on a 401.
- **Multiple accounts on one device:** `AccountStore` keeps credentials **per
  Auth0 `sub`** in secure storage, and renews them with
  `auth0.api.renewCredentials`. auth0_flutter's built-in CredentialsManager only
  holds one account, so it isn't used. "Add another account" passes
  `prompt=login` so the browser doesn't quietly reuse the current session.
- **Context = (user, club).** Each account gets its **own Drift database file**,
  so partners' data never mixes. The active club is chosen inside the account.
  Switching context swaps the DB and invalidates the Riverpod providers.
- Push payloads carry `user_id` + `club_id`. Tapping one switches context if
  needed, then deep-links.

## Notifications

- **FCM is the only third party, and it's free.** Android push needs it anyway
  (Google Play services), and on iOS it wraps APNs. Only Cloud Messaging is used:
  no Firebase Auth or Firestore.
- The app registers its FCM token with `POST /app/devices` after sign-in and
  removes it on sign-out. The token belongs to the user, not the club.
- The OS permission prompt appears **after membership is linked**, explaining
  why, rather than on first launch. Android 13+ and iOS both need this runtime
  permission.
- **The server decides who gets what.** It applies category preferences, series
  opt-outs and pace matching. Each push is backed by a row in the
  `notifications` inbox, so nothing is lost if a push is missed.
- Notification actions (e.g. "Not coming") call the API directly from the
  background handler.

## Environments & config

- `config/dev.json` and `config/prod.json` are passed with
  `--dart-define-from-file`. They hold the API base URL, Auth0 domain/client id
  and club id. They contain no secrets: the Auth0 client id is public.
- `ClubConfig` holds the name, colours, logo, join URL and EA club id. White-label
  apps later become Flutter **flavors** that each supply a `ClubConfig` and their
  own app id.
