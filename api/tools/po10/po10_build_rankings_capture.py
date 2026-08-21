#!/usr/bin/env python3
"""
Generate a browser-console script that pulls club rankings per year off
powerof10.uk, which is the cheap way to find lapsed members.

Why this beats searching athlete by athlete: the athlete search needs one
reCAPTCHA-gated request per member, about 1400 of them, and the challenge
escalates to image puzzles after a handful. Club rankings are gated too but
cover a whole year of the club in one request, and they go back to 2006. Each
ranking row carries the athlete GUID (athid) AND the meeting GUID (mtid), and
meeting results pages are NOT gated, so a few dozen requests here unlock an
unlimited free crawl afterwards (po10_crawl_meetings.py).

Queries run oldest year first, because recent members are the ones we already
have.

Usage:
    python po10_build_rankings_capture.py po10_rankings_capture.js
    python po10_build_rankings_capture.py out.js --from 2006 --to 2026 \
        --events 10K,Half_Marathon
"""
import argparse
import json

CLUB_GUID = '60614dd5-24df-4e8f-a65e-6a14e26c9b70'   # Black Pear Joggers
DEFAULT_EVENTS = ['10K', 'Half_Marathon']

TEMPLATE = r"""
/* Power of 10 club-rankings capture - paste into the console on
   https://www.powerof10.uk/Home/Club/__CLUB__

   Drives the page's own search so reCAPTCHA runs exactly as it does when you
   use the form. Progress is kept in localStorage, so if the tab reloads just
   paste this again and it carries on. */
(function () {
  const QUERIES = __QUERIES__;
  const KEY = 'po10rankings';
  const BASE_DELAY = __DELAY__;
  const TIMEOUT_MS = 60000;

  const saved = JSON.parse(localStorage.getItem(KEY) || '{}');
  let pending = null;

  const origAjax = $.ajax;
  $.ajax = function (opts) {
    if (opts && typeof opts.url === 'string' && opts.url.indexOf('SearchRankings') !== -1) {
      const theirSuccess = opts.success;
      opts.success = function (response) {
        if (response && response.status === 'OK' && pending) {
          pending.resolve(response); pending = null;
        }
        return theirSuccess.apply(this, arguments);
      };
      const theirError = opts.error;
      opts.error = function () {
        if (pending) { pending.reject(new Error('ajax error')); pending = null; }
        return theirError ? theirError.apply(this, arguments) : undefined;
      };
    }
    return origAjax.apply(this, arguments);
  };

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  function setDdl(id, value, handler) {
    $('#' + id).val(value);
    window[handler]();
  }

  function runOne(q) {
    const p = q.surface;                      // 'road' or 'track'
    setDdl(p + 'YrDdl', 'yr' + q.yr, p + 'YrChange_Ddl');
    setDdl(p + 'SexDdl', q.sex, p + 'SexChange_Ddl');
    setDdl(p + 'AgeDdl', 'OVER', p + 'AgeChange_Ddl');
    setDdl(p + 'EventDdl', q.ev, 'ev' + (p === 'road' ? 'Road' : 'Track') + 'Change_Ddl');
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (pending) { pending = null; reject(new Error('timeout')); }
      }, TIMEOUT_MS);
      pending = {
        resolve: (v) => { clearTimeout(timer); resolve(v); },
        reject: (e) => { clearTimeout(timer); reject(e); }
      };
      try {
        (p === 'road' ? runSearchRoad : runSearchTrack)(true);
      } catch (e) {
        clearTimeout(timer); pending = null; reject(e);
      }
    });
  }

  function download(obj, name) {
    const blob = new Blob([JSON.stringify(obj, null, 1)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    a.click();
  }

  window.po10stop = false;

  (async function () {
    console.log('%cclub rankings capture: ' + QUERIES.length + ' queries, ' +
                Object.keys(saved).length + ' already done', 'font-weight:bold');
    console.log('Solve a challenge if one appears; it resumes on its own. ' +
                'Set po10stop = true to halt.');
    let n = 0, failed = 0;
    for (const q of QUERIES) {
      if (window.po10stop) { console.log('stopped'); break; }
      if (saved[q.key]) { continue; }
      try {
        const resp = await runOne(q);
        saved[q.key] = (resp.results || []).map((r) => ({
          athid: r.athid, athn: r.athn,
          mtid: r.mtid, mtn: r.mtn, perfdt: r.perfdt
        }));
        n++;
      } catch (e) {
        saved[q.key] = null;
        failed++;
        console.warn('failed', q.key, e.message);
      }
      localStorage.setItem(KEY, JSON.stringify(saved));
      let ath = 0, mts = new Set();
      Object.values(saved).forEach((v) => (v || []).forEach((r) => {
        ath++; if (r.mtid) mts.add(r.mtid);
      }));
      console.log('  ' + Object.keys(saved).length + '/' + QUERIES.length +
                  '  ' + q.key + '  rows so far ' + ath +
                  ', meetings ' + mts.size + (failed ? ', failed ' + failed : ''));
      /* jitter, and breathe every so often; hammering at a fixed interval is
         what makes the invisible reCAPTCHA start showing image puzzles */
      await sleep(BASE_DELAY + Math.floor(Math.random() * BASE_DELAY));
      if ((n + failed) % 12 === 0) { await sleep(8000); }
    }
    localStorage.setItem(KEY, JSON.stringify(saved));
    download(saved, 'po10_rankings.json');
    console.log('%cdone - po10_rankings.json downloaded', 'font-weight:bold');
    console.log('If the download did not start: copy(localStorage.po10rankings)');
  })();
})();
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out', nargs='?', default='po10_rankings_capture.js')
    ap.add_argument('--from', dest='yr_from', type=int, default=2006)
    ap.add_argument('--to', dest='yr_to', type=int, default=2026)
    ap.add_argument('--events', default=','.join(DEFAULT_EVENTS))
    ap.add_argument('--delay', type=int, default=1500)
    ap.add_argument('--club', default=CLUB_GUID)
    args = ap.parse_args()

    events = [e for e in args.events.split(',') if e]
    queries = []
    for yr in range(args.yr_from, args.yr_to + 1):     # oldest first, on purpose
        for ev in events:
            for sex in ('M', 'W'):
                queries.append({'key': 'road-%s-%s-%s' % (yr, ev, sex),
                                'surface': 'road', 'yr': yr, 'ev': ev, 'sex': sex})

    js = (TEMPLATE
          .replace('__QUERIES__', json.dumps(queries))
          .replace('__DELAY__', str(args.delay))
          .replace('__CLUB__', args.club))
    open(args.out, 'w', encoding='utf-8').write(js)

    secs = len(queries) * (args.delay * 1.5 / 1000 + 1.2) + len(queries) / 12 * 8
    print('%d queries -> %s' % (len(queries), args.out))
    print('years %d-%d, events %s' % (args.yr_from, args.yr_to, ', '.join(events)))
    print('rough runtime: %.0f minutes plus however long the challenges take'
          % (secs / 60))


if __name__ == '__main__':
    main()
