---
name: wiki-synthesize
description: >
  Découvre systématiquement les opportunités de synthèse dans le wiki Logseq — des paires ou groupes
  de concepts qui apparaissent souvent ensemble dans les pages mais n'ont aucune page de synthèse les reliant.
  Crée de nouvelles pages de synthèse dans `wiki/synthesis/` qui tirent des conclusions croisées explicites.
  Use when the user says "synthesize my wiki", "trouve des connexions", "quels concepts apparaissent ensemble",
  "/wiki-synthesize", ou après une ingestion massive lorsque le wiki a grandi.
---

# Wiki Synthesize — Découverte et Création de Synthèses de Premier Plan

Ce skill scanne le wiki pour détecter des concepts qui apparaissent souvent ensemble sur les mêmes pages, mais qui ne disposent d'aucune page de synthèse dédiée pour expliciter leur relation. Votre rôle est de faire émerger ces lacunes et de rédiger des pages de synthèse croisées de haute valeur ajoutée.

## Avant de commencer

1. **Résoudre la configuration** — suivez le protocole de résolution de configuration dans `llm-wiki/SKILL.md` pour obtenir `LOGSEQ_VAULT_PATH`.
2. Lire `wiki/_master-index.md` pour obtenir l'inventaire complet des pages physiques.
3. Lire `wiki/hot.md` si présent pour repérer l'activité récente et les fils de discussion actifs.
4. Consulter `wiki/_meta/taxonomy.md` (ou index) pour comprendre le vocabulaire des tags du wiki.

## Étape 1 : Construire la Carte de Co-occurrence

Parcourir toutes les pages classiques du wiki (exclure `_master-index.md`, `_log.md`, `hot.md`, les index thématiques, `_staging/`, `_archives/`, `_raw/`).

Pour chaque page, extraire :
- Tous les wikilinks sortants (`[[wiki/theme/page]]`)
- Les propriétés `tags::`
- La propriété `category::`

Construire une matrice de co-occurrence : pour chaque paire de concepts ou d'entités (A, B), compter combien de pages pointent vers **les deux** à la fois. Ce nombre constitue leur score de co-occurrence.

Pour les wikis volumineux, inutile d'être exhaustif sur toutes les combinaisons : ciblez les 20 à 30 meilleures paires candidates. Utilisez Grep pour trouver les backlinks efficacement :

```bash
grep -rl "\[\[wiki/.*ConceptA\]\]" "$LOGSEQ_VAULT_PATH/wiki" --include="*.md"
```

## Étape 2 : Filtrer les Paires Déjà Synthétisées

Parcourir le dossier `wiki/synthesis/` pour identifier les synthèses existantes :
- Analyser leurs sources référencées dans la propriété `sources::` ou leurs wikilinks corporels.
- Retirer ces paires de concepts de la liste des candidats.

## Étape 3 : Évaluer et Classer les Candidats

Pour chaque paire (ou groupe de 3+) restante, calculer un score de valeur de synthèse :

| Signal | Points |
|---|---|
| Co-occurrence sur ≥ 5 pages | +3 |
| Co-occurrence sur 3-4 pages | +2 |
| Co-occurrence sur 1-2 pages | +1 |
| Les concepts sont dans des thématiques différentes (`category::` distinct) | +2 |
| Les concepts partagent des tags mais résident dans des thématiques différentes | +1 |
| Un des concepts (ou les deux) est identifié comme hub structurel | +1 |
| La synthèse permet d'élucider une contradiction ou un doute signalé (`^[ambiguous]`) | +2 |

Sélectionner les 5 meilleurs candidats. Si l'utilisateur a spécifié un thème particulier ("synthétise la partie observabilité"), filtrer d'abord les candidats reliés à ce domaine.

## Étape 4 : Rédiger les Pages de Synthèse

Pour chaque candidat retenu, créer une page dans le dossier `wiki/synthesis/` en respectant strictement le format Logseq sans frontmatter YAML :

```markdown
title:: Concept A × Concept B
category:: synthesis
tags:: tag-partage, tag-domaine
sources:: [[wiki/categorie/page-A]], [[wiki/categorie/page-B]]
created:: YYYY-MM-DD
updated:: YYYY-MM-DD
summary:: Synthèse croisée de l'interaction entre Concept A et Concept B, avec implications pour le domaine.
provenance:: extracted: 0.20, inferred: 0.70, ambiguous: 0.10
base_confidence:: 0.65
lifecycle:: draft
lifecycle_changed:: YYYY-MM-DD

# Concept A × Concept B

## La Connexion
- *Ce qui rend la mise en relation de ces deux concepts pertinente — le lien non évident que les pages individuelles n'explicitent pas.*

## Contexte de Co-occurrence
- *Les pages et situations où les deux concepts apparaissent simultanément dans le wiki.*

## Vision Transversale
- *La conclusion ou le principe qui émerge de la confrontation des deux concepts. C'est le cœur de la page — l'apport sémantique inédit que les pages sources ne mentionnent pas.*

## Tensions et Arbitrages
- *Les contradictions ou compromis induits par ces concepts. Là où l'application de l'un nuit à l'autre.*

## Questions Ouvertes
- *Ce que cette synthèse fait émerger comme zone d'ombre ou axe de recherche future pour le wiki.*

## Liens
- [[wiki/concepts/concept-A]]
- [[wiki/concepts/concept-B]]
- [[wiki/synthesis/_index]]
```

**Règles de rédaction des synthèses :**
- **Le format de titre utilise le signe de multiplication `×`** (ex: `title:: Concept A × Concept B`), ce qui indique immédiatement au lecteur qu'il s'agit d'une page de synthèse transversale.
- **La provenance est majoritairement `^[inferred]`** : vous formulez des déductions et des ponts conceptuels — c'est le propre d'un travail de synthèse. Utilisez `^[inferred]` pour les conclusions transversales et `^[ambiguous]` là où les sources originales se contredisent.

## Étape 5 : Lier depuis les Pages Sources

Pour chaque synthèse créée, ajouter un wikilink réciproque sur les pages des concepts sources. Sur les pages conceptuelles concernées, insérer dans la section `## Liens` :

```markdown
- [[wiki/synthesis/concept-A___concept-B]] — synthèse
```

*(Rappel : Logseq utilise le convertisseur de caractères spéciaux `:triple-lowbar` pour stocker les noms de fichiers contenant des caractères spéciaux ou des sous-niveaux).*

## Étape 6 : Rapporter les Opportunités Non Retenues

Après avoir créé les pages pour les 5 meilleurs candidats, listez dans votre rapport final les 10 candidats suivants les mieux notés. Cela donne de la visibilité sur les axes futurs de développement du wiki sans le surcharger d'un coup.

Format :
```markdown
### Prochaines opportunités de synthèse (à envisager) :
- [[wiki/concepts/caching]] × [[wiki/concepts/consistency]] — co-occurrence sur 4 pages, trans-domaine
- [[wiki/concepts/testing]] × [[wiki/concepts/observability]] — co-occurrence sur 3 pages, tags partagés
```

## Étape 7 : Mettre à jour les Fichiers Spéciaux

**`wiki/_master-index.md`** — Ajouter les entrées pour toutes les nouvelles pages de synthèse.

**`wiki/_log.md`** — Ajouter une ligne :
```markdown
- [TIMESTAMP] SYNTHESIZE pages_scanned=N synthesis_created=M candidates_skipped=K
```

**`wiki/hot.md`** — Mettre à jour **Activité Récente** avec les synthèses réalisées (ex: "Synthèse de 5 pages croisées : Concept A × Concept B, ..."). Ajouter les questions ouvertes soulevées par les synthèses dans **Active Threads**. Mettre à jour la date `updated::`.

## Liste de Contrôle Qualité

- [ ] Chaque page de synthèse possède un résumé sémantique `summary::` (≤200 caractères)
- [ ] Chaque page de synthèse pointe vers ses concepts sources d'origine
- [ ] Les pages de concepts sources pointent en retour vers la page de synthèse
- [ ] La page de synthèse apporte une idée transversale inédite et ne se contente pas de redire ce que disent les sources
- [ ] Les fichiers `_master-index.md`, `_log.md` et `hot.md` sont à jour
