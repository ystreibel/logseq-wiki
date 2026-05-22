---
name: daily-update
description: >
  Exécuter le cycle de maintenance quotidienne du wiki : vérifier la fraîcheur de toutes
  les sources, mettre à jour l'index, et régénérer le contexte chaud. Déclencher quand
  l'utilisateur dit "/daily-update", "lancer la mise à jour quotidienne", "mettre tout à jour",
  "sync du matin", "rafraîchir l'index wiki", ou lors du déclenchement par launchd à 9h.
  Aussi utile pour configurer ou vérifier l'infrastructure cron + notification terminal
  pour la première fois.
---

# Daily Update — Cycle de Maintenance Quotidienne

Tu exécutes une passe de maintenance légère sur le wiki : vérifier la fraîcheur des sources,
rafraîchir l'index, régénérer le contexte chaud, et écrire le fichier d'état que la
notification terminal lit.

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local) → `LOGSEQ_VAULT_PATH`, `LOGSEQ_WIKI_REPO`
2. **Dériver le répertoire d'état scopé au vault** :
   ```bash
   VAULT_ID=$(echo "$LOGSEQ_VAULT_PATH" | md5sum 2>/dev/null | cut -c1-8 \
              || md5 -q - <<< "$LOGSEQ_VAULT_PATH" | cut -c1-8)
   STATE_DIR="$HOME/.logseq-wiki/state/$VAULT_ID"
   mkdir -p "$STATE_DIR"
   ```
3. Lire `$LOGSEQ_VAULT_PATH/wiki/_manifest.json`

## Modes

### Mode Run (défaut — déclenché par cron ou `/daily-update`)

Exécuter le cycle de maintenance :

**Étape 1 : Vérification de fraîcheur des sources**

Comparer chaque source dans `_manifest.json` avec le temps de modification du fichier.
Classifier comme :
- **Fraîche** — `mtime ≤ ingested_at`
- **Périmée** — `mtime > ingested_at` (nouveau contenu existe, pas encore ingéré)
- **Manquante** — le fichier source n'existe plus

**Étape 2 : Rafraîchissement de l'index**

Lire `$LOGSEQ_VAULT_PATH/wiki/_master-index.md`. Si des pages du vault manquent dans
l'index (ou inversement), mettre à jour l'index. Utiliser :
```bash
find "$LOGSEQ_VAULT_PATH/wiki" -name "*.md" \
  ! -path "*/wiki/_*" ! -name "_master-index.md"
```
pour énumérer les pages wiki, puis réconcilier avec l'index.

**Étape 3 : Mise à jour du contexte chaud**

Lire les 200 dernières lignes de `wiki/_log.md` (contexte de session). Si le dernier
log date de plus de 48h, lire les 10 pages wiki les plus récemment modifiées et écrire
un snapshot sémantique de ~300 mots en bas de `wiki/_log.md` sous la section :
```
## Contexte chaud — <YYYY-MM-DD>
<snapshot>
```

**Étape 4 : Écriture de l'état**

Écrire dans `$STATE_DIR` :
```bash
date +%s > "$STATE_DIR/.last_update"
echo "<nombre_sources_périmées>" > "$STATE_DIR/.pending_delta"
echo "$LOGSEQ_VAULT_PATH" > "$STATE_DIR/.vault_path"
```

**Étape 5 : Log**

Ajouter dans `$LOGSEQ_VAULT_PATH/wiki/_log.md` :
```
- [TIMESTAMP] DAILY-UPDATE fraîches=N périmées=N manquantes=N index_ajoutées=N contexte_rafraîchi=true|false
```

**Étape 6 : Rapport à l'utilisateur**

```
## Mise à jour quotidienne du Wiki

- Sources : N fraîches · N périmées · N manquantes
- Index : N pages (N ajoutées, N retirées)
- Contexte : rafraîchi / à jour

Sources périmées (à synchroniser) :
  /wiki-history-ingest claude   — N sessions depuis le dernier ingest
  /wiki-history-ingest codex    — N sessions depuis le dernier ingest
```

---

### Mode Setup (déclenché par "configurer le cron" ou "installer la notification terminal")

Guider l'utilisateur pour la configuration initiale :

**Étape 1 : Vérifier le script**

Vérifier que `$LOGSEQ_WIKI_REPO/scripts/daily-update.sh` existe et est exécutable. Sinon,
demander à l'utilisateur de le créer ou de cloner le repo.

**Étape 2 : Installer le plist launchd (macOS)**

```bash
# Remplacer le placeholder dans le plist
sed "s|LOGSEQ_WIKI_REPO|$LOGSEQ_WIKI_REPO|g" \
  "$LOGSEQ_WIKI_REPO/scripts/com.logseq-wiki.daily-update.plist" \
  > "$HOME/Library/LaunchAgents/com.logseq-wiki.daily-update.plist"

# Charger
launchctl load "$HOME/Library/LaunchAgents/com.logseq-wiki.daily-update.plist"
```

**Étape 3 : Installer la notification terminal (optionnel)**

Demander à l'utilisateur : "Veux-tu une notification terminal quand ton wiki est périmé ? (o/n)"

Si oui, détecter le shell et le bon fichier rc :
```bash
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  bash) RC_FILE="$HOME/.bashrc" ;;
  *)    echo "Shell '$SHELL_NAME' non auto-détecté. Ajouter manuellement au fichier rc." ; return ;;
esac
```

Vérifier si `wiki-notify.sh` est déjà sourcé. Sinon, ajouter :
```bash
echo "" >> "$RC_FILE"
echo "# logseq-wiki notification terminal" >> "$RC_FILE"
echo "source $LOGSEQ_WIKI_REPO/scripts/wiki-notify.sh" >> "$RC_FILE"
```

**Étape 4 : Premier run**

```bash
bash "$LOGSEQ_WIKI_REPO/scripts/daily-update.sh"
```

Initialise `$STATE_DIR/.last_update` pour que la notification fonctionne immédiatement.

**Étape 5 : Confirmer**

Informer l'utilisateur :
- Le cron tourne quotidiennement à 9h (ou au prochain login si manqué)
- La notification terminal s'affiche à l'ouverture du terminal si des sources sont périmées
- Pour désactiver : `launchctl unload ~/Library/LaunchAgents/com.logseq-wiki.daily-update.plist`

## Notes

- Le script `daily-update.sh` dans le repo est un wrapper shell léger qui lance
  l'agent (Copilot, Claude, etc.) avec cette skill
- L'état est scopé au vault (hash du chemin) — plusieurs vaults coexistent sans conflit
- Sur Linux, utiliser crontab à la place de launchd
