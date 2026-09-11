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

notify() { osascript -e "display notification \"$2\" with title \"$1\"" 2>/dev/null; }

# 1. session check — fail loud, not silent
if ! curl -s -m 5 "http://localhost:$PORT/json/version" >/dev/null 2>&1; then
  notify "Wiki YouTube" "Chrome debug non lancé — impossible de lire l'historique."
  exit 1
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

# 4. notify — human confirms + themes later
notify "Wiki YouTube" "$COUNT vidéos de la semaine prêtes. Lance /ingest-youtube-history --resume pour trier et ingérer."
