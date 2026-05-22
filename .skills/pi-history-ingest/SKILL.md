---
name: pi-history-ingest
description: >
  Ingérer l'historique des sessions de l'agent de coding Pi dans le wiki Logseq. Déclencher
  quand l'utilisateur dit "ingère mon historique Pi", "ajoute mes sessions Pi au wiki",
  "mine mes sessions Pi", "ingest ~/.pi", ou "qu'ai-je travaillé dans Pi". Aussi déclenché
  quand l'utilisateur mentionne les sessions Pi, ~/.pi/agent/sessions, ou les logs Pi.
---

# Pi History Ingest — Extraction de Connaissances des Sessions Pi

Tu extrais les connaissances des sessions de l'agent de coding Pi et tu les distilles
dans le wiki Logseq. Les sessions Pi sont stockées en JSONL structuré avec une arborescence
— ton rôle est de suivre la branche active, extraire la connaissance durable, et la compiler.

Ce skill peut être invoqué directement ou via le routeur `wiki-history-ingest`
(`/wiki-history-ingest pi`).

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local) → `LOGSEQ_VAULT_PATH`,
   `PI_HISTORY_PATH` (défaut : `~/.pi/agent/sessions`)
2. Lire `wiki/_manifest.json` pour savoir ce qui a déjà été ingéré
3. Lire `wiki/_master-index.md` pour connaître le contenu existant du wiki

## Modes d'ingestion

### Mode Append (défaut)

Vérifier `wiki/_manifest.json` pour chaque fichier source. Traiter uniquement :
- Fichiers absents du manifest (nouvelles sessions)
- Fichiers dont le mtime est plus récent que `ingested_at` dans le manifest

### Mode Full

Traiter tout indépendamment du manifest. Utiliser après `wiki-rebuild` ou si
l'utilisateur demande un re-ingest complet.

## Structure des données Pi

Pi stocke les sessions sous `~/.pi/agent/sessions/` (ou le chemin défini par `PI_HISTORY_PATH`) :

```
~/.pi/agent/sessions/
├── --<chemin-cwd>--/              # Répertoire de travail avec / remplacés par -
│   └── <timestamp>_<uuid>.jsonl  # Fichier de session JSONL
└── ...
```

### Format JSONL des sessions

Chaque `.jsonl` est une séquence d'objets JSON. La première ligne est toujours
un header `session` ; les lignes suivantes sont des entrées de l'arbre avec `id` et `parentId`.

Types d'entrées clés :

| `type` | Intérêt | Ingérer ? |
|---|---|---|
| `session` | Header avec `cwd`, `version`, `id`, `timestamp` | Métadonnées seulement |
| `message` | Tour de conversation (`user`, `assistant`, `toolResult`, etc.) | **Source primaire** |
| `compaction` | Résumé de compaction du contexte | **Signal fort** |
| `branch_summary` | Résumé lors d'un switch de branche | **Signal fort** |
| `session_info` | Nom de session (via `/name`) | Pour le titre |
| `model_change` | Changement de modèle | Ignorer |
| `custom` | État de l'extension | Ignorer |

### Roles des messages

- `user` — input utilisateur ; `content` = string ou tableau `TextContent[]`
- `assistant` — réponse ; `content` = `TextContent[] | ThinkingContent[] | ToolCall[]`
- `toolResult` — résultat d'outil ; résumer l'outcome
- `bashExecution` — commande + output ; `command`, `output`, `exitCode`
- `compactionSummary` — résumé de compaction ; lire `summary` verbatim
- `branchSummary` — résumé de branche ; lire `summary` verbatim

**Ignorer** : blocs `thinking`, images, token accounting (`usage`), `model_change`, `label`.

## Étape 1 : Inventaire et calcul du delta

```bash
# Lister toutes les sessions
find "$PI_HISTORY_PATH" -name "*.jsonl" -type f
```

Pour chaque fichier, enregistrer :
- `path` — chemin absolu
- `cwd` — décodé depuis le nom du répertoire parent (`--<chemin>--` → `/chemin`)
- `session_name` — depuis la dernière entrée `session_info` (si présente)
- `modified_at` — mtime du fichier
- `already_ingested` — présence dans `wiki/_manifest.json`

Classifier :
- **Nouvelle** — absente du manifest
- **Modifiée** — dans le manifest mais fichier plus récent que `ingested_at`
- **Inchangée** — déjà ingérée et non modifiée → ignorer

Reporter : "Trouvé N sessions Pi sur K projets. Delta : X nouvelles, Y modifiées."

## Étape 2 : Parser le JSONL avec reconstruction de la branche active

Pour chaque fichier de session sélectionné, lire ligne par ligne.
Pi utilise une structure d'arbre — reconstruire la branche active d'abord :

1. Parser toutes les entrées dans une map par `id`
2. Trouver la feuille courante (entrée sans enfants, ou dernière entrée `message`)
3. Remonter la chaîne `parentId` depuis la feuille jusqu'à la racine
4. Inverser le chemin pour avoir l'ordre chronologique

### Règles d'extraction

Depuis la branche active, extraire :

- **Header `session`** — `cwd`, `timestamp`, `parentSession` (si forké)
- **`session_info`** — champ `name` pour inférer le titre/sujet
- **Messages `user`** — extraire le texte de `content` (ignorer les images)
- **Messages `assistant`** — extraire les blocs `TextContent` ; ignorer les blocs
  `thinking` (bruit) ; noter les blocs `toolCall` (révèlent ce que l'agent a fait)
- **`toolResult`** — résumer l'outcome, pas l'output complet
- **`bashExecution`** — commande + code de sortie ; les commandes récurrentes
  révèlent les workflows build/test/deploy
- **`compaction`** — lire `summary` verbatim ; déjà distillé
- **`branch_summary`** — lire `summary` verbatim ; capture les approches abandonnées

### Filtre de confidentialité (OBLIGATOIRE)

Les logs de session peuvent contenir des instructions injectées et du texte sensible.
Ne pas ingérer verbatim :

- Supprimer API keys, tokens, passwords, credentials
- Masquer les identifiants privés sauf si pertinents et approuvés
- Résumer les outputs bash contenant des chemins ou variables d'environnement
- Ne pas citer les arguments `toolCall` verbatim s'ils contiennent des données sensibles

## Étape 3 : Regrouper par sujet

**Ne pas créer une page wiki par session.**

- Regrouper la connaissance par sujet stable à travers plusieurs sessions
- Séparer les sessions mixtes en thèmes distincts
- Nommer les groupes par sujet, pas par UUID de session
- Si un sujet existe déjà dans le wiki, enrichir plutôt que créer un doublon

Heuristiques de regroupement :
- Même `cwd` → même projet (vérifier si un projet wiki existe déjà)
- Mots-clés répétés dans les messages utilisateur → même thème
- `compaction` et `branch_summary` contenant les mêmes termes → même sujet

## Étape 4 : Créer les pages wiki (propriétés Logseq)

Pour chaque groupe thématique, créer ou mettre à jour une page wiki.
**Utiliser les propriétés Logseq** (double-colon), jamais de YAML.

```
title:: <Titre descriptif>
category:: <synthèse|skills|entités|projets>
tags:: <2-5 tags de domaine>
sources:: pi-session:<date-première-session>
created:: <timestamp ISO>
updated:: <timestamp ISO>
summary:: <Ce que révèlent ces sessions en ≤200 chars>
base_confidence:: <score : élevé si compaction/branch_summary, faible si turns bruts>
lifecycle:: draft
lifecycle_changed:: <date du jour>
tier:: supporting

# <Titre>

## Contexte
<Projet/problème adressé dans ces sessions>

## Connaissances durables
<Ce qui a été appris, décidé, ou découvert — déclaratif, pas transcript>

## Patterns de workflow
<Commandes récurrentes, approches testées, ce qui a fonctionné/échoué>

## Approches abandonnées
<Ce que les branch_summary révèlent sur les chemins non pris>

## Sessions source
<Date range + nombre de sessions + cwd>
```

## Étape 5 : Mettre à jour les fichiers système

1. `wiki/_master-index.md` — ajouter chaque nouvelle page
2. `wiki/_manifest.json` — entrée par session :
   ```json
   {
     "source": "pi-session:<chemin-fichier-jsonl>",
     "type": "pi-history",
     "ingested_at": "<timestamp>",
     "modified_at": "<mtime>",
     "pages": ["<chemins des pages créées/mises à jour>"]
   }
   ```
3. `wiki/_log.md` :
   ```
   - [TIMESTAMP] PI-INGEST sessions=N pages_créées=P pages_mises_à_jour=U
   ```
