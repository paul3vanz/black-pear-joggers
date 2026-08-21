#!/usr/bin/env python3
"""
POC: build a legacy-athlete-id -> powerof10.uk GUID mapping WITHOUT reCAPTCHA.

The athlete search endpoint is reCAPTCHA-gated, but RESULTS pages are fully
server-rendered and list every competitor as
    <a href="/Home/Athlete/{guid}">Full Name</a> ... {age group} ... {club}

So we snowball:
  1. seed with any known athlete GUID(s)
  2. read that athlete's meeting GUIDs (mtid) out of the embedded gridData
  3. fetch each meeting's results page, harvest (guid, name, club) for our club
  4. those new athletes yield more meetings -> repeat

Matching back to our database:
  * exact  - athletes with a profile photo expose /Images/Athletes/<legacyId>.jpg
             which IS our athletes.athlete_id (verified: 450606 = Paul Evans)
  * name   - everyone else matches on normalised first+last name within the club

Usage: python po10_discover.py <club name> <seed guid> [rounds]
"""
import json, re, sys, unicodedata
from collections import OrderedDict

from po10_scrape import fetch, BASE, parse_grid_data


def norm_name(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z ]", "", s.lower()).strip()


def harvest_results_page(html):
    """(guid, name, club) for every competitor listed on a results page."""
    out = []
    for m in re.finditer(
            r'href="/Home/Athlete/([a-f0-9-]{36})"[^>]*>\s*([^<]{1,60})', html):
        guid, name = m.group(1), m.group(2).strip()
        # club appears later in the same table row
        tail = html[m.end():m.end() + 1500]
        cm = re.search(r'href="/Home/Club/[a-f0-9-]{36}"[^>]*>\s*([^<]{1,60})', tail)
        out.append((guid, name, cm.group(1).strip() if cm else None))
    return out


def meetings_of(html):
    grid = parse_grid_data(html)
    ids = set()
    if grid and grid.get("perfs"):
        for block in grid["perfs"]["dictpgs"].values():
            for page in block.get("pgs") or []:
                for r in page.get("results") or []:
                    if r.get("mtid"):
                        ids.add(r["mtid"])
    return ids


def crawl(club, seeds, rounds=2, max_meetings=40):
    athletes = OrderedDict()          # guid -> {name, club, legacyId}
    seen_meetings, frontier = set(), list(seeds)

    for rnd in range(rounds):
        meetings = set()
        for guid in frontier:
            html = fetch("%s/Home/Athlete/%s" % (BASE, guid))
            if not html:
                continue
            lid = re.search(r"/Images/Athletes/(\d+)\.jpg", html)
            cm = re.search(r'First Claim Club:\s*([^"]+)"', html)
            nm = re.search(r"<h1[^>]*>\s*([^<]+?)\s*</h1>", html)
            athletes.setdefault(guid, {}).update({
                "name": athletes.get(guid, {}).get("name") or (nm.group(1) if nm else None),
                "club": cm.group(1).strip() if cm else None,
                "legacyId": int(lid.group(1)) if lid else None,
            })
            meetings |= meetings_of(html)

        meetings -= seen_meetings
        meetings = list(meetings)[:max_meetings]
        seen_meetings |= set(meetings)
        print("round %d: %d athletes known, fetching %d meetings"
              % (rnd + 1, len(athletes), len(meetings)))

        new = []
        for mid in meetings:
            html = fetch("%s/Home/Results/%s" % (BASE, mid))
            if not html:
                continue
            for guid, name, ath_club in harvest_results_page(html):
                if ath_club and club.lower() in ath_club.lower():
                    if guid not in athletes:
                        athletes[guid] = {"name": name, "club": ath_club, "legacyId": None}
                        new.append(guid)
                    elif not athletes[guid].get("name"):
                        athletes[guid]["name"] = name
        print("         -> %d new %s athletes" % (len(new), club))
        frontier = new
        if not frontier:
            break
    return athletes


def match(athletes, roster):
    """Match discovered GUIDs to our athletes table."""
    by_legacy = {a["athlete_id"]: a for a in roster}
    by_name = {}
    for a in roster:
        by_name.setdefault(norm_name(a["first_name"] + " " + a["last_name"]), []).append(a)

    exact, named, unmatched = [], [], []
    for guid, info in athletes.items():
        if info.get("legacyId") and info["legacyId"] in by_legacy:
            exact.append((guid, info, by_legacy[info["legacyId"]]))
            continue
        cands = by_name.get(norm_name(info.get("name") or ""), [])
        if len(cands) == 1:
            named.append((guid, info, cands[0]))
        else:
            unmatched.append((guid, info, cands))
    return exact, named, unmatched


ROSTER_URL = "https://bpj.org.uk/api/public/index.php/athletes"
ROSTER_FILE = "bpj_athletes.json"


def load_roster():
    """Our athletes table, from a local cache or the public API."""
    import os

    if os.path.exists(ROSTER_FILE):
        return json.load(open(ROSTER_FILE))

    print("fetching roster from %s" % ROSTER_URL)
    roster = json.loads(fetch(ROSTER_URL))
    json.dump(roster, open(ROSTER_FILE, "w"))

    return roster


if __name__ == "__main__":
    club = sys.argv[1] if len(sys.argv) > 1 else "Black Pear Joggers"
    seed = sys.argv[2] if len(sys.argv) > 2 else "cefdba18-0a6e-4a8c-b204-f9dcc855b5e0"
    rounds = int(sys.argv[3]) if len(sys.argv) > 3 else 2

    athletes = crawl(club, [seed], rounds=rounds)
    roster = load_roster()
    exact, named, unmatched = match(athletes, roster)

    print()
    print("discovered %d %s athletes on powerof10.uk" % (len(athletes), club))
    print("  matched by legacy id (exact) : %d" % len(exact))
    print("  matched by name              : %d" % len(named))
    print("  unmatched / ambiguous        : %d" % len(unmatched))
    print("  roster size                  : %d" % len(roster))
    print()
    for guid, info, a in exact[:5]:
        print("  EXACT %s legacyId=%s %s %s" % (guid, info["legacyId"], a["first_name"], a["last_name"]))
    for guid, info, a in named[:5]:
        print("  NAME  %s %-22s -> athlete_id=%s" % (guid, info["name"], a["athlete_id"]))
    for guid, info, c in unmatched[:5]:
        print("  MISS  %s %-22s candidates=%d" % (guid, info.get("name"), len(c)))

    mapping = {}
    for guid, info, a in exact + named:
        mapping[str(a["athlete_id"])] = {"guid": guid, "name": info.get("name"),
                                         "via": "legacyId" if info.get("legacyId") else "name"}
    json.dump(mapping, open("id_map.json", "w"), indent=1)
    print("\nwrote id_map.json (%d entries)" % len(mapping))
