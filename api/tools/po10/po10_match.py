#!/usr/bin/env python3
"""
Turn captured powerof10.uk search results into a verified athlete_id -> GUID map.

A name match on its own is not safe: attaching the wrong GUID silently grafts
another runner's results onto a member. So every candidate is checked against
the site itself (server rendered, no reCAPTCHA) and scored:

  legacy-id    the profile photo is served as /Images/Athletes/<id>.jpg and that
               integer IS our athlete_id. Conclusive, but only about 3% of
               athletes have a photo.
  performance  we store a first and a latest performance for nearly every
               member, both dated and with a parsed time. If either turns up in
               the candidate's Power of 10 history it is the same person. This
               is the workhorse, and it works for lapsed members too.
  handicap     we also store a dated runBritain handicap value, which the
               athlete page carries as hcapHist. A value matching on its date
               is as good as a performance match.
  club         first, second or other claim club is the club we are matching.
               Good for current members, useless for anyone who has moved on.

Anything that clears two independent signals, or one conclusive one, is written
to matches.json. The rest goes to review.csv for a human to look at.

Usage:
    python po10_match.py po10_candidates.json bpj_athletes_all.json
"""
import csv
import json
import re
import sys
import unicodedata
from concurrent.futures import ThreadPoolExecutor

from po10_scrape import scrape_athlete

CLUB = "black pear joggers"
API = "https://bpj.org.uk/api/public/index.php"


def norm(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z]", "", s.lower())


def our_signals(athlete_id):
    """Dated facts we already hold for this athlete, to test a candidate against.

    /performances is no use here: it inner joins memberships, so a lapsed member
    returns nothing at all, and lapsed members are most of what we are trying to
    match. /athlete/{id} carries first_performance, latest_performance and
    latest_ranking, and it answers for everyone.
    """
    import ssl
    import urllib.request
    ctx = ssl.create_default_context()
    try:
        import certifi
        ctx = ssl.create_default_context(cafile=certifi.where())
    except Exception:
        pass
    url = "%s/athlete/%s" % (API, athlete_id)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "bpj-po10-match"})
        d = json.load(urllib.request.urlopen(req, timeout=60, context=ctx))
    except Exception:
        return {"perfs": set(), "hcap": set()}

    perfs = set()
    for key in ("first_performance", "latest_performance"):
        p = d.get(key)
        if not p:
            continue
        date = (p.get("date") or "")[:10]
        try:
            secs = round(float(p.get("time_parsed")), 0)
        except (TypeError, ValueError):
            continue
        if date:
            perfs.add((date, secs))

    hcap = set()
    r = d.get("latest_ranking")
    if r and r.get("date") and r.get("ranking") is not None:
        hcap.add((str(r["date"])[:10], round(float(r["ranking"]), 1)))
    return {"perfs": perfs, "hcap": hcap}


def po10_signals(scraped):
    perfs = set()
    for r in scraped.get("history") or []:
        date = (r.get("date") or "")[:10]
        secs = r.get("seconds")
        if date and secs is not None:
            perfs.add((date, round(float(secs), 0)))
    hcap = sorted(((r.get("date") or "")[:10], round(float(r["ranking"]), 1))
                  for r in scraped.get("rankings") or [] if r.get("ranking") is not None)
    return {"perfs": perfs, "hcap": hcap}


def handicap_agrees(ours, theirs, tol=0.3, max_gap_days=200):
    """Does their handicap series pass through our recorded value?

    We store the handicap as of the night our cron ran; the rebuilt site samples
    it at change points instead, so the dates never line up exactly. Compare our
    value against their last reading at or before our date. It is a continuous
    number to one decimal, so agreeing to within a tenth or two is a strong
    signal that this is the same runner.
    """
    from datetime import date as _date

    def d(s):
        y, m, dd = s.split("-")
        return _date(int(y), int(m), int(dd))

    for our_date, our_val in ours:
        prior = [t for t in theirs if t[0] and t[0] <= our_date]
        if not prior:
            continue
        their_date, their_val = prior[-1]
        try:
            gap = (d(our_date) - d(their_date)).days
        except Exception:
            continue
        if gap <= max_gap_days and abs(our_val - their_val) <= tol:
            return abs(our_val - their_val)
    return None


def clubs_of(scraped, cand):
    names = [scraped.get("profile", {}).get("club") or ""]
    for k in ("clbnm", "scclbnm", "fcoclbnm"):
        names.append(cand.get(k) or "")
    return [n.lower() for n in names if n]


def assess(athlete, cand, scraped, ours):
    """Return (verdict, score, reasons). Score is evidence weight, not confidence."""
    reasons = []
    score = 0

    legacy = scraped.get("profile", {}).get("legacyAthleteId")
    if legacy and int(legacy) == int(athlete["athlete_id"]):
        reasons.append("legacy id")
        score += 4
    elif legacy:
        return "rejected", 0, ["legacy id is %s" % legacy]

    gen = (cand.get("gen") or "").upper()[:1]
    ours_gen = (athlete.get("gender") or "").upper()[:1]
    gen = {"W": "F"}.get(gen, gen)
    ours_gen = {"W": "F"}.get(ours_gen, ours_gen)
    if gen and ours_gen and gen != ours_gen:
        return "rejected", 0, ["gender mismatch (%s vs %s)" % (gen, ours_gen)]

    theirs = po10_signals(scraped)

    their_dates = {d for d, _ in theirs["perfs"]}
    exact = sum(1 for d, t in ours["perfs"]
                if any(d == td and abs(t - tt) <= 1 for td, tt in theirs["perfs"]))
    same_day = sum(1 for d, _ in ours["perfs"] if d in their_dates)
    if exact:
        reasons.append("%d performance%s match" % (exact, "" if exact == 1 else "es"))
        score += 2 * exact
    elif same_day:
        reasons.append("%d same-day performance%s" % (same_day, "" if same_day == 1 else "s"))
        score += same_day

    delta = handicap_agrees(ours["hcap"], theirs["hcap"])
    if delta is not None:
        reasons.append("handicap agrees (within %.1f)" % delta)
        score += 2

    if any(CLUB in c for c in clubs_of(scraped, cand)):
        reasons.append("club")
        score += 1

    if score >= 3:
        return "confident", score, reasons
    if reasons:
        return "review", score, reasons
    return "review", 0, ["name only"]


def main():
    captured = json.load(open(sys.argv[1]))
    roster = json.load(open(sys.argv[2]))

    todo = []
    for a in roster:
        if a.get("po10_guid"):
            continue
        key = str(a["athlete_id"])
        cands = captured.get(key) or []
        want = norm(a["first_name"]) + norm(a["last_name"])
        cands = [c for c in cands if norm(c.get("fn")) + norm(c.get("ln")) == want]
        if cands:
            todo.append((a, cands))

    print("roster missing a GUID : %d" % sum(1 for a in roster if not a.get("po10_guid")))
    print("with name candidates  : %d" % len(todo))
    print("candidate pages to check: %d" % sum(len(c) for _, c in todo))

    guids = sorted({c["id"] for _, cs in todo for c in cs})
    pages = {}
    with ThreadPoolExecutor(max_workers=8) as ex:
        for i, (g, s) in enumerate(zip(guids, ex.map(scrape_athlete, guids))):
            pages[g] = s
            if (i + 1) % 50 == 0:
                print("  scraped %d/%d" % (i + 1, len(guids)), flush=True)

    matches, review = {}, []
    with ThreadPoolExecutor(max_workers=8) as ex:
        ids = [a["athlete_id"] for a, _ in todo]
        perf = dict(zip(ids, ex.map(our_signals, ids)))

    for a, cands in todo:
        ours = perf.get(a["athlete_id"]) or {"perfs": set(), "hcap": set()}
        scored = []
        for c in cands:
            s = pages.get(c["id"]) or {}
            if s.get("error"):
                continue
            verdict, score, reasons = assess(a, c, s, ours)
            if verdict != "rejected":
                scored.append((score, verdict, c, reasons))
        scored.sort(key=lambda x: -x[0])
        if not scored:
            continue
        top = scored[0]
        only = len(scored) == 1 or top[0] > scored[1][0]
        name = "%s %s" % (a["first_name"], a["last_name"])
        if top[1] == "confident" and only:
            matches[str(a["athlete_id"])] = {
                "guid": top[2]["id"], "name": name, "via": ", ".join(top[3])}
        else:
            review.append({
                "athlete_id": a["athlete_id"], "name": name,
                "guid": top[2]["id"], "club": top[2].get("clbnm"),
                "reasons": "; ".join(top[3]),
                "other_candidates": len(scored) - 1,
                "url": "https://www.powerof10.uk/Home/Athlete/%s" % top[2]["id"]})

    json.dump(matches, open("matches.json", "w"), indent=1)
    with open("review.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(review[0].keys()) if review else
                           ["athlete_id", "name", "guid", "club", "reasons",
                            "other_candidates", "url"])
        w.writeheader()
        w.writerows(review)

    print()
    print("confident -> matches.json : %d" % len(matches))
    print("needs review -> review.csv: %d" % len(review))


if __name__ == "__main__":
    main()
