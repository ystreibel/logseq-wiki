---
name: logseq-llm-wiki
description: >
  Skill fondation — primitives de lecture, syntaxe Logseq, règles d'écriture wiki.
  Invoqué automatiquement par tous les autres skills logseq-*. Ne pas invoquer directement.
---

# Logseq LLM Wiki — Fondation

Ce skill est la base commune à tous les skills logseq-*. Il définit les primitives de lecture,
la syntaxe Logseq, le format des pages wiki, et la structure du manifest.

## Vault

Le vault est toujours le répertoire de travail courant. Structure :
- `pages/` — thèmes et projets (lecture seule)
- `journals/` — notes quotidiennes au format `YYYY_MM_DD.md` (lecture seule)
- `assets/` — images et PDFs référencés dans les .md (lecture seule)
- `wiki/` — wiki généré par Claude (lecture + écriture)
  - `wiki/_master-index.md` — index global
  - `wiki/_manifest.json` — tracking des sources ingérées
  - `wiki/_log.md` — historique des opérations
  - `wiki/[thème]/_index.md` — index par thème
  - `wiki/[thème]/[page].md` — page wiki

## Primitives de lecture

Utilise toujours la primitive la moins coûteuse qui répond au besoin :

| Besoin | Primitive | Coût |
|--------|-----------|------|
| Trouver des fichiers contenant un terme | Grep (files_with_matches) | ~0 token |
| Lire le contenu d'un fichier ciblé | Read | faible |
| Lister les fichiers d'un dossier | Glob | ~0 token |
| Chercher un pattern dans un fichier | Grep (content) | faible |

**Règle :** Grep d'abord pour identifier, Read ensuite pour lire. Ne jamais faire un Read
de tous les fichiers d'un dossier sans Grep préalable sauf si explicitement nécessaire.

## Syntaxe Logseq

### Propriétés de page (toujours en début de fichier)
```
title:: Nom de la page
category:: nom-du-thème
tags:: tag1, tag2, tag3
sources:: [[Page Source]], [[journals/2026_04_01]]
summary:: Résumé en une phrase (≤200 caractères)
created:: YYYY-MM-DD
updated:: YYYY-MM-DD
```

### Blocs
- Les blocs sont des lignes commençant par `- `
- L'indentation (tabulation) crée des sous-blocs
- `collapsed:: true` sur un bloc le replie dans l'UI

### Workflow (config `:preferred-workflow :now`)
- `NOW` — tâche en cours
- `LATER` — tâche planifiée
- `DONE` — tâche terminée
- **Ne jamais utiliser TODO/DOING** — ce vault utilise NOW/LATER/DONE

### Liens
- `[[Nom de page]]` — lien vers une page du vault
- `[[wiki/kubris/kubernetes-3488]]` — lien vers une page wiki (namespace)
- Les assets sont référencés via `![](../assets/fichier.png)`

### Format fichiers
- Noms de fichiers : `:triple-lowbar` — les `/` dans les titres deviennent `___`
- Journaux : `YYYY_MM_DD.md`

### LOGBOOK
Les blocs de temps trackés ont ce format — à lire mais ne jamais écrire :
```
:LOGBOOK:
CLOCK: [2026-03-05 Thu 09:58:29]--[2026-03-09 Mon 16:23:39] =>  102:25:10
:END:
```

## Format des pages wiki

Chaque page wiki respecte ce format :

```markdown
title:: [Titre descriptif]
category:: [thème]
tags:: [tag1, tag2]
sources:: [[Source1]], [[Source2]]
summary:: [1 phrase ≤200 chars]
created:: YYYY-MM-DD
updated:: YYYY-MM-DD

# [Titre]

## [Section]
- Fait extrait directement de la source
- Décision ou inférence ^[inferred]
- Information contradictoire ou ambiguë ^[ambiguous]

## Liens
- [[wiki/[thème]/_index]]
- [[wiki/[thème]/[page-liée]]]
```

### Règles d'écriture
- Propriétés Logseq natives en tête — **jamais de YAML frontmatter**
- `[[liens]]` vers autres pages wiki ET vers sources originales
- `^[inferred]` pour les déductions (pas explicitement dans la source)
- `^[ambiguous]` pour les contradictions entre sources
- Langue : **toujours français**
- Jamais de modification des sources (`pages/`, `journals/`, `assets/`)
- `wiki/` uniquement pour l'écriture

## Structure `_manifest.json`

```json
{
  "version": 1,
  "last_ingest": "YYYY-MM-DDTHH:MM:SS",
  "stats": {
    "total_sources_ingested": 0,
    "total_pages_created": 0
  },
  "sources": {
    "pages/fichier.md": {
      "ingested_at": "YYYY-MM-DDTHH:MM:SS",
      "content_hash": "sha256:<64-char-hex>",
      "pages_created": ["wiki/thème/page"],
      "pages_updated": []
    }
  }
}
```

**Calcul du hash :** `shasum -a 256 <fichier> | awk '{print $1}'`

## Structure `_log.md`

```markdown
## Log

- [YYYY-MM-DDTHH:MM:SS] SETUP — initialisation du wiki
- [YYYY-MM-DDTHH:MM:SS] INGEST — N sources, M pages créées
- [YYYY-MM-DDTHH:MM:SS] UPDATE — N sources modifiées, M pages mises à jour
- [YYYY-MM-DDTHH:MM:SS] REBUILD — archive vers wiki/_archive/YYYY-MM-DD/
```
