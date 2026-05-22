---
name: llm-wiki
description: >
  Skill fondation — primitives de lecture, syntaxe Logseq, règles d'écriture wiki.
  Invoqué automatiquement par tous les autres skills wiki-*. Ne pas invoquer directement.
---

# Logseq LLM Wiki — Fondation

Ce skill est la base commune à tous les skills wiki-*. Il définit les primitives de lecture,
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

### Propriétés de page (toujours en début de fichier, sans séparateurs ---)
```
title:: Nom de la page
category:: nom-du-thème
tags:: tag1, tag2, tag3
sources:: [[Page Source]], [[journals/2026_04_01]]
summary:: Résumé en une phrase (≤200 caractères)
provenance:: extracted: 0.72, inferred: 0.25, ambiguous: 0.03
base_confidence:: 0.65
lifecycle:: draft
lifecycle_changed:: 2026-05-22
tier:: supporting
created:: 2026-05-22
updated:: 2026-05-22
relationships:: [[wiki/concepts/related-concept]] (extends), [[wiki/entities/related-entity]] (uses)
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
- `[[wiki/devops/kubernetes-basics]]` — lien vers une page wiki (namespace)
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

## Importance Tiering (`tier::`)

La propriété `tier::` contrôle la priorité de mise à jour lors de l'ingestion et de recherche lors des requêtes :
- **`core`** : Pages centrales à forte connectivité (≥5 liens entrants ou ponts structurels). Toujours mises à jour, même si la source n'est que marginalement reliée. Prioritaires en recherche.
- **`supporting`** (défaut) : Pages standard avec connectivité modérée. Mises à jour si la source apporte de nouveaux faits.
- **`peripheral`** : Faible connectivité (≤1 lien entrant, pas de mise à jour depuis 90+ jours). Ignorées ou skippées si le budget de jetons contextuels est serré.

## Confiance et Cycle de Vie (`base_confidence::`, `lifecycle::`)

Chaque page intègre des signaux de confiance et de cycle de vie.

### base_confidence::
Calculé automatiquement lors de l'écriture :
`base_confidence = source_count_score * 0.5 + source_quality_score * 0.5`
- `source_count_score = min(distinct_source_ids / 3, 1.0)`
- `source_quality_score = avg(qualité de chaque source distincte)`

Qualité des sources :
- `paper` (arXiv, conf) : 1.0
- `official` (docs constructeurs, .gov) : 0.9
- `documentation` (docs tierces de qualité) : 0.85
- `book` : 0.8
- `repository` (READMEs, codebases) : 0.75
- `blog` : 0.55
- `session_transcript` : 0.5
- `forum` (StackOverflow, HN, Reddit) : 0.4
- `unknown` : 0.4
- `llm_generated` (auto-réflexions LLM) : 0.3

### lifecycle::
Cycle de vie de la page :
- **`draft`** : État initial écrit par l'agent.
- **`reviewed`** : Validé par un humain.
- **`verified`** : Fortement validé (non dégradé par le temps).
- **`disputed`** : Contradiction ou doute signalé par l'humain ou un lint.
- **`archived`** : Obsolète. Si archivé, peut inclure `superseded_by:: [[wiki/concepts/nouvelle-page]]`.

## Relations Typées (`relationships::`)

Permet d'ajouter des liens sémantiques orientés entre les concepts :
`relationships:: [[wiki/concepts/transformer-architecture]] (extends), [[wiki/concepts/lstm]] (contradicts)`

Types autorisés :
- `extends` : Construit ou généralise la cible.
- `implements` : Réalisation concrète de la cible.
- `contradicts` : Conflit direct ou réfutation de la cible.
- `derived_from` : Basé sur / adapté de la cible.
- `uses` : Dépendance technique.
- `replaces` : Remplace ou rend obsolète la cible.
- `related_to` : Lien simple, valeur par défaut.

## Provenance des Allégations (`provenance::`)

Sur chaque bloc de la page, des annotations permettent de tracer la provenance :
- Aucun marqueur : Fait extrait directement de la source (Extracted).
- **`^[inferred]`** : Déduction, extrapolation ou synthèse par l'LLM.
- **`^[ambiguous]`** : Sources contradictoires ou douteuses.

La propriété de page résume les ratios :
`provenance:: extracted: 0.70, inferred: 0.20, ambiguous: 0.10`

## Format des pages wiki

Chaque page wiki respecte ce format :

```markdown
title:: [Titre descriptif]
category:: [thème]
tags:: [tag1, tag2]
sources:: [[Source1]], [[Source2]]
summary:: [1 phrase ≤200 chars]
provenance:: extracted: 1.00, inferred: 0.00, ambiguous: 0.00
base_confidence:: 0.65
lifecycle:: draft
lifecycle_changed:: YYYY-MM-DD
tier:: supporting
created:: YYYY-MM-DD
updated:: YYYY-MM-DD
relationships:: [[wiki/[thème]/[autre-page]]] (related_to)

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

**Stats globales — recalcul obligatoire (jamais d'incrémentation) :**
- `total_sources_ingested` = `len(sources)` — nombre de clés dans l'objet `sources{}`
- `total_pages_created` = nombre de fichiers `.md` dans `wiki/` en excluant :
  `_master-index.md`, `_log.md`, tout fichier dans `wiki/_meta/`, tout fichier dans
  `wiki/_archive/`

Ces valeurs sont toujours recalculées depuis les données réelles à chaque mise à jour du
manifest, jamais incrémentées.

## Structure `_log.md`

```markdown
## Log

- [YYYY-MM-DDTHH:MM:SS] SETUP — initialisation du wiki
- [YYYY-MM-DDTHH:MM:SS] INGEST — N sources, M pages créées
- [YYYY-MM-DDTHH:MM:SS] UPDATE — N sources modifiées, M pages mises à jour
- [YYYY-MM-DDTHH:MM:SS] REBUILD — archive vers wiki/_archive/YYYY_MM_DD/
```
