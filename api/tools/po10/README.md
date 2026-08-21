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

Builds the `athlete_id -> po10_guid` mapping for the `athletes.po10_guid`
column.

Athlete search is reCAPTCHA gated, so this snowballs through results pages,
which are server rendered and list every competitor as GUID, name and club:

1. start from a known athlete GUID
2. read their meeting GUIDs out of the embedded `gridData`
3. fetch those results pages and harvest club members
4. repeat, since club members race together

```bash
python po10_discover.py "Black Pear Joggers" cefdba18-0a6e-4a8c-b204-f9dcc855b5e0 3
```

Writes `id_map.json`. The roster is pulled from the public API and cached in
`bpj_athletes.json`.

Matching works two ways:

- **legacy id** (exact): athletes with a profile photo expose their old integer
  id, which is our `athlete_id`. Only about a quarter of athletes have a photo.
- **name** (needs review): everyone else matches on normalised name within the
  club.

A sample run from a single seed found 87 club athletes in 20 seconds and matched
64 of them. Expect some misses: relay team entries appear as athletes, and not
every member has a Power of 10 profile.

**Check the name matches before loading them.** A wrong GUID silently attaches
another runner's results to a member.

## Known limitation

The progression charts cover road and track only. Cross country and race walk
performances appear in `gridData` but have no chart series, so for those we only
see the most recent year that has data. Full XC history would need the gated
endpoint.

Chart meeting names are also capped at 30 characters (about a tenth of them are
truncated, `"Worcester Pitchcroft parkru..."`). The API treats a truncated name
as a prefix match so it neither duplicates the meeting nor overwrites a good
full name.
