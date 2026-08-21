#!/usr/bin/env python3
"""
Generate a browser-console script that collects powerof10.uk athlete-search
results for every club member we do not yet have a GUID for.

Why a console script rather than an HTTP client: athlete search is behind
reCAPTCHA v2 invisible. The token is single use, tied to the site key and
validated by Google, so there is no honest way to mint one outside a browser.
Rather than fight that, this drives the page's own runSearch(), which means the
site's normal reCAPTCHA flow runs exactly as it does for a human clicking
Search. We only read the responses.

Usage:
    python po10_build_capture.py bpj_athletes_all.json po10_capture.js
Then open https://www.powerof10.uk/Home/AthleteSearch, paste the file into the
console, and let it run. It writes po10_candidates.json via a download.
"""
import json
import sys

CLUB = "Black Pear Joggers"

TEMPLATE = r"""
/* Power of 10 athlete-search capture - paste into the console on
   https://www.powerof10.uk/Home/AthleteSearch

   Drives the page's own search so reCAPTCHA runs normally. Progress is kept in
   localStorage, so if the tab reloads just paste this again and it resumes. */
(function () {
  const QUERIES = __QUERIES__;
  const KEY = 'po10capture';
  const DELAY_MS = __DELAY__;      // be polite, this is someone else's server
  const TIMEOUT_MS = 30000;

  const saved = JSON.parse(localStorage.getItem(KEY) || '{}');
  let pending = null;

  /* Capture at the ajax layer. On a good response we blank searchRun so the
     page's own handler bails out of isCurrentSearch(); that stops it rendering
     rows and, critically, stops the "exactly one result" redirect from
     navigating us off the page mid-run. A RECAPTCHA_REQUIRED response is
     passed through untouched so their retry logic still fires. */
  const origAjax = $.ajax;
  $.ajax = function (opts) {
    if (opts && typeof opts.url === 'string' && opts.url.indexOf('RunAthleteSearch') !== -1) {
      const theirSuccess = opts.success;
      opts.success = function (response, textStatus, jqXHR) {
        if (response && response.status === 'OK') {
          if (pending) { pending.resolve(response); pending = null; }
          try { hideLoading(); } catch (e) {}
          /* searchRun is `let`-scoped on their page so we cannot clear it.
             Instead hand their handler a copy with a sid that cannot match, so
             isCurrentSearch() sends it straight back out. That keeps it from
             rendering rows and, more importantly, from firing the
             "exactly one result" redirect that would navigate us off the page
             in the middle of the run. */
          const ignored = Object.assign({}, response, { sid: -1 });
          return theirSuccess.call(this, ignored, textStatus, jqXHR);
        }
        /* RECAPTCHA_REQUIRED and friends go through untouched. */
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

  function runOne(q) {
    $('#searchFirstName').val(q.fn || '');
    $('#searchLastName').val(q.ln || '');
    $('#searchClubName').val(q.clb || '');
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (pending) { pending = null; reject(new Error('timeout')); }
      }, TIMEOUT_MS);
      pending = {
        resolve: (v) => { clearTimeout(timer); resolve(v); },
        reject: (e) => { clearTimeout(timer); reject(e); }
      };
      try {
        runSearch(true);   // true = straight to grecaptcha, skips a wasted request
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
    console.log('%cPower of 10 capture: ' + QUERIES.length + ' queries, ' +
                Object.keys(saved).length + ' already done',
                'font-weight:bold');
    console.log('Set po10stop = true to halt early; progress is saved.');
    let done = 0, failed = 0;
    for (const q of QUERIES) {
      if (window.po10stop) { console.log('stopped by request'); break; }
      if (saved[q.key]) { continue; }
      try {
        const resp = await runOne(q);
        saved[q.key] = (resp.results || []).map((r) => ({
          id: r.id, fn: r.fn, ln: r.ln, gen: r.gen,
          clbnm: r.clbnm, clbid: r.clbid,
          scclbnm: r.scclbnm, fcoclbnm: r.fcoclbnm,
          tag: r.tag, xcag: r.xcag, rag: r.rag
        }));
        done++;
      } catch (e) {
        saved[q.key] = null;          // null = query failed, retried on next run
        failed++;
        console.warn('failed', q.key, e.message);
      }
      if ((done + failed) % 25 === 0) {
        localStorage.setItem(KEY, JSON.stringify(saved));
        console.log('  ' + Object.keys(saved).length + '/' + QUERIES.length +
                    ' (' + failed + ' failed)');
      }
      await sleep(DELAY_MS);
    }
    localStorage.setItem(KEY, JSON.stringify(saved));
    const hits = Object.values(saved).filter((v) => v && v.length).length;
    console.log('%cdone. ' + Object.keys(saved).length + ' queries, ' +
                hits + ' with at least one result', 'font-weight:bold');
    download(saved, 'po10_candidates.json');
    console.log('If the download did not start, run: copy(localStorage.po10capture)');
  })();
})();
"""


def main():
    roster = json.load(open(sys.argv[1]))
    out = sys.argv[2] if len(sys.argv) > 2 else 'po10_capture.js'
    delay = int(sys.argv[3]) if len(sys.argv) > 3 else 600

    queries = [{'key': 'club', 'clb': CLUB}]
    for a in roster:
        if a.get('po10_guid'):
            continue
        fn = (a.get('first_name') or '').strip()
        ln = (a.get('last_name') or '').strip()
        if not ln:
            continue
        queries.append({'key': str(a['athlete_id']), 'fn': fn, 'ln': ln})

    js = (TEMPLATE
          .replace('__QUERIES__', json.dumps(queries))
          .replace('__DELAY__', str(delay)))
    open(out, 'w', encoding='utf-8').write(js)

    mins = len(queries) * (delay + 900) / 1000 / 60
    print('%d queries -> %s (%.0f KB)' % (len(queries), out, len(js) / 1024))
    print('rough runtime at %dms delay: %.0f minutes' % (delay, mins))


if __name__ == '__main__':
    main()
