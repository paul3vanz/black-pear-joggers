#!/usr/bin/env python3
"""
Expand a club-rankings capture into as many athlete GUIDs as we can, for free.

Meeting results pages are server rendered and carry no reCAPTCHA, and they list
every competitor with their club. The rankings capture hands us meeting GUIDs
spread across twenty years, which is exactly what the old snowball crawl could
never reach: an athlete page only exposes meetings from the most recent year it
holds data for, so there was no way back into 2012.

So: take the meetings from the capture, read every club member out of them, then
use those athletes' own pages to find more meetings from the same era, and go
round again. None of this is gated.

Usage:
    python po10_crawl_meetings.py po10_rankings.json bpj_athletes_all.json
    python po10_crawl_meetings.py po10_rankings.json bpj_athletes_all.json --rounds 3
"""
import argparse
import json
import re
import time
import unicodedata
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor

from po10_discover import harvest_results_page, meetings_of
from po10_scrape import BASE, fetch

CLUB = 'black pear joggers'


def norm(s):
    s = unicodedata.normalize('NFKD', s or '')
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'[^a-z]', '', s.lower())


def meeting_ids_from_capture(capture):
    ids = set()
    for rows in capture.values():
        for r in rows or []:
            if r.get('mtid'):
                ids.add(r['mtid'])
    return ids


def athletes_from_capture(capture):
    out = {}
    for rows in capture.values():
        for r in rows or []:
            if r.get('athid'):
                out.setdefault(r['athid'], {'name': r.get('athn'), 'club': 'Black Pear Joggers',
                                            'source': 'rankings'})
    return out


def scan_meeting(mtid):
    html = fetch('%s/Home/Results/%s' % (BASE, mtid))
    if not html:
        return mtid, []
    found = []
    for guid, name, club in harvest_results_page(html):
        if club and CLUB in club.lower():
            found.append((guid, name, club))
    return mtid, found


def meetings_of_athlete(guid):
    html = fetch('%s/Home/Athlete/%s' % (BASE, guid))
    if not html:
        return set()
    return meetings_of(html)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('capture')
    ap.add_argument('roster')
    ap.add_argument('--rounds', type=int, default=2)
    ap.add_argument('--workers', type=int, default=6)
    ap.add_argument('--out', default='po10_candidates.json')
    args = ap.parse_args()

    capture = json.load(open(args.capture))
    roster = json.load(open(args.roster))

    athletes = OrderedDict(athletes_from_capture(capture).items())
    print('athletes named directly in the rankings: %d' % len(athletes))

    seen_meetings = set()
    frontier = meeting_ids_from_capture(capture)
    print('meetings from the rankings            : %d' % len(frontier))

    for rnd in range(args.rounds):
        todo = sorted(frontier - seen_meetings)
        if not todo:
            break
        seen_meetings |= set(todo)
        print('\nround %d: scanning %d meetings' % (rnd + 1, len(todo)))
        new = []
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            for i, (mtid, found) in enumerate(ex.map(scan_meeting, todo)):
                for guid, name, club in found:
                    if guid not in athletes:
                        athletes[guid] = {'name': name, 'club': club, 'source': 'meeting'}
                        new.append(guid)
                if (i + 1) % 50 == 0:
                    print('   %d/%d meetings, %d club athletes known'
                          % (i + 1, len(todo), len(athletes)), flush=True)
                time.sleep(0.02)
        print('   -> %d new club athletes (total %d)' % (len(new), len(athletes)))

        if rnd + 1 < args.rounds and new:
            print('   pulling meetings off %d new athletes' % len(new))
            frontier = set()
            with ThreadPoolExecutor(max_workers=args.workers) as ex:
                for mids in ex.map(meetings_of_athlete, new):
                    frontier |= mids
            print('   -> %d more meetings to try' % len(frontier - seen_meetings))

    json.dump(athletes, open('po10_discovered.json', 'w'), indent=1)
    print('\ndiscovered %d club athletes -> po10_discovered.json' % len(athletes))

    # Shape them like an athlete-search capture so po10_match.py can verify them
    # unchanged: keyed by our athlete_id, value a list of candidates.
    by_name = {}
    for guid, info in athletes.items():
        by_name.setdefault(norm(info.get('name')), []).append((guid, info))

    candidates, hits = {}, 0
    for a in roster:
        if a.get('po10_guid'):
            continue
        key = norm(a['first_name'] + a['last_name'])
        for guid, info in by_name.get(key, []):
            parts = (info.get('name') or '').split()
            candidates.setdefault(str(a['athlete_id']), []).append({
                'id': guid,
                'fn': parts[0] if parts else '',
                'ln': parts[-1] if len(parts) > 1 else '',
                'gen': a.get('gender'),
                'clbnm': info.get('club'), 'scclbnm': None, 'fcoclbnm': None,
            })
        if str(a['athlete_id']) in candidates:
            hits += 1

    json.dump(candidates, open(args.out, 'w'), indent=1)
    print('matched by name to %d roster athletes still missing a GUID -> %s'
          % (hits, args.out))
    print('now run: python po10_match.py %s %s' % (args.out, args.roster))


if __name__ == '__main__':
    main()
