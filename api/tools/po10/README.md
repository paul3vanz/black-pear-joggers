# Power of 10 tooling

One-off tooling for the powerof10.uk migration. The nightly scrape itself lives
in the API (`app/Services/PowerOfTenClient.php`); these scripts exist to explore
the site and to build the athlete id mapping the API needs.

## Background

Power of 10 rebuilt their site in 2026. Three things changed:

1. Athlete ids went from integers (`450606`) to GUIDs
   (`cefdba18-0a6e-4a8c-b204-f9dcc855b5e0`). Integer URLs now return
   "This athlete could not be found", and nothing on the new site is keyed by
   UKA URN, which is what the old scraper looked athletes up by.
2. Every JSON endpoint sits behind Google reCAPTCHA. `GetAthletePerformances`,
   `RunAthleteSearch` and the club rankings searches all answer
   `{"status":"RECAPTCHA_REQUIRED"}` to an unattended client, and a real browser
   gets the same response before it runs the challenge.
3. runbritainrankings.com is gone. `runners/profile.aspx` returns "Not Found"
   and the domain redirects to powerof10.uk.

The reCAPTCHA turned out not to matter. Server-rendered pages are not protected,
and the athlete page embeds everything we need as JavaScript literals, including
a copy of the very payload the gated endpoint would return:

| What | Where | Covers |
| --- | --- | --- |
| `let gridData = {...}` | athlete page | the `GetAthletePerformances` response, `status: "OK"`, most recent year holding data per tab |
| `var dataRp*<n>` | athlete page | full multi-year history per charted event |
| `hcapHistData` / `hcapHistDates` | athlete page | runBritain handicap history |
| `/Images/Athletes/<id>.jpg` | athlete page | the legacy integer athlete id |

So one plain HTTP GET per athlete replaces the two requests the old code made,
and no reCAPTCHA is involved.

## Scripts

Both are dependency free (standard library only) and need Python 3.8+.

### po10_scrape.py

Reference implementation of the parsing, and the quickest way to see what the
site currently returns for an athlete. The PHP in `PowerOfTenClient` mirrors it.

```bash
python po10_scrape.py cefdba18-0a6e-4a8c-b204-f9dcc855b5e0
```

Prints a summary and writes `athlete_<prefix>.json`.

### po10_discover.py

Snowballs through server-rendered results pages, harvesting club members from
meetings a known athlete appeared in.

```bash
python po10_discover.py "Black Pear Joggers" cefdba18-0a6e-4a8c-b204-f9dcc855b5e0 3
```

This is what produced the first 135 GUIDs, but it plateaus there and cannot get
much further. An athlete page only carries meeting ids for the most recent year
that holds data, about nine meetings, so 135 athletes between them expose only
214 meetings and almost all of them are current season. Members who stopped
racing years ago are unreachable: finding their races needs a meeting from that
era, and the only way to get one is to already know somebody who ran it. Use
the capture route below instead.

### The recommended route: club rankings, then a free crawl

Athlete-by-athlete search works but costs one reCAPTCHA-gated request per
member, about 1400 of them, and the invisible challenge escalates to image
puzzles after four or five in a row. Use this instead. It needs 84 gated
requests rather than 1400, and everything after that is free.

**Step 1 - club rankings (browser, ~84 requests).** Club rankings are gated too,
but one request covers a whole year of the club, and the year list goes back to
2006. That is the part the old crawl could never reach.

```bash
python po10_build_rankings_capture.py po10_rankings_capture.js
```

Open the club page, paste the file into the console, leave it running. Queries
go oldest year first, because recent members are the ones we already have.
Progress survives a reload. It downloads `po10_rankings.json`.

Each ranking row carries the athlete GUID (`athid`) **and** the meeting GUID
(`mtid`), and that second one is what makes the rest free.

**Step 2 - crawl the meetings (no reCAPTCHA at all).**

```bash
python po10_crawl_meetings.py po10_rankings.json bpj_athletes_all.json --rounds 2
```

Meeting results pages are server rendered and list every competitor with their
club, so each meeting hands over every club member who ran it. Those athletes'
pages then yield more meetings from the same era, and it goes round again.
Writes `po10_discovered.json` and a `po10_candidates.json` for step 3.

Running this over just the 214 meetings already reachable from the 135 known
athletes found 234 club athletes, 87 of them roster members with no GUID, of
which 56 verified automatically. That was before any rankings capture at all.

**Step 3 - verify.** Never load a name match unattended; a wrong GUID silently
grafts another runner's results onto a member.

```bash
python po10_match.py po10_candidates.json bpj_athletes_all.json
```

| Signal | Strength | Availability |
| --- | --- | --- |
| legacy id from the profile photo path | conclusive | ~3% of athletes |
| our stored performance, same date and time | strong | ~50% |
| our stored runBritain handicap agrees | strong | ~65% |
| first, second or other claim club is ours | supporting | current members only |

The handicap is the workhorse. We record it on the night the cron ran and the
rebuilt site samples it at change points, so the dates never line up; the check
compares our value against their last reading at or before our date and allows a
tenth or two of drift. It is a continuous one-decimal number, so agreement is
hard to get by chance.

Writes `matches.json` (safe to load) and `review.csv` (everything else, with a
link straight to the athlete page). On a 40 athlete ground-truth run against
GUIDs already known to be correct, 33 were confirmed automatically with **no
false positives**, and the other 7 fell to review.

Get the full roster first; the default endpoint is filtered to affiliated
members and returns 422 of 1555:

```bash
curl "https://bpj.org.uk/api/public/index.php/athletes?includeAllMembers=1"   -o bpj_athletes_all.json
```

### po10_build_capture.py - the fallback

Same idea but one search per athlete, by first name and surname. Only worth
running for whoever is still missing after the route above, since searching by
name is the only way to find someone whose Power of 10 club is no longer ours.

```bash
python po10_build_capture.py bpj_athletes_all.json po10_capture.js 600
```

Paste into the console on <https://www.powerof10.uk/Home/AthleteSearch>. Expect
an image challenge every few searches, so keep the list short.

## Known limitation

The progression charts cover road and track only. Cross country and race walk
performances appear in `gridData` but have no chart series, so for those we only
see the most recent year that has data. Full XC history would need the gated
endpoint.

Chart meeting names are also capped at 30 characters (about a tenth of them are
truncated, `"Worcester Pitchcroft parkru..."`). The API treats a truncated name
as a prefix match so it neither duplicates the meeting nor overwrites a good
full name.
