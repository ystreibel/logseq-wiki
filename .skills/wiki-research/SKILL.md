---
name: wiki-research
description: >
  Recherche autonome multi-round sur un sujet via le web, synthèse des résultats, et dépôt
  dans le wiki Logseq sous forme de pages structurées. Déclencher quand l'utilisateur dit
  "/wiki-research [sujet]", "recherche X", "trouve tout sur Y", "deep dive sur Z", ou veut
  une connaissance web complète sur un sujet déposée directement dans son wiki.
---

# Wiki Research — Recherche Autonome Multi-Round

Tu exécutes une boucle de recherche autonome sur un sujet, synthétises ce que tu trouves,
et déposes les résultats dans le wiki Logseq comme connaissance permanente.

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local, premier trouvé) → `LOGSEQ_VAULT_PATH`
2. Lire `$LOGSEQ_VAULT_PATH/wiki/_master-index.md` pour comprendre ce qui est déjà dans
   le wiki — ne pas re-rechercher des sujets bien couverts
3. Lire `$LOGSEQ_VAULT_PATH/wiki/_log.md` (hot context) si disponible

Confirmer le sujet de recherche avec l'utilisateur s'il est ambigu. Puis procéder.

## Configuration de recherche (optionnelle)

Si `$LOGSEQ_VAULT_PATH/wiki/_meta/research-config.md` existe, le lire et appliquer :
- Préférences de sources (ex: préférer académique, éviter certains domaines)
- Domaines à ignorer
- Ajustements de scoring de confiance
- Contraintes spécifiques au sujet

## Round 1 — Survey Large

**Objectif :** Cartographier le sujet.

1. Décomposer le sujet en **3-5 angles distincts**
2. Pour chaque angle, lancer **2-3 requêtes WebSearch** avec des formulations variées
3. Pour les 2-3 meilleurs résultats par angle, fetcher le contenu
4. De chaque page fetchée, extraire :
   - **Claims clés** — ce que la source dit explicitement
   - **Concepts** — idées, termes, frameworks introduits
   - **Entités** — outils, personnes, organisations mentionnés
   - **Contradictions** — là où les sources se contredisent

Suivre ce qui est couvert et ce qui manque au fur et à mesure.

## Round 2 — Combler les lacunes

**Objectif :** Fermer les trous du Round 1.

Relire ce que le Round 1 a produit :
- Quelles questions les sources ont-elles soulevées sans répondre ?
- Où les sources se contredisent-elles ?
- Quels angles ont été peu couverts ?

Lancer **jusqu'à 5 recherches ciblées** sur ces lacunes. Préférer les sources primaires,
la documentation officielle, les analyses de référence.

Mettre à jour le working set. Mettre à jour la liste de contradictions.

## Round 3 — Vérification de la Synthèse

**Objectif :** Résoudre les contradictions ; confirmer que la profondeur est suffisante.

Si des contradictions majeures restent non résolues :
- Lancer une dernière passe ciblée (2-3 recherches)
- Si résolution impossible, signaler la contradiction explicitement dans la page de synthèse

**Condition d'arrêt :** S'arrêter quand la profondeur est atteinte ou après 3 rounds.

## Dépôt — Écrire les pages wiki

Organiser tous les résultats en pages wiki. Utiliser les wikilinks Logseq au format
`[[wiki/thème/page]]`. **Toutes les pages utilisent les propriétés Logseq** (double-colon),
jamais de YAML frontmatter.

### 1. Un thème `/références/` — Une page par source majeure

Pour chaque source significative (typiquement 4-8 pages) :

```
title:: <Titre de la source>
category:: références
tags:: <2-4 tags de domaine>
sources:: <URL>
created:: <timestamp ISO>
updated:: <timestamp ISO>
summary:: <1-2 phrases sur ce que la source couvre, ≤200 chars>
base_confidence:: <score>
lifecycle:: draft
lifecycle_changed:: <date du jour>

# <Titre>

URL: <url>

## Ce que couvre cette source
<description>

## Claims clés
- <claim> [^[extrait]]
- <claim> [^[inféré]]
```

### 2. Un thème pour les concepts — Une page par concept substantiel

Pour chaque concept significatif extrait des sources :

Propriétés Logseq standard + corps. Relier les concepts entre eux et aux pages sources.
Utiliser le namespace dynamique détecté dans le vault (ex: `[[wiki/concepts/nom-concept]]`).

### 3. Un thème pour les entités — Outils, organisations, personnes

Pour chaque entité significative (outils, bibliothèques, entreprises, auteurs clés) :

Propriétés Logseq standard. Relier aux concepts qui utilisent l'entité et aux sources.

### 4. Synthèse — Page maîtresse

La sortie principale : une synthèse structurée de tout ce qui a été trouvé.

```
title:: Recherche : <Sujet>
category:: synthèse
tags:: <3-5 tags de domaine>, research
sources:: <liste des URLs ou chemins de pages>
created:: <timestamp ISO>
updated:: <timestamp ISO>
summary:: Synthèse de recherche [N rounds] sur <sujet>. Couvre <résultats clés en ≤200 chars>.
base_confidence:: <min(N_sources_uniques/3, 1.0)×0.5 + qualité_moyenne×0.5>
lifecycle:: draft
lifecycle_changed:: <date du jour>

# Recherche : <Sujet>

## Vue d'ensemble
<2-4 phrases de résumé exécutif>

## Résultats clés
<Liste des claims les plus importants, chacun avec citation [[page source]]>

## Concepts clés
<Liens vers les pages concepts créées, avec descriptions en une ligne>

## Entités & Outils
<Liens vers les pages entités, avec descriptions en une ligne>

## Contradictions & Questions ouvertes
<Là où les sources divergent ou où la recherche a atteint ses limites>

## Méthode
- Rounds : 3 (ou N si arrêt anticipé)
- Sources consultées : N
- Requêtes lancées : N
```

## Post-dépôt

1. Mettre à jour `wiki/_master-index.md` — ajouter toutes les nouvelles pages
2. Mettre à jour `wiki/_manifest.json` — ajouter chaque URL comme source ingérée
3. Ajouter dans `wiki/_log.md` :
   ```
   - [TIMESTAMP] RESEARCH sujet="<sujet>" rounds=N sources=N pages_créées=N
   ```

## Notes

- Ne pas créer de pages pour des faits triviaux ou largement connus
- Si le wiki couvre déjà bien le sujet, proposer de mettre à jour plutôt que créer
- Garder chaque page de source focalisée — une source = une page, pas un méga-dump
- Les pages concepts et entités doivent être réutilisables — pas liées à un seul research
