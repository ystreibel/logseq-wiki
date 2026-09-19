Exécute le pipeline complet d'ingestion de l'historique YouTube dans le wiki Logseq, de façon entièrement autonome (aucune validation humaine possible — tu es lancé par un cron).

Invoque d'abord le skill `ingest-youtube-history` pour les détails, mais voici le déroulé exact à suivre en mode automatique :

PARAMÈTRES FIXES DE CE RUN :
- Thème : tech + maker (IA/agents, dev, cloud, Kubernetes, DevOps, LLM, cybersécurité, self-hosting, domotique/Home Assistant, électronique/ESP32, home-lab)
- Période : 7 derniers jours
- Plafond : maximum 25 vidéos ingérées ce run (les plus pertinentes au thème si plus de candidats)
- Vault : lis `~/.logseq-wiki/config` pour LOGSEQ_VAULT_PATH

ÉTAPES :

1. SCRAPE — le wrapper a déjà lancé le scrape et écrit la liste dans `~/.logseq-wiki/yt-pending.json`. Lis ce fichier. S'il est absent ou vide, arrête-toi (rien à faire).

2. DÉDUP — exclus les vidéos dont le `vid` correspond déjà à une page `pages/videos___*.md` existante (grep les URLs/vid dans le vault).

3. FILTRE tech+maker — classe sémantiquement les titres+chaînes. Écarte : musique/clips, faits divers, OVNIs/paranormal, auto/moto perso, running/sport perso, politique, gaming. Garde uniquement le contenu tech/maker. Range chaque vidéo gardée en `veille-tech` (tech/IA/dev/cyber) ou `home-lab` (domotique/électronique/self-hosting). Plafonne à 25.

4. TRANSCRIPTS — écris la short-list en JSON, puis lance :
   `python3 <SKILL_DIR>/scripts/fetch_transcripts.py --in <shortlist>.json --out-dir <scratch>/yt-transcripts`
   (SKILL_DIR = le dossier de ce prompt). Garde les entrées `status: ok`.

5. DISTILLATION — pour chaque transcript OK, applique le flux ingest-video :
   - page source `pages/videos___<slug>.md` (type:: video, url::, sources:: NON — c'est la source ; transcript en blocs ## Transcript)
   - page wiki `wiki/<theme>/<page-slug>.md` : distillation FR, `sources:: [[videos/<slug>]]` (jamais une URL), sections thématiques, marqueurs ^[inferred]/^[ambiguous]
   - cross-linke vers les pages existantes pertinentes du thème (grep wiki/<theme>/ avant de lier — 0 lien cassé)
   - ajoute chaque page à `wiki/<theme>/_index.md`

6. MANIFEST + LOG — ajoute chaque page source au `wiki/_manifest.json` (clé = chemin fichier, hash, pages_created). Ajoute au `wiki/_log.md` :
   `- [ISO8601] INGEST-YT-HISTORY (auto) — <N> vidéos (theme=tech+maker, période=7j) → <détail thèmes>`

7. COMMIT — dans le vault, commit git avec l'identité UIRIS `Yohann STREIBEL <yohann.streibel@externe.systeme-u.fr>` et SANS AUCUN co-auteur Claude. Message : `[logseq-plugin-git:commit] <timestamp ISO8601>`. Push origin main.

8. NOTIFIE le résultat via Finder :
   `osascript -e 'tell application "Finder" to display notification "<N> vidéos ingérées (<détail>)" with title "Wiki YouTube"'`

RÈGLES ABSOLUES :
- Identité git vault = UIRIS ; JAMAIS de `Co-Authored-By: Claude`.
- `sources::` toujours en `[[videos/<slug>]]`, jamais une URL.
- Ne recopie jamais le transcript dans la page wiki (distillation seulement).
- Si une étape échoue franchement, notifie l'échec via Finder et arrête-toi proprement.
