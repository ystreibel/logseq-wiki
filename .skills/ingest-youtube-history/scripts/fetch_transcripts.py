#!/usr/bin/env python3
"""Fetch transcripts for a list of YouTube URLs via the `nlm` CLI (NotebookLM).

Reads a JSON list of {url, title, channel, resolved_date, vid} on stdin (or --in FILE),
adds them to a temporary NotebookLM notebook, retrieves each raw transcript, and writes
one cleaned text file per video to --out-dir. Prints a JSON manifest of results.

No cookies needed — NotebookLM ingests YouTube server-side.

Usage: fetch_transcripts.py --in videos.json --out-dir /tmp/yt-transcripts [--keep-notebook]
"""
import json, sys, subprocess, argparse, os, re

UUID_RE = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")

def nlm(*args, timeout=180):
    r = subprocess.run(["nlm", *args], capture_output=True, text=True, timeout=timeout)
    return r.stdout.strip(), r.stderr.strip(), r.returncode

def nlm_id(*args, timeout=180):
    # ponytail: this nlm CLI build has no --json output; scrape the UUID it prints instead
    out, err, rc = nlm(*args, timeout=timeout)
    m = UUID_RE.search(out)
    return ({"id": m.group(0)} if m else {"_raw": out, "_err": err}), rc

def nlm_json(*args, timeout=180):
    out, err, rc = nlm(*args, timeout=timeout)
    try:
        return json.loads(out), rc
    except json.JSONDecodeError:
        return {"_raw": out, "_err": err}, rc

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="infile", default="-")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--notebook-title", default="yt-history-ingest")
    ap.add_argument("--keep-notebook", action="store_true")
    args = ap.parse_args()

    raw = sys.stdin.read() if args.infile == "-" else open(args.infile, encoding="utf-8").read()
    videos = json.loads(raw)
    if not videos:
        print(json.dumps({"status": "empty", "results": []})); return
    os.makedirs(args.out_dir, exist_ok=True)

    nb, rc = nlm_id("notebook", "create", args.notebook_title)
    nbid = nb.get("id")
    if not nbid:
        sys.exit(f"ERROR: notebook create failed: {nb}")

    results = []
    try:
        for v in videos:
            # add the video (server-side, no cookies), wait for indexing
            src, rc = nlm_id("source", "add", nbid, "--youtube", v["url"], "--wait", timeout=200)
            sid = src.get("id")
            if not sid:
                results.append({**v, "status": "add_failed", "detail": src}); continue
            # retrieve raw transcript
            content, rc = nlm_json("source", "content", sid, timeout=120)
            payload = content.get("value", content)
            text = payload.get("content") or payload.get("text") or ""
            if not text.strip():
                results.append({**v, "status": "empty_transcript"}); continue
            slug = re.sub(r"[^a-z0-9]+", "-",
                          (v.get("title") or v["vid"]).lower()).strip("-")[:60] or v["vid"]
            path = os.path.join(args.out_dir, f"{slug}.txt")
            open(path, "w", encoding="utf-8").write(text)
            results.append({**v, "status": "ok", "slug": slug,
                            "transcript_path": path, "char_count": len(text)})
    finally:
        if not args.keep_notebook:
            nlm("notebook", "delete", nbid, "-y", timeout=60)

    ok = sum(1 for r in results if r["status"] == "ok")
    print(json.dumps({"status": "done", "notebook_id": nbid if args.keep_notebook else None,
                      "ok": ok, "total": len(videos), "results": results},
                     ensure_ascii=False, indent=1))

if __name__ == "__main__":
    main()
