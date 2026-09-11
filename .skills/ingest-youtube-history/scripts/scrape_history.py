#!/usr/bin/env python3
"""Scrape YouTube watch history from a logged-in Chrome debug instance.

Prints JSON to stdout: [{date, resolved_date, vid, url, title, channel}, ...]
filtered to the last N days.

Requires a Chrome started with:
  --remote-debugging-port=9222 --remote-allow-origins=*
  --user-data-dir=~/.logseq-wiki/chrome-debug   (with a logged-in YouTube session)

Usage: scrape_history.py [--days N] [--port 9222]
"""
import json, sys, time, datetime, unicodedata, urllib.request, argparse

def get_ws(port):
    tabs = json.load(urllib.request.urlopen(f"http://localhost:{port}/json"))
    page = next((t for t in tabs if t.get("type") == "page"), None)
    if not page:
        sys.exit("ERROR: no Chrome page on debug port — is the debug Chrome running?")
    try:
        import websocket  # websocket-client
    except ImportError:
        sys.exit("ERROR: pip install websocket-client")
    return websocket.create_connection(page["webSocketDebuggerUrl"], max_size=None)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--port", type=int, default=9222)
    ap.add_argument("--scrolls", type=int, default=8)
    args = ap.parse_args()

    ws = get_ws(args.port)
    _id = 0
    def cmd(m, p=None):
        nonlocal _id; _id += 1
        ws.send(json.dumps({"id": _id, "method": m, "params": p or {}}))
        while True:
            r = json.loads(ws.recv())
            if r.get("id") == _id:
                return r
    cmd("Page.enable"); cmd("Runtime.enable")
    cmd("Page.navigate", {"url": "https://www.youtube.com/feed/history"})
    time.sleep(6)

    # session check
    st = cmd("Runtime.evaluate", {"expression":
        "({loggedIn: !document.body.innerText.includes('Se connecter'), "
        "url: location.href})", "returnByValue": True})
    val = st.get("result", {}).get("result", {}).get("value", {})
    if not val.get("loggedIn"):
        sys.exit("ERROR: YouTube session not logged in in the debug Chrome. "
                 "Open the debug Chrome, sign in to YouTube, then retry.")

    for _ in range(args.scrolls):
        cmd("Runtime.evaluate", {"expression":
            "window.scrollTo(0, document.documentElement.scrollHeight)"})
        time.sleep(1.5)

    js = r"""
    (() => {
      const out=[];
      document.querySelectorAll('ytd-item-section-renderer').forEach(sec=>{
        const h=sec.querySelector('#title.ytd-item-section-header-renderer, #header #title');
        const date=h?h.textContent.trim():'';
        sec.querySelectorAll('yt-lockup-view-model').forEach(v=>{
          const a=v.querySelector('a[href*="/watch?v="]');
          if(a&&a.href){
            const vid=(a.href.match(/[?&]v=([^&]+)/)||[])[1];
            // title: h3 is the reliable source (headless-safe); aria-label/text often = thumbnail duration
            const h3=v.querySelector('h3');
            const titleLink=v.querySelector('a[href*="/watch?v="][aria-label], a#video-title');
            const title=(h3?h3.textContent:'') || (titleLink?titleLink.getAttribute('aria-label'):'') || '';
            // channel = first segment of the metadata line ("Channel • N vues")
            const meta=v.querySelector('yt-content-metadata-view-model');
            let channel='';
            if(meta){ channel=(meta.innerText.split(/[•\n]/)[0]||'').trim(); }
            out.push({date, vid, url:'https://www.youtube.com/watch?v='+vid,
              title:title.trim(), channel});
          }
        });
      });
      const seen=new Set(), uniq=[];
      for(const o of out){ if(o.vid && !seen.has(o.vid)){seen.add(o.vid); uniq.push(o);} }
      return uniq;
    })()
    """
    r = cmd("Runtime.evaluate", {"expression": js, "returnByValue": True})
    vids = r.get("result", {}).get("result", {}).get("value") or []
    ws.close()

    # resolve French date labels to real dates
    today = datetime.date.today()
    jours = {'lundi':0,'mardi':1,'mercredi':2,'jeudi':3,'vendredi':4,'samedi':5,'dimanche':6}
    mois = {'janv':1,'févr':2,'mars':3,'avril':4,'mai':5,'juin':6,'juil':7,
            'août':8,'sept':9,'oct':10,'nov':11,'déc':12}
    def norm(s): return ''.join(c for c in unicodedata.normalize('NFD', s.lower())
                                 if unicodedata.category(c) != 'Mn')
    def to_date(lbl):
        l = norm(lbl.strip())
        if 'aujour' in l: return today
        if 'hier' in l: return today - datetime.timedelta(days=1)
        for j, idx in jours.items():
            if norm(j) in l:
                delta = (today.weekday() - idx) % 7
                return today - datetime.timedelta(days=delta or 7)
        parts = l.replace('.', '').split()
        if len(parts) >= 2 and parts[0].isdigit():
            for m, mi in mois.items():
                if parts[1].startswith(norm(m)[:3]):
                    y = today.year if mi <= today.month else today.year - 1
                    try: return datetime.date(y, mi, int(parts[0]))
                    except ValueError: return None
        return None

    cutoff = today - datetime.timedelta(days=args.days)
    recent = []
    for v in vids:
        d = to_date(v['date'])
        if d and d >= cutoff:
            v['resolved_date'] = str(d)
            recent.append(v)
    recent.sort(key=lambda v: v['resolved_date'], reverse=True)
    print(json.dumps(recent, ensure_ascii=False, indent=1))

if __name__ == "__main__":
    main()
