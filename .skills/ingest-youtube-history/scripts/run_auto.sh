#!/bin/bash
# Fully autonomous weekly ingest — launched by launchd.
# Scrapes YouTube history, then hands the full pipeline (filter + transcripts +
# distillation + commit) to a headless `claude -p` run. No human in the loop.
set -uo pipefail

# launchd does not inherit the interactive PATH — set it explicitly so asdf-python,
# claude, nlm and gh are all found.
export PATH="$HOME/.asdf/shims:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
PY="$HOME/.asdf/installs/python/3.12.8/bin/python3"   # the python3 that has websocket-client
[ -x "$PY" ] || PY="python3"

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SKILL_DIR/../../.." && pwd)"   # repo root (has CLAUDE.md + .claude/skills)
PENDING="$HOME/.logseq-wiki/yt-pending.json"
PORT=9222
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PROFILE="$HOME/.logseq-wiki/chrome-debug"
CLAUDE="$HOME/.local/bin/claude"
LOG="/tmp/yt-history-auto.log"

# Notifications: informational only, no click action (Logseq-OG has no URL scheme to open
# a page, and opening the vault folder adds nothing). terminal-notifier is preferred for a
# clean banner (its own bundle id, no click → nothing happens); osascript is the fallback.
# Note: a brew-installed terminal-notifier must be taken out of Gatekeeper quarantine once
# (`xattr -dr com.apple.quarantine <app>`) or macOS silently denies its notifications.
notify() {
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "$1" -message "$2" >/dev/null 2>&1
  else
    osascript -e "display notification \"$2\" with title \"$1\"" 2>/dev/null
  fi
}
say() { echo "[$(date '+%F %T')] $1" >> "$LOG"; }

say "=== run_auto start ==="

# 1. ensure debug Chrome (headless) with the YouTube session
STARTED_CHROME=0
if ! curl -s -m 5 "http://localhost:$PORT/json/version" >/dev/null 2>&1; then
  [ -x "$CHROME" ] || { notify "Wiki YouTube" "Google Chrome introuvable."; say "no chrome binary"; exit 1; }
  "$CHROME" --headless=new --remote-debugging-port=$PORT --remote-allow-origins='*' \
    --window-size=1920,1080 --user-data-dir="$PROFILE" >/dev/null 2>&1 &
  for i in $(seq 1 20); do curl -s -m 2 "http://localhost:$PORT/json/version" >/dev/null 2>&1 && break; sleep 1; done
  curl -s -m 3 "http://localhost:$PORT/json/version" >/dev/null 2>&1 || { notify "Wiki YouTube" "Chrome debug n'a pas démarré."; say "chrome debug failed"; exit 1; }
  STARTED_CHROME=1
fi

# 2. scrape last 7 days → pending file
OUT="$("$PY" "$SKILL_DIR/scrape_history.py" --days 7 2>>"$LOG")"
if [ -z "$OUT" ] || echo "$OUT" | grep -q '^ERROR'; then
  notify "Wiki YouTube" "Session YouTube expirée — reconnecte-toi."
  say "scrape failed / session expired"
  [ "$STARTED_CHROME" = "1" ] && pkill -f "user-data-dir=$PROFILE" 2>/dev/null
  exit 1
fi
mkdir -p "$HOME/.logseq-wiki"
echo "$OUT" > "$PENDING"
COUNT=$(echo "$OUT" | "$PY" -c "import sys,json;print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
say "scraped $COUNT videos"

# 3. hand the full pipeline to a headless Claude run (from the framework repo)
notify "Wiki YouTube" "$COUNT vidéos scrapées — ingestion automatique en cours…"
say "launching claude -p"
cd "$FRAMEWORK" || exit 1
PROMPT="$(cat "$SKILL_DIR/auto-prompt.md")"
"$CLAUDE" -p "$PROMPT" --dangerously-skip-permissions >>"$LOG" 2>&1
RC=$?
say "claude -p finished rc=$RC"

# 4. close the debug Chrome only if we started it
[ "$STARTED_CHROME" = "1" ] && pkill -f "user-data-dir=$PROFILE" 2>/dev/null

# Claude sends its own completion notification; only flag a hard failure of the runner.
[ $RC -ne 0 ] && notify "Wiki YouTube" "Ingestion auto: erreur (rc=$RC) — voir $LOG"
say "=== run_auto end ==="
exit 0
