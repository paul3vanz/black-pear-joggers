#!/usr/bin/env python3
"""
POC: scrape athlete data from the redesigned powerof10.uk WITHOUT hitting reCAPTCHA.

Key insight: every reCAPTCHA-gated AJAX endpoint has a server-rendered equivalent.
The athlete page embeds, as plain JS literals:
  * gridData          - the EXACT payload GetAthletePerformances returns (status "OK"),
                        for the most recent year that has data, per filter.
  * dataRp* arrays    - the FULL multi-year performance history for each charted event.
  * hcapHist*         - the runBritain handicap ("ranking") history, replacing the
                        now-dead runbritainrankings.com profile scrape.
  * /Images/Athletes/<legacyId>.jpg - the legacy integer athlete id.

Usage:  python po10_scrape.py <guid> [<guid> ...]
"""
import json, re, sys, time, urllib.request, urllib.error, gzip, io

BASE = "https://www.powerof10.uk"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")


def fetch(url, retries=3):
    for attempt in range(retries):
        req = urllib.request.Request(url, headers={
            "User-Agent": UA,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-GB,en;q=0.9",
            "Accept-Encoding": "gzip",
        })
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                raw = r.read()
                if r.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.GzipFile(fileobj=io.BytesIO(raw)).read()
                return raw.decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if attempt == retries - 1:
                raise
        except Exception:
            if attempt == retries - 1:
                raise
        time.sleep(2 ** attempt)
    return None


# ---------- JS literal extraction ----------

def _js_array(html, name):
    """Read `var <name> = [ ... ];` as JSON (single->double quotes)."""
    m = re.search(r"(?:var|let)\s+%s\s*=\s*(\[.*?\]);" % re.escape(name), html, re.S)
    if not m:
        return []
    body = m.group(1)
    body = body.replace("\\'", "\u0001").replace("'", '"').replace("\u0001", "'")
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return []


def parse_grid_data(html):
    """The embedded copy of the GetAthletePerformances response."""
    m = re.search(r"let gridData = (\{.*?\});\s*\n", html, re.S)
    if not m:
        return None
    return json.loads(m.group(1))


TIME_FORMATS = ("MinSec", "SecCs", "MinSecCs", "HrMinSec")
DISTANCE_FORMATS = ("MetreCm", "KmMetre")


def decode_value(value, fmt):
    """PO10 chart integers -> (kind, value).

    Time formats:  MinSec / SecCs / MinSecCs are hundredths of a second,
                   HrMinSec is whole seconds.
    Field events:  MetreCm / KmMetre are hundredths of a metre - these are
                   DISTANCES, not times, and must never be run through the
                   time formatter (a 12.13m triple jump is not '12:13').
    """
    if fmt == "HrMinSec":
        return "time", float(value)
    if fmt in ("MinSec", "SecCs", "MinSecCs"):
        return "time", round(value / 100.0, 2)
    if fmt in DISTANCE_FORMATS:
        return "distance", round(value / 100.0, 2)
    return "unknown", float(value)


def fmt_time(secs):
    s = float(secs)
    h, rem = divmod(s, 3600)
    m, sec = divmod(rem, 60)
    if h:
        return "%d:%02d:%05.2f" % (h, m, sec)
    return "%d:%05.2f" % (m, sec)


def parse_chart_history(html):
    """Full multi-year history from the per-event progression charts."""
    events = re.findall(r"evntKeys\.set\(\d+,\s*'(.*?)'\)", html)
    out = []
    for i, event in enumerate(events):
        fm = re.search(r"var dataFormatToUse%d = '(.*?)';" % i, html)
        fmt = fm.group(1) if fm else "MinSec"
        dates = _js_array(html, "dataRpMeetDates%d" % i)
        values = _js_array(html, "dataRpValues%d" % i)
        meetings = _js_array(html, "dataRpMeetings%d" % i)
        venues = _js_array(html, "dataRpLocations%d" % i)
        positions = _js_array(html, "dataRpPositions%d" % i)
        ages = _js_array(html, "dataRpAgeGroups%d" % i)
        indoors = _js_array(html, "dataRpIndoors%d" % i)
        for j, d in enumerate(dates):
            if not d:
                continue
            kind, val = decode_value(values[j], fmt) if j < len(values) else ("unknown", None)
            dd, mm, yyyy = d.split("/")
            out.append({
                "event": event.replace("_", " "),
                "date": "%s-%s-%s" % (yyyy, mm, dd),
                "format": fmt,
                "kind": kind,
                "seconds": val if kind == "time" else None,
                "metres": val if kind == "distance" else None,
                "time": fmt_time(val) if kind == "time" else None,
                "performance": (fmt_time(val) if kind == "time"
                                else ("%.2fm" % val if kind == "distance" else None)),
                "meeting": meetings[j] if j < len(meetings) else None,
                "venue": venues[j] if j < len(venues) else None,
                "position": positions[j] if j < len(positions) else None,
                "ageGroup": ages[j] if j < len(ages) else None,
                "indoor": (indoors[j] == "1") if j < len(indoors) else False,
                "source": "chart",
            })
    return out


def parse_grid_rows(grid, filt="Full"):
    """Exact string times for the latest year, from the embedded grid payload."""
    if not grid or not grid.get("perfs"):
        return [], None
    block = grid["perfs"]["dictpgs"].get(filt)
    if not block:
        return [], None
    year = block.get("yr")
    rows = []
    for page in block.get("pgs") or []:
        for r in page.get("results") or []:
            parts = r["dte"].split()
            day, mon = (parts + [None, None])[:2]
            rows.append({
                "event": r["evnt"],
                "date": "%s %s %s" % (day, mon, year),
                "time": r.get("perfchip") or r.get("perf"),
                "gunTime": r.get("perf"),
                "chipTime": r.get("perfchip") or None,
                "position": r.get("pos"),
                "venue": r.get("venn"),
                "meeting": r.get("mtn"),
                "meetingId": r.get("mtid"),
                "performanceId": r.get("id"),
                "wasPb": r.get("waspb"),
                "source": "grid",
            })
    return rows, year


MONTHS = {m: i + 1 for i, m in enumerate(
    ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])}


def _iso(datestr):
    """'21 Jan 2016' -> '2016-01-21'"""
    try:
        d, m, y = datestr.split()
        return "%s-%02d-%02d" % (y, MONTHS[m[:3]], int(d))
    except Exception:
        return None


def parse_rankings(html):
    """runBritain handicap history - replaces the dead runbritainrankings scrape.

    The chart is paginated: hcapHistData/hcapHistDates are pushed one array per
    page, aligned 1:1 within a page, but the pages are NOT in chronological
    order (page 0 is the most recent block). Pair per page, then sort.
    """
    data_pages = re.findall(r"hcapHistData\.push\(\[(.*?)\]\);", html, re.S)
    date_pages = re.findall(r"hcapHistDates\.push\(\[(.*?)\]\);", html, re.S)
    out = []
    for dpage, tpage in zip(data_pages, date_pages):
        vals = [float(y) for y in re.findall(r"y:\s*([\d.]+)", dpage)]
        dates = re.findall(r"'(.*?)'", tpage)
        for val, ds in zip(vals, dates):
            out.append({"date": _iso(ds), "dateText": ds, "ranking": val})
    return sorted(out, key=lambda r: r["date"] or "")


def parse_profile(html):
    legacy = re.search(r"/Images/Athletes/(\d+)\.jpg", html)
    club = re.search(r'First Claim Club:\s*([^"]+)"', html)
    club_id = re.search(r"/Home/Club/([a-f0-9-]{36})", html)
    age = re.search(r'id="divAllAgeGroup"[^>]*>([^<]*)<', html)
    yrs = re.search(r"\((\d+)\s*YRS\)", html)
    return {
        "legacyAthleteId": int(legacy.group(1)) if legacy else None,
        "club": club.group(1).strip() if club else None,
        "clubId": club_id.group(1) if club_id else None,
        "ageGroup": age.group(1).strip() if age else None,
        "age": int(yrs.group(1)) if yrs else None,
    }


def _year_list(html):
    return re.findall(r'perfYearsAll\.push\("(\d+)"\)', html)


def scrape_athlete(guid):
    html = fetch("%s/Home/Athlete/%s" % (BASE, guid))
    if html is None or "could not be found" in html:
        return {"guid": guid, "error": "not found"}
    grid = parse_grid_data(html)
    grid_rows, grid_year = parse_grid_rows(grid)
    chart = parse_chart_history(html)
    return {
        "guid": guid,
        "profile": parse_profile(html),
        "gridStatus": grid.get("status") if grid else None,
        "latestYear": grid_year,
        "latestYearPerformances": grid_rows,
        "history": sorted(chart, key=lambda r: r["date"]),
        "rankings": parse_rankings(html),
        "availableYears": _year_list(html),
    }


if __name__ == "__main__":
    guids = sys.argv[1:] or ["cefdba18-0a6e-4a8c-b204-f9dcc855b5e0"]
    for g in guids:
        r = scrape_athlete(g)
        if r.get("error"):
            print("%s: %s" % (g, r["error"]))
            continue
        p = r["profile"]
        print("=" * 72)
        print("GUID %s" % g)
        print("  legacyId=%s club=%s ageGroup=%s age=%s" % (
            p["legacyAthleteId"], p["club"], p["ageGroup"], p["age"]))
        print("  grid status : %s | latest year %s (%d perfs)" % (
            r["gridStatus"], r["latestYear"], len(r["latestYearPerformances"])))
        print("  years avail : %s" % ",".join(r["availableYears"]))
        print("  history     : %d perfs  %s -> %s" % (
            len(r["history"]),
            r["history"][0]["date"] if r["history"] else "-",
            r["history"][-1]["date"] if r["history"] else "-"))
        print("  rankings    : %d points  %s -> %s" % (
            len(r["rankings"]),
            r["rankings"][0]["date"] if r["rankings"] else "-",
            r["rankings"][-1]["date"] if r["rankings"] else "-"))
        for row in r["latestYearPerformances"][:3]:
            print("     grid %s %-10s %-9s %s" % (row["date"], row["event"], row["time"], row["meeting"]))
        for row in r["history"][-3:]:
            print("     hist %s %-14s %-10s %s" % (row["date"], row["event"], row["performance"], row["meeting"]))
        with open("athlete_%s.json" % g[:8], "w", encoding="utf-8") as f:
            json.dump(r, f, indent=1)
