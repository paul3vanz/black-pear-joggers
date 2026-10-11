# BPJ mobile app (Flutter)

Members' and leaders' app for Black Pear Joggers. It shows club updates with push
notifications, the club runs schedule, and pace groups (leaders sign up, members
RSVP). It works offline. It's built on the existing Lumen API (`../api`) and
Auth0 tenant.

**Read on demand, not every session:**
- [docs/ROADMAP.md](docs/ROADMAP.md): phases, current progress, open questions. **Check here first for what's next.**
- [docs/architecture.md](docs/architecture.md): stack, folder layout, offline/auth/push patterns
- [docs/data-model.md](docs/data-model.md): server tables, recurrence, group formats, notification categories
- [docs/decisions.md](docs/decisions.md): decision log (D1…)
- [docs/api-contract.md](docs/api-contract.md): `/app` endpoint shapes shared with `../api`. Update it when an endpoint changes.
- [docs/setup.md](docs/setup.md): manual setup (Auth0 dashboard, local API, deploy migrations, APK sharing)

## Non-negotiables

- **Club-scoped data:** every new server table has `club_id`. Personal rows also
  have `member_id`. The app context is always (user, club).
- **Offline-first:**
  - UI reads Drift streams, never awaits the network to render.
  - Writes go through the outbox with client UUIDs.
- **One Drift DB file per signed-in account.** Never mix users' data.
- **Paces are stored as entered** (`pace_unit` + seconds) and only converted for
  display or matching.
- **No secrets in the app.** `config/*.json` holds only public ids and URLs.

## Working notes

- The owner is strong in React/TS and new to Dart. When explaining Flutter or
  Dart concepts, relate them to React/TS equivalents.
- Use Dart 3 features (sealed classes, records, `switch` expressions) before
  adding codegen packages.
- Commands (from the Flutter project root):
  - `flutter pub get`
  - `dart run build_runner watch` (generated `*.g.dart` files are committed)
  - `flutter run --dart-define-from-file=config/dev.json`
  - `flutter test`
  - `dart format .`
  - `flutter analyze`
- Android emulator → local API: `http://10.0.2.2:8000` (API run with `php -S localhost:8000 -t public`).

## Keeping context current

When a phase item lands:
- Tick it in ROADMAP.md.
- Add a decision to decisions.md if one was made.
- Update this file only if a convention or command changed.

Keep this file short and put detail in `docs/`.
