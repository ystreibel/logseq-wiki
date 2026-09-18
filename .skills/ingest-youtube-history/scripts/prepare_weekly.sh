#!/bin/bash
# Weekly semi-auto prep for ingest-youtube-history.
# Scrapes the last 7 days of YouTube history, saves it for later review, and notifies the user.
# Does NOT ingest — a human reviews + confirms via /ingest-youtube-history --resume.
#
# Installed as a launchd job (see com.logseq-wiki.yt-history.plist).
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PENDING="$HOME/.logseq-wiki/yt-pending.json"
PORT=9222
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PROFILE="$HOME/.logseq-wiki/chrome-debug"

# Attribute the notification to Finder so clicking it opens Finder (harmless),
# not the AppleScript editor (which a bare `display notification` defaults to).
notify() { osascript -e "tell application \"Finder\" to display notification \"$2\" with title \"$1\"" 2>/dev/null; }

# 1. ensure a debug Chrome with the YouTube session is running — launch it headless if not
if ! curl -s -m 5 "http://localhost:$PORT/json/version" >/dev/null 2>&1; then
  if [ ! -x "$CHROME" ]; then
    notify "Wiki YouTube" "Google Chrome introuvable — impossible de lire l'historique."
    exit 1
  fi
  "$CHROME" --headless=new --remote-debugging-port=$PORT --remote-allow-origins='*' \
    --window-size=1920,1080 --user-data-dir="$PROFILE" >/dev/null 2>&1 &
  # wait up to ~20s for the debug port to come up
  for i in $(seq 1 20); do
    curl -s -m 2 "http://localhost:$PORT/json/version" >/dev/null 2>&1 && break
    sleep 1
  done
  if ! curl -s -m 3 "http://localhost:$PORT/json/version" >/dev/null 2>&1; then
    notify "Wiki YouTube" "Chrome debug n'a pas démarré — réessaie ou vérifie le profil."
    exit 1
  fi
  STARTED_CHROME=1
fi

# 2. scrape last 7 days
OUT="$(python3 "$SKILL_DIR/scrape_history.py" --days 7 2>/tmp/yt-scrape-err.log)"
if [ -z "$OUT" ] || echo "$OUT" | grep -q '^ERROR'; then
  notify "Wiki YouTube" "Session YouTube expirée ou scrape échoué — reconnecte-toi."
  exit 1
fi

# 3. save for review
mkdir -p "$HOME/.logseq-wiki"
echo "$OUT" > "$PENDING"
COUNT=$(echo "$OUT" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")

# 4. close the debug Chrome only if this script started it (leave a user-launched one alone)
if [ "${STARTED_CHROME:-0}" = "1" ]; then
  pkill -f "user-data-dir=$PROFILE" 2>/dev/null
fi

# 5. notify — human confirms + themes later
notify "Wiki YouTube" "$COUNT vidéos de la semaine prêtes. Lance /ingest-youtube-history --resume pour trier et ingérer."
