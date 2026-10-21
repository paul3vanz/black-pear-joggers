# Data model

Server tables live in the existing MariaDB behind the Lumen API (`api/`). The app
keeps a Drift/SQLite mirror of the subset each user needs (see
[architecture.md](architecture.md#offline-first)).

## Conventions (new tables only)

- **Every row carries `club_id`.** Rows that belong to a person also carry
  `member_id` (a `club_members.id`), which pins them to one user *in one club*.
  Never query new tables without a `club_id` filter.
- **IDs are UUIDs** (ordered, `Str::orderedUuid()`), so the app can create rows
  offline and replay them idempotently.
- **`created_at` / `updated_at` / `deleted_at`** (soft deletes) on everything the
  app syncs, so `?since=` delta sync can return tombstones.
- **snake_case columns.** Existing tables are mixed (`users.athleteId`,
  `athletes.first_name`); leave those alone.
- Times are stored in **UTC**; recurrence is expanded in the club's timezone
  (`Europe/London`) so BST changes land correctly.

## Identity & clubs

```
users            (existing) id = Auth0 `sub`, athleteId     ← used by web apps; leave as is
clubs            id, name, slug, ea_club_id (1606 for BPJ), timezone, join_url, settings json
club_members     id, club_id, athlete_id, display_name, roles json ['leader','committee','admin'],
                 status('active','lapsed')                   unique(club_id, athlete_id)
member_logins    id, club_id, member_id, user_id (Auth0 sub), linked_at
                                                             unique(club_id, user_id)
```

- A **user** is one Auth0 login.
- A **member** is one *person* in one club, keyed by their athlete record.
- **Several logins can map to one member.** For example, Google on the web and
  Facebook in the app both resolve to the same `club_members` row, so RSVPs and
  preferences don't get split between them.
- One user can be a member of several clubs, and one device can hold several
  users (partners).
- The app's "context" is always `(user_id, club_id)`, which `member_logins`
  resolves to one `club_members` row.
- Roles live here (per club), **not** in Auth0 permissions. Existing Auth0
  permissions (`members:read`, `athletes:admin`, …) keep working for the web admin.
  - Every linked member can offer to lead.
  - `leader` is a badge the committee gives to qualified leaders.
  - `committee` and `admin` unlock management screens.
- `status` follows EA registration and payments (`Athlete::active`), refreshed by
  the existing 6‑hourly membership sync. **Only linked members can use club
  features for now.** Lapsed or unlinked users see the link screen and the join
  link. Trial runners are a later extension.

## Club runs: series → sessions (Outlook-style recurrence)

```
venues           id, club_id, name, address, lat, lng, notes
session_series   id, club_id, title, description, venue_id, weekday, start_time (local),
                 duration_min, interval_weeks (1), valid_from, valid_until?,
                 group_mode('paced','single','open','routes'), default_groups json, cms_slug?
sessions         id, club_id, series_id?, occurrence_date?, starts_at, ends_at, venue_id,
                 title, notes, group_mode, coordinator_member_id?, status('scheduled','cancelled'),
                 cancel_reason?, is_detached bool           unique(series_id, occurrence_date)
```

- A nightly job **materialises sessions 8 weeks ahead** from each series. Concrete
  rows make RSVPs, leader sign-ups and offline sync simple (no client-side
  recurrence maths).
- **Edit one occurrence** (bank holiday: different venue, earlier time) → update that
  `sessions` row and set `is_detached = true` so regeneration leaves it alone.
- **Cancel one occurrence** → `status = 'cancelled'` (kept, so attendees get told).
- **Edit the series** → future, non-detached occurrences are regenerated ("this and
  following" in Outlook terms).
- **Ad-hoc run** (Christmas, socials) → a `sessions` row with `series_id = null`.
- **Seasonal runs** (Thursday Mug Run in summer, Perdiswell in winter) → two series
  with non-overlapping `valid_from`/`valid_until`. Copying a series for next season
  is a quick admin task; we can add yearly-repeating windows later if it's a chore.
- `group_mode` drives the UI:
  - `paced`: Mon/Tue/winter Thu. Leaders add pace groups.
  - `single`: Wednesday track. One group created from `default_groups`.
  - `open`: Mug Run. Everyone starts together; members can still say "I'll run
    ~9:00/mi, join me" as an informal group.
  - `routes`: Sunday long runs. A **coordinator** (`sessions.coordinator_member_id`)
    sets routes such as 10 mi and 16 mi as `route` groups with no leaders.
    Attendees pick a route and their pace *for that run*, and can see the pace
    spread of everyone else on the route.

`cms_slug` links to the Sanity `clubRun` page (`/club-runs/{slug}`) for the long
description, so we don't duplicate marketing copy.

## Groups, leaders, attendance

```
session_groups         id, club_id, session_id, kind, label?, description?,
                       pace_unit('mi','km')?, pace_from_s?, pace_to_s?,
                       distance_value?, distance_unit('mi','km')?,
                       status('active','needs_leader'), sort_order, created_by_member_id
session_group_leaders  id, club_id, group_id, member_id, role('leader','co_leader','backmarker'),
                       status('confirmed','withdrawn'), withdrawn_at?
session_attendees      id, club_id, session_id, member_id, group_id?, status('going','maybe','not_going'),
                       pace_unit?, pace_from_s?, pace_to_s?   (this run only; defaults to profile)
                       unique(session_id, member_id)
```

### A group is a pace, a distance and a description, each optional

A leader describes a group with independent, optional parts:

| Part | Options | Example |
|---|---|---|
| **Pace** | none · single · range | none · 9:30/mi · 9:00-9:30/mi |
| **Distance** | none · a distance | 3 mi · 5 km |
| **Kind** | `run` (default) · `jog_walk` · `efforts` · `route` · `social` · `other` | picks the icon and label |
| **Label / description** | free text | "Jog/walk, 3 miles" · "6 x 400 m, 90 s recovery" · "Faster runners muster back at the bridge" |

- **Single pace** = `pace_from_s` only: the group aims to run close to that pace.
- **Range** = `pace_from_s` (the faster end) and `pace_to_s` (the slower end). The
  leader supports a wider spread, and the description can say where faster
  runners muster back to pick up the slower ones. `pace_from_s <= pace_to_s`
  always, because a smaller number of seconds is faster.
- **No pace** (jog/walk, efforts, a social run): leave the pace empty. The kind and
  the description explain the group.
- **Distance** can sit alongside a pace, replace it, or be left out.
- A group needs no pace, no distance and no label. `kind` and the description are
  enough.

There is no fixed list of formats to extend. A new kind of session (hill reps, a
C25K week) is a `kind` value and a description, so adding one doesn't change the
database or the pace maths.

In Dart this is a small value object (`GroupSpec`: optional `Pace` that is either
single or a range, optional `Distance`, `kind`, text) rather than a class per
format. `Pace` and `Distance` hold the value as entered plus the unit and expose
conversions.

### Units: stored as entered, shown in the viewer's units

- **Paces and distances are stored as entered, with their unit** (`570` + `mi` =
  9:30/mi; `3` + `mi` = 3 miles). A leader's "8:00/mi" never comes back as
  "7:59/mi" and "3 mi" never becomes "4.83 km".
- The API also returns **canonical** values for sorting and matching
  (`paceFromSPerKm`, `paceToSPerKm`, `distanceM`). They're derived on the fly and
  never stored. `1 mi = 1.609344 km`.
- **Pace and distance units are separate member preferences.** Many runners think
  in minutes per mile and distances in km (or the reverse). Each person sets both
  in their profile, and the app shows every pace and distance in their units,
  with the leader's original in small text when it differs, e.g. "5:35/km (9:00/mi)".
- Converted paces round to the nearest second. Entry is `m:ss` per mile or per km.

### Visibility and permissions

- **Leader names are public** (members see which leaders have confirmed groups).
- **Attendee names** are visible to the group's leaders, the session coordinator
  and committee. Everyone else sees counts and an anonymous spread of paces.
- **Any linked member can lead** (D12): they create a group with themselves as
  leader, or join an existing group as co-leader. The `leader` role is a badge the
  committee awards; it doesn't gate leading.
- **Leaderless groups** are created by the committee or the session's
  coordinator (e.g. Sunday route groups).
- **Edit or delete a group**: its leaders, the session coordinator, committee.
- **Set the coordinator and roles**: committee (granting `committee` or `admin`
  needs `admin`).

### Attendance

- `group_id = null` + `going`: "I'm coming, haven't picked a group". Committee
  sees these alongside each member's pace to spot gaps (Phase 5 notifies matching
  leaders).
- `maybe`: counted separately from `going`.
- `not_going`: stops reminders for that session.
- A member's pace for one run defaults to their profile range and can be
  overridden on that attendance row (e.g. "faster than usual on Sunday").
- Attendance can't change once a session has ended (409 `session_past`), or if it's
  cancelled (409 `session_cancelled`).

### A leader withdrawing

The leader row goes to `withdrawn`, but the group and its attendees are kept. If
it was the last confirmed leader and the session expects leaders (`paced` or
`single` mode), the group becomes `needs_leader`. Phase 5 then asks attendees and
leaders whose pace fits to step in. Route groups never need leaders.

## Member preferences & notifications

```
member_preferences        member_id, club_id, pace_unit, distance_unit, pace_from_s?, pace_to_s?,
                          push_daily_cap, lead_days?, run_days?   (ISO weekdays "1,3"; lead ⊆ run, D115),
                          follows_migrated_at?   (run_days is kept only for older apps, D117)
member_series_prefs       member_id, club_id, series_id, mode('follow','auto','hide')?, reminders?
                          (one choice per series for My runs AND reminders, D117; no row = auto;
                          `reminders` on/off is the pre-D117 value, read only for unmigrated members)
notification_preferences  member_id, club_id, category, push_enabled
devices                   id, user_id, fcm_token unique, platform, app_version, last_seen_at
notifications             id, club_id, member_id, category, title, body, data json (deep link),
                          created_at, read_at?, pushed_at?
posts                     id, club_id, author_member_id, title, body_md,
                          priority('normal','important'), audience('all','leaders','committee'),
                          published_at, pinned_until?
```

- `devices` hangs off **user**, not member: one phone has one FCM token, and every
  push payload carries `club_id` + `user_id` so tapping it opens the right
  context. To notify a member, the server looks up all their `member_logins`,
  then all those users' devices.
- `notifications` is the in-app inbox. Push only nudges the user; the message is
  still there to read if the push was missed or muted.
- Categories (each can be opted out):

| category | sent when | default |
|---|---|---|
| `club_updates` | committee publishes a post | on (`important` posts can't be turned off) |
| `run_reminders` | upcoming run, unless replied `not_going` or opted out of that series | on |
| `group_matches` | a group in your pace range is added to a run you're going to (or might) | on |
| `my_group_changes` | your group or run is cancelled or moved, or its leader withdraws | on (can't be turned off) |
| `leaders_needed` | gaps on runs, for leaders only | on |
| `group_messages` | new message in a group you've joined | on |

## Update receipts

```
post_receipts   id, club_id, post_id, member_id, delivered_at?, read_at?   (unique post_id + member_id)
```

One row per member per update, written by the member's own app (D123). No row means neither has happened. The
committee reads them back; members only ever write their own.

## Update comments

```
post_comments       id, club_id, post_id, member_id, body, created_at, updated_at, deleted_at?
post_thread_states  id, club_id, post_id, member_id, last_read_at?, muted   (unique post + member; a row = opened the thread)
posts.comments_closed_at  timestamp?  (the committee closed comments)
```

A Q&A thread under each club update (D126), reusing the group chat's shapes.

## Leaders threads

```
leader_messages         id, club_id, session_id, member_id, kind(message|ask), body, ask_fast_s_per_km?, ask_slow_s_per_km?, renudged_at?, created_at, updated_at, deleted_at?
leader_thread_states    id, club_id, session_id, member_id, last_read_at?, muted   (unique session + member)
leader_thread_members   id, club_id, session_id, member_id                         (unique session + member)
```

One thread per run for the committee and the people who lead or were asked to lead it (D125). It reuses the group
chat's shapes; `leader_thread_members` is who an ask went to.

## Later: group messaging

```
group_messages   id, club_id, group_id, member_id, body, created_at, edited_at?, deleted_at?
```

There's one thread per `session_group`. The app fetches it with a `?since=` delta
and polls while the thread is open, and push covers new messages otherwise. We
don't need websockets.
