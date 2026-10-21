# Black Pear Joggers monorepo

Club website, API and mobile app for Black Pear Joggers (Worcester running club).

| Folder | What | Notes |
|---|---|---|
| `api/` | Laravel **Lumen 10** API (PHP 8.2, MariaDB) | Serves every frontend. See `api/CLAUDE.md` |
| `next/` | Nx workspace of **Next.js** apps (cms, profile, register, admin, claim-award…) + Sanity studio | Auth via `@auth0/auth0-react`; shared config in `next/libs/core-services/src/config.ts` |
| `apps/`, `libs/` | Legacy **Angular 12** Nx apps (race-results, club-records, club-standards, magic-mile) | See README for building on modern Node |
| `mobile/` | **Flutter** members' app (in progress) | See `mobile/CLAUDE.md` |

- Production API base: `https://bpj.org.uk/api/public/index.php`. Auth0 tenant `blackpearjoggers.us.auth0.com`, audience `https://bpj.org.uk`.
- `api/` deploys over FTP on push to `master` (`.github/workflows/deploy-api.yml`). `vendor/` is not in git.
- Never commit or print secrets. `api/env` and `.env*` hold live credentials.
