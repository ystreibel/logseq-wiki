---
name: copilot-history-ingest
description: >
  Ingérer l'historique des sessions GitHub Copilot dans le wiki Logseq sous forme de pages
  de connaissance distillées. Déclencher quand l'utilisateur dit "ingère mes sessions copilot",
  "ajoute mon historique copilot au wiki", "mine mes sessions copilot", "juste les nouvelles
  sessions depuis la dernière fois", ou mentionne session-store.db, ~/.copilot/session-state,
  ou les transcripts VS Code dans le contexte de construction d'un wiki. NE PAS déclencher
  pour les questions générales sur Copilot ou la recherche dans les sessions.
---

# Copilot History Ingest — Extraction de Connaissances

Tu extrais les connaissances des conversations GitHub Copilot passées et tu les distilles
dans le wiki Logseq. Les conversations sont riches mais bruyantes — ton rôle est de trouver
le signal et de le compiler.

Ce skill peut être invoqué directement ou via le routeur `wiki-history-ingest`
(`/wiki-history-ingest copilot`).

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local) → `LOGSEQ_VAULT_PATH`,
   `COPILOT_HISTORY_PATH` (défaut : `~/.copilot/session-state`),
   `COPILOT_VSCODE_STORAGE_PATH` (plateforme-dépendant — demander si absent)
2. Lire `wiki/_manifest.json` pour savoir ce qui a déjà été ingéré
3. Lire `wiki/_master-index.md` pour connaître le contenu existant du wiki

## Modes d'ingestion

### Mode Append (défaut)

Vérifier `wiki/_manifest.json` pour chaque fichier source. Traiter uniquement :
- Sessions absentes du manifest (nouvelles sessions)
- Sessions dont `updated_at` est plus récent que `ingested_at` dans le manifest

### Mode Full

Traiter tout indépendamment du manifest. Utiliser après un `wiki-rebuild` ou si
l'utilisateur demande explicitement.

## Sources de données Copilot

Copilot stocke les données à trois endroits. Scanner **les trois**.

### Source 1 : `~/.copilot/session-state/` (sessions CLI)

```
~/.copilot/session-state/
├── <session-uuid>/
│   ├── workspace.yaml           # Métadonnées (id, cwd, created_at, updated_at)
│   ├── vscode.metadata.json     # Contexte VS Code (workspaceFolder, branch, customTitle)
│   ├── events.jsonl             # Log complet — tous les tours, tool calls
│   ├── index.md                 # Résumé de session (écrit en fin de session)
│   ├── checkpoints/
│   │   └── <uuid>.json          # title, overview, work_done, technical_details,
│   │                            #   important_files, next_steps
│   └── files/                   # Artifacts produits
└── ...
```

### Source 2 : `~/.copilot/session-store.db` (SQLite global)

La source la plus structurée. Tables clés :
```
sessions    — id, cwd, repository, branch, summary, created_at, updated_at
turns       — session_id, turn_index, user_message, assistant_response, timestamp
checkpoints — session_id, checkpoint_number, title, overview, work_done,
              technical_details, important_files, next_steps
session_files — session_id, file_path, tool_name, turn_index
search_index  — FTS5 (content, session_id, source_type, source_id)
```

### Source 3 : VS Code Workspace Storage

```
<workspaceStorage>/<hash>/GitHub.copilot-chat/
├── transcripts/<session-uuid>.jsonl
└── memory-tool/memories/<base64-id>/plan.md
```

### Valeur des sources (ordre décroissant)

1. **Checkpoints** — résumés pré-distillés avec `work_done`, `technical_details` → or
2. **Résumés de session** (`sessions.summary` + `index.md`) → très utile
3. **Turns** (conversations complètes) → riche mais verbeux
4. **Memory artifacts** (`plan.md`) → importer quasi-verbatim
5. **Patterns d'accès fichiers** (`session_files`) → révèle les fichiers clés du projet
6. **Session refs** → commits, PRs, issues liés

## Étape 1 : Inventaire et calcul du delta

```bash
# Source 1 — répertoires de sessions
ls ~/.copilot/session-state/

# Source 2 — base SQLite
sqlite3 ~/.copilot/session-store.db "
SELECT s.id, s.cwd, s.summary, s.updated_at,
       COUNT(DISTINCT c.id) AS checkpoint_count
FROM sessions s
LEFT JOIN checkpoints c ON c.session_id = s.id
GROUP BY s.id ORDER BY s.updated_at DESC;"
```

Construire un inventaire unifié — une entrée par UUID de session. Classifier :
- **Nouvelle** — absente du manifest → à ingérer
- **Modifiée** — dans le manifest mais `updated_at` plus récent → re-ingérer
- **Inchangée** — déjà ingérée et non modifiée → ignorer

Reporter : "Trouvé X sessions dans session-state, Y dans session-store.db, Z transcripts VS Code. Delta : B nouvelles, C modifiées."

## Étape 2 : Ingérer les checkpoints et résumés en premier

Les checkpoints sont déjà distillés — les traiter avant les turns bruts.

```sql
SELECT s.id, s.cwd, s.repository, s.summary,
       c.title, c.overview, c.work_done,
       c.technical_details, c.important_files, c.next_steps
FROM checkpoints c
JOIN sessions s ON c.session_id = s.id
ORDER BY s.updated_at DESC, c.checkpoint_number ASC;
```

Lire aussi `index.md` par session si présent.

## Étape 3 : Parser les turns (si les checkpoints sont insuffisants)

Pour les sessions sans checkpoints, parser `events.jsonl` :

- Extraire les messages `user` et `assistant` (ignorer `thinking`, images, tool outputs bruts)
- Extraire les `bashExecution` — commandes récurrentes = patterns de workflow
- **Filtre de confidentialité** : supprimer API keys, tokens, passwords ; résumer
  les outputs bash contenant des chemins ou variables d'environnement sensibles

## Étape 4 : Regrouper par sujet

**Ne pas créer une page wiki par session.**

- Regrouper la connaissance par sujet stable à travers plusieurs sessions
- Séparer les sessions mixtes en thèmes distincts
- Nommer les groupes par sujet, pas par session UUID
- Si un sujet existe déjà dans le wiki, enrichir la page plutôt que créer un doublon

## Étape 5 : Créer les pages wiki (propriétés Logseq)

Pour chaque groupe thématique identifié, créer ou mettre à jour une page wiki.
**Utiliser les propriétés Logseq** (double-colon), jamais de YAML.

Le namespace cible dépend du type de connaissance :
- Architecture, décisions → `wiki/synthèse/`
- Patterns, techniques → `wiki/skills/` ou thème dynamique
- Outils, bibliothèques découverts → `wiki/entités/`
- Projet spécifique → `wiki/projets/<nom-projet>/`

```
title:: <Titre descriptif>
category:: <synthèse|skills|entités|projets>
tags:: <2-5 tags de domaine>
sources:: copilot-session:<date-première-session>
created:: <timestamp ISO>
updated:: <timestamp ISO>
summary:: <Ce que révèle ce groupe de sessions en ≤200 chars>
base_confidence:: <score basé sur N checkpoints vs turns bruts>
lifecycle:: draft
lifecycle_changed:: <date du jour>
tier:: supporting

# <Titre>

## Contexte
<Quel projet/problème ces sessions adressaient>

## Ce qui a été appris / décidé
<Connaissance durable — déclaratif, pas transcript>

## Patterns identifiés
<Patterns récurrents observés à travers les sessions>

## Fichiers clés impliqués
<Fichiers les plus touchés (depuis session_files)>

## Sessions source
<Date range + nombre de sessions>
```

## Étape 6 : Mettre à jour les fichiers système

1. `wiki/_master-index.md` — ajouter chaque nouvelle page
2. `wiki/_manifest.json` — entrée par session ingérée :
   ```json
   {
     "source": "copilot-session:<uuid>",
     "type": "copilot-history",
     "ingested_at": "<timestamp>",
     "updated_at": "<session_updated_at>",
     "pages": ["<chemins des pages créées/mises à jour>"]
   }
   ```
3. `wiki/_log.md` :
   ```
   - [TIMESTAMP] COPILOT-INGEST sessions=N pages_créées=P pages_mises_à_jour=U
   ```
