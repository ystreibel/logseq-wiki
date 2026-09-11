---
name: ingest-youtube-history
description: >
  Ingest videos from your YouTube watch history into the Logseq wiki, filtered by theme and
  time window. Use when the user says "/ingest-youtube-history", "ingère mes vidéos YouTube de
  la semaine", "ajoute mon historique YouTube au wiki", "les vidéos <thème> que j'ai regardées",
  or wants a recurring weekly ingest of watched videos. Scrapes history via a logged-in Chrome,
  fetches transcripts via NotebookLM (no cookies), distils into the wiki.
---

# Ingest YouTube History — Themed, time-windowed

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

## Why this exists

YouTube's watch history is **not accessible via yt-dlp** (private data, no API since 2016) and
exported cookies expire within hours (rotation). This skill solves both:
- **History** is read by scraping `youtube.com/feed/history` in a **logged-in Chrome debug instance**
- **Transcripts** are fetched by **NotebookLM** (`nlm` CLI), which ingests YouTube **server-side —
  no cookies, no rate-limit** on subtitles

Parameters: `--theme "<free text>"` (e.g. `tech`, `maker`, `UTMB`, `home studio`; presets
`tech`/`maker`/`all`) and `--period` (default **7 days**; `jour`/`semaine`/`mois`/`année`/`Nj`).

## Prerequisites (verify, guide if missing)

1. **Config** — read `~/.logseq-wiki/config` for `LOGSEQ_VAULT_PATH`.
2. **Debug Chrome with a logged-in YouTube session.** Check the port responds:
   `curl -s http://localhost:9222/json/version`. If not, tell the user to run:
   ```
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --remote-debugging-port=9222 "--remote-allow-origins=*" \
     --user-data-dir="$HOME/.logseq-wiki/chrome-debug" >/dev/null 2>&1 &
   ```
   and sign in to YouTube once in that window (session persists in that dedicated profile).
3. **NotebookLM CLI authenticated** — `nlm notebook list` should return JSON. If it errors, the
   user runs `nlm login` (interactive; it holds the terminal until the browser flow completes).
4. `pip install websocket-client` if the scraper reports it missing.

## Step 1: Scrape history (time-windowed)

Parse `--period` into a day count N (jour=1, semaine=7, mois=30, année=365, `Nj`=N). Then:
```
python3 scripts/scrape_history.py --days N
```
It prints a JSON list of `{resolved_date, url, title, channel, vid}` for the last N days,
after verifying the session is logged in (it exits with a clear error otherwise).

## Step 2: Filter by theme (your judgment, not a script)

Read the scraped titles and **classify each by relevance to `--theme`** — this is semantic
judgment, done by you, not a keyword script. Presets:
- `tech` → IA/agents, dev, cloud, Kubernetes, DevOps, LLM, self-hosting infra
- `maker` → domotique (Home Assistant), électronique (ESP32), 3D printing, home-lab
- `all` → any informative content; exclude only music, faits divers, perso, gaming
- free text (`UTMB`, `home studio`, …) → videos matching that subject

Keep a short-list ranked by relevance. **Show it numbered to the user and ask for confirmation**
(they may drop numbers), unless invoked in `--auto` mode (see Step 5). Never ingest the full
history unfiltered — it is mostly noise.

## Step 3: Fetch transcripts via NotebookLM

Write the confirmed short-list to a JSON file, then:
```
python3 scripts/fetch_transcripts.py --in shortlist.json --out-dir <scratch>/yt-transcripts
```
It creates a temp NotebookLM notebook, adds each video with `--youtube --wait`, retrieves each
raw transcript, writes one `.txt` per video, and deletes the notebook. Output is a JSON manifest
with `status` per video (`ok`/`add_failed`/`empty_transcript`) and `transcript_path`.

Skip videos already in the wiki manifest (dedup by URL / `pages/videos___<slug>.md`).

## Step 4: Distil into the wiki

For each `ok` transcript, apply the **ingest-video** flow:
- Raw source page `pages/videos___<slug>.md` (namespace `videos/`, `type:: video`, `url::`,
  `sources::` as `[[videos/<slug>]]`), transcript in `## Transcript` blocks
- Distilled wiki page in the detected theme, `sources:: [[videos/<slug>]]`, provenance markers
- Update `wiki/<theme>/_index.md`, `wiki/_manifest.json` (keyed by the file path), `wiki/_log.md`:
  `- [ISO8601] INGEST-YT-HISTORY — <N> videos (theme=<t>, period=<p>) → wiki/...`

## Step 5: Recurring semi-auto mode (launchd)

For weekly automation, install the launchd agent (see `scripts/com.logseq-wiki.yt-history.plist`
and Step 5 of the skill's setup note): it runs Steps 1–2 automatically, writes the short-list to
`~/.logseq-wiki/yt-pending.json`, and **notifies** the user via macOS notification. The user
then runs `/ingest-youtube-history --resume` to review + ingest. This keeps a human in the loop
for a 30-second validation while doing all the heavy work automatically.

Session safety: the launchd job verifies the debug-Chrome session first; if expired, it notifies
"YouTube session expired — sign in again" instead of failing silently.

## Pièges connus

| Piège | Réalité |
|-------|---------|
| yt-dlp pour l'historique | Impossible (donnée privée) — scraper le navigateur connecté |
| Cookies exportés | Expirent en heures (rotation Google) — passer par NotebookLM server-side |
| Debug sur le profil Chrome par défaut | Chrome 136+ le neutralise — profil dédié `~/.logseq-wiki/chrome-debug` |
| WebSocket refusé | Ajouter `--remote-allow-origins=*` au lancement de Chrome |
| Ingérer tout l'historique | Surtout du bruit (musique, divers) — toujours filtrer par thème |
| MCP NotebookLM auth expirée | Utiliser le CLI `nlm` (indépendant de l'état du serveur MCP) |
| cron full-auto sans garde-fou | Session peut expirer → semi-auto avec notification |
