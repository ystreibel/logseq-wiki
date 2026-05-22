---
name: wiki-lint
description: >
  Audit et maintenance de la santé du wiki Logseq. Déclencher quand l'utilisateur veut vérifier
  son wiki, trouver des pages orphelines, détecter des contradictions, identifier du contenu
  obsolète, corriger des wikilinks cassés ou faire un audit général de la base de connaissances.
  Se déclenche aussi sur "nettoyer le wiki", "qu'est-ce qui doit être corrigé", "audit mes notes",
  "wiki health check". Ajouter --consolidate pour passer du mode rapport-seul au mode
  act-and-report (le "dream cycle") : corrige les liens cassés, ajoute des cross-références
  manquantes pour les orphelins, corrige les états de cycle de vie, déclasse les pages périphériques
  obsolètes, normalise les alias de tags et ajoute des callouts de contradiction — le tout avec un
  dry-run et confirmation explicite avant toute écriture.
---

# Wiki Lint — Audit de Santé

Tu effectues un audit de santé sur un wiki Logseq. Ton objectif est de trouver et corriger les problèmes structurels qui dégradent la valeur du wiki au fil du temps.

**Avant de scanner quoi que ce soit :** respecte les Primitives de Lecture dans `llm-wiki/SKILL.md`. Préfère les greps ciblés sur les propriétés et les lectures ancrées sur des sections plutôt que des lectures complètes de pages. Sur un vault volumineux, lire aveuglément toutes les pages pour les auditer est exactement ce que ce framework est conçu à éviter.

## Avant de commencer

1. **Résoudre la configuration** — lire `~/.logseq-wiki/config` en premier, sinon `.env` dans le répertoire logseq-wiki. Cela donne `LOGSEQ_VAULT_PATH`.
2. Lire `wiki/_master-index.md` pour l'inventaire complet des pages.
3. Lire `wiki/_log.md` pour le contexte d'activité récente.

## Checks de Lint

Effectuer ces vérifications dans l'ordre. Rapporter les résultats au fil des vérifications.

### 1. Pages orphelines

Trouver les pages sans aucun lien entrant. Ce sont des îlots de connaissance que rien ne relie.

**Comment vérifier :**
- Glob tous les fichiers `.md` dans `$LOGSEQ_VAULT_PATH/wiki/`
- Pour chaque page, Grep le reste du wiki pour des références `[[wiki/thème/page]]`
- Les pages avec zéro lien entrant (sauf `wiki/_master-index.md` et `wiki/_log.md`) sont des orphelines

**Comment corriger :**
- Identifier quelles pages existantes devraient lier vers l'orpheline
- Ajouter des wikilinks dans les sections appropriées

### 2. Liens cassés (Broken Wikilinks)

Trouver les `[[wikilinks]]` pointant vers des pages qui n'existent pas.

**Comment vérifier :**
- Grep `\[\[wiki/.*?\]\]` sur toutes les pages
- Extraire les cibles des liens
- Vérifier si un fichier `.md` correspondant existe

**Comment corriger :**
- Si la cible a été renommée, mettre à jour le lien
- Si la cible devrait exister, la créer
- Si le lien est incorrect, le supprimer ou le corriger

### 3. Propriétés Logseq obligatoires

Chaque page wiki doit avoir : `title::`, `category::`, `tags::`, `sources::`, `created::`, `updated::`.

**Comment vérifier :**
- Grep les blocs de propriétés en tête de fichier (en cherchant `^title::`, `^category::`, etc.) plutôt que lire chaque page en entier
- Signaler les pages manquant des champs requis

**Comment corriger :**
- Ajouter les champs manquants avec des valeurs raisonnables par défaut

### 3a. Résumé manquant (soft warning)

Chaque page *devrait* avoir un champ `summary::` — 1-2 phrases, ≤200 chars. C'est ce que la récupération rapide (ex. le mode index-only de `wiki-query`) lit pour éviter d'ouvrir le corps des pages.

**Comment vérifier :**
- Grep les propriétés pour `^summary::` sur tout le wiki
- Signaler les pages sans ce champ, **mais comme un soft warning, pas une erreur** — les anciennes pages antérieures à ce champ sont correctes ; le check existe pour inciter les skills d'ingest à le remplir sur les nouvelles écritures.
- Signaler aussi les pages dont le résumé dépasse 200 chars.

**Comment corriger :**
- Réingérer la page, ou écrire manuellement un court résumé (1-2 phrases du contenu de la page).

### 4. Contenu obsolète (Stale Content)

Pages dont le timestamp `updated::` est ancien par rapport à leurs sources.

**Comment vérifier :**
- Comparer les timestamps `updated::` des pages aux dates de modification des fichiers sources
- Signaler les pages dont les sources ont été modifiées après la dernière mise à jour de la page

### 5. Contradictions

Claims qui entrent en conflit entre des pages.

**Comment vérifier :**
- Cela nécessite de lire les pages liées et de comparer les affirmations
- Se concentrer sur les pages partageant des tags ou fortement cross-référencées
- Chercher des phrases comme "cependant", "en revanche", "malgré" qui peuvent signaler des contradictions déjà reconnues vs. non reconnues

**Comment corriger :**
- Ajouter une section "Questions ouvertes" notant la contradiction
- Référencer les deux sources et leurs affirmations

### 6. Cohérence de l'index

Vérifier que `wiki/_master-index.md` correspond à l'inventaire réel des pages.

**Comment vérifier :**
- Comparer les pages listées dans `wiki/_master-index.md` aux fichiers réels sur disque
- Vérifier que les résumés dans `wiki/_master-index.md` correspondent encore au contenu des pages

### 7. Dérive de Provenance (Provenance Drift)

Vérifier si les pages sont honnêtes sur la proportion de leur contenu inféré vs extrait. Voir la section Provenance Markers dans `llm-wiki` pour la convention.

**Comment vérifier :**
- Pour chaque page avec un bloc `provenance::` ou des marqueurs `^[inferred]`/`^[ambiguous]`, compter les phrases/bullets et combien se terminent par chaque marqueur
- Calculer les fractions approximatives (`extracted`, `inferred`, `ambiguous`)
- Appliquer ces seuils :
  - **AMBIGUOUS > 15%** : signaler comme "speculation-heavy" — même 1 claim sur 7 genuinement incertain est un signal que la page nécessite des sources plus solides ou devrait être déplacée en `wiki/synthesis/`
  - **INFERRED > 40% sans `sources::` dans les propriétés** : signaler comme "unsourced synthesis" — la page fait des connexions mais n'a rien à citer
  - **Pages hub** (top 10 par nombre de liens entrants) avec INFERRED > 20% : signaler comme "high-traffic page with questionable provenance" — les erreurs sur les pages hub se propagent à toutes les pages qui les lient
  - **Drift** : si la page a un champ `provenance::`, la signaler quand un champ s'écarte de plus de 0.20 de la valeur recalculée
- **Passer** les pages sans `provenance::` ni marqueurs — traitées comme entièrement extraites par convention

**Comment corriger :**
- Pour ambiguous-heavy : réingérer depuis les sources, résoudre les claims incertains, ou séparer le contenu spéculatif dans une page `wiki/synthesis/`
- Pour unsourced synthesis : ajouter `sources::` aux propriétés ou étiqueter clairement la page comme synthesis
- Pour les pages hub avec INFERRED > 20% : prioriser pour réingestion — les erreurs ici ont le plus grand blast radius
- Pour le drift : mettre à jour le champ `provenance::` pour correspondre aux valeurs recalculées

### 8. Clusters de Tags fragmentés

Vérifie si les pages partageant un tag sont effectivement liées entre elles. Les tags impliquent un cluster thématique ; si ces pages ne se référencent pas mutuellement, le cluster est fragmenté.

**Comment vérifier :**
- Pour chaque tag apparaissant sur ≥ 5 pages :
  - `n` = nombre de pages avec ce tag
  - `actual_links` = nombre de wikilinks entre deux pages quelconques de ce groupe (vérifier les deux directions)
  - `cohesion = actual_links / (n × (n−1) / 2)`
- Signaler tout groupe de tags avec cohesion < 0.15 et n ≥ 5

**Comment corriger :**
- Lancer le skill `cross-linker` ciblé sur le tag fragmenté — il trouvera et insérera les liens manquants
- Si un groupe de tags est large (n > 15) et toujours fragmenté, envisager de le diviser en sous-tags plus spécifiques

### 9. Cohérence des tags de visibilité

Vérifie que les tags `visibility/` sont appliqués correctement et ne sont pas silencieusement absents là où ils comptent.

**Comment vérifier :**

- **Patterns PII non taggés :** Grep les corps de pages pour des patterns indiquant des données sensibles — lignes contenant `password`, `api_key`, `secret`, `token`, `ssn`, `email:`, `phone:` suivis d'une valeur réelle (pas d'une description de champ). Si une page correspond et n'a pas `visibility/pii` ou `visibility/internal` dans `tags::`, la signaler comme potentiellement mal classifiée.
- **`visibility/pii` sans `sources::`:** Une page avec le tag `visibility/pii` devrait toujours avoir un champ `sources::` — sans provenance, impossible de vérifier la classification. Signaler toute page `visibility/pii` manquant `sources::`.
- **Tags de visibilité dans la taxonomie :** Les tags `visibility/` sont des tags système et ne doivent **pas** apparaître dans `wiki/_meta/taxonomy.md`. Si trouvés, signaler comme mal configuré.

**Comment corriger :**
- Pour les patterns PII non taggés : ajouter `visibility/pii` (ou `visibility/internal` si c'est du contexte d'équipe plutôt que des données personnelles) dans les propriétés `tags::` de la page
- Pour `sources::` manquant : ajouter la provenance ou escalader à l'utilisateur — ne pas auto-remplir
- Pour la contamination de la taxonomie : supprimer les entrées `visibility/` de `wiki/_meta/taxonomy.md`

### 10. Candidats à la promotion depuis misc/

Trouver les pages dans `wiki/misc/` qui ont accumulé suffisamment d'affinité thématique pour être promues.

**Comment vérifier :**
- Glob `$LOGSEQ_VAULT_PATH/wiki/misc/*.md`
- Pour chaque page, lire le champ `affinity::` dans les propriétés
- Signaler les pages où le score d'un projet unique est ≥ 3

**Comment corriger :**
- Lancer le skill `cross-linker` en premier si les scores d'affinité semblent obsolètes (ex. `affinity:: {}` sur une page avec beaucoup de wikilinks)
- Pour promouvoir : déplacer la page vers `wiki/projects/<nom-projet>/references/` (ou une autre catégorie appropriée), mettre à jour sa propriété `category::`, supprimer `promotion_status::`, et grep le vault pour mettre à jour les backlinks

### 11. Gaps de Synthèse

Identifier les opportunités de synthèse à haute valeur que le wiki ne couvre pas — des paires de concepts co-occurrents sur de nombreuses pages mais sans page `wiki/synthesis/` les reliant.

**Comment vérifier :**
- Lister toutes les pages dans `wiki/synthesis/` — collecter les paires de concepts que chacune couvre déjà (depuis ses `[[wikilinks]]` ou son titre)
- Sélectionner 10-15 concepts fréquemment liés depuis les autres thèmes
- Pour chaque paire, lancer un grep rapide pour compter les pages liant les deux :
  ```bash
  grep -rl "\[\[wiki/theme/ConceptA\]\]" "$LOGSEQ_VAULT_PATH/wiki" --include="*.md" > /tmp/a.txt
  grep -rl "\[\[wiki/theme/ConceptB\]\]" "$LOGSEQ_VAULT_PATH/wiki" --include="*.md" > /tmp/b.txt
  comm -12 <(sort /tmp/a.txt) <(sort /tmp/b.txt) | wc -l
  ```
- Signaler les paires avec co-occurrence ≥ 3 sans page de synthèse existante

**Comment corriger :**
- Lancer `/wiki-synthesize` pour découvrir automatiquement et combler les principales lacunes

### 12. Confiance et Cycle de Vie (Lifecycle Schema)

Enforces the confidence + lifecycle frontmatter schema (voir la section Confidence and Lifecycle dans `llm-wiki/SKILL.md`).

Deux modes :
- **`--check`** (défaut, lecture seule) — rapporte les erreurs et avertissements
- **`--fix`** — peut réécrire `base_confidence::` uniquement si un drift est détecté (Règle 12e) ; ne réécrit jamais `lifecycle::`

#### Règle 12a — Validation enum `lifecycle::`

**Comment vérifier :** Grep les propriétés pour `^lifecycle::` sur toutes les pages. Signaler toute valeur absente de `{draft, reviewed, verified, disputed, archived}`.

**Comment corriger :** n/a (seul un humain doit définir l'état de lifecycle)

#### Règle 12b — Plage de `base_confidence::`

**Comment vérifier :** Grep les propriétés pour `^base_confidence::` sur toutes les pages. Signaler toute valeur hors de `[0.0, 1.0]` ou toute page manquant le champ.

**Comment corriger :** n/a (valeur incorrecte signifie que le skill l'a mal calculée — remonter pour correction manuelle)

#### Règle 12c — Rapport de pages obsolètes (computed overlay)

L'obsolescence n'est jamais stockée — elle est calculée à la lecture : `is_stale = (aujourd'hui − updated) > 90 jours`.

**Comment vérifier :** Pour chaque page, lire `updated::` dans les propriétés et calculer `is_stale`. Si obsolète, vérifier aussi `lifecycle::`. Rapporter :
- Pages obsolètes avec `lifecycle:: verified` avec une annotation plus forte (ce sont les plus dangereuses — pages haute-confiance qui peuvent être incorrectes)
- Toutes les autres pages obsolètes comme avertissement standard

**Comment corriger :** `--fix` ne réécrit **pas** `lifecycle::`. L'obsolescence se résorbe automatiquement quand une réingestion met à jour `updated::`.

#### Règle 12d — Intégrité de supersession

**Comment vérifier :** Pour chaque page avec `superseded_by:: [[wiki/thème/page]]` :
- Vérifier que la page cible existe
- Vérifier que la page cible n'est pas elle-même `archived` (pas de supersession circulaire ou en chaîne)
- Vérifier l'absence de cycles (A supersède B qui supersède A)
- Avertir si `lifecycle::` ≠ `archived` alors que `superseded_by::` est défini (état incohérent)

**Comment corriger :** n/a — signaler pour résolution humaine

#### Règle 12e — Drift de confiance

**Comment vérifier :** Pour les pages ayant à la fois `base_confidence::` et `sources::` dans les propriétés, recalculer `base_confidence::` à l'aide de la formule dans `llm-wiki/SKILL.md`. Si la valeur stockée diffère de la valeur recalculée de plus de 0.05, signaler comme drift.

**Comment corriger (`--fix` uniquement) :** Réécrire le champ `base_confidence::` à la valeur recalculée. C'est la **seule règle** qui modifie les propriétés automatiquement.

#### Timeline de migration

| Phase | Quand | Comportement sur champs manquants |
|---|---|---|
| Phase 1 : Soft launch | PR initial | Warning seulement — `base_confidence::` ou `lifecycle::` manquant sur une page |
| Phase 2 : Nouvelles pages enforced | +2 semaines | Erreur pour les nouvelles pages créées sans ces champs ; les pages existantes avertissent encore même si `updated::` est mis à jour lors de maintenance |
| Phase 3 : Enforcement complet | +6 semaines, conditionné à un backfill dans un PR séparé | Erreur pour toutes les pages |

#### Ajouts à l'output

Ajouter au Wiki Health Report :

```markdown
### Problèmes Confiance/Cycle de Vie (N trouvés)
- `wiki/concepts/foo.md` — champ `lifecycle::` manquant (warning : Phase 1)
- `wiki/entities/bar.md` — `lifecycle:: stalestate` n'est pas une valeur enum valide
- `wiki/concepts/scaling.md` — `base_confidence:: 1.4` hors plage [0.0, 1.0]
- `wiki/synthesis/old-analysis.md` — OBSOLÈTE (dernière mise à jour 2025-10-01, 182 jours) lifecycle=verified ⚠️ PRIORITÉ HAUTE
- `wiki/concepts/outdated.md` — OBSOLÈTE (dernière mise à jour 2025-11-15, 137 jours) lifecycle=draft
- `wiki/entities/tool-v1.md` — `superseded_by:: [[wiki/entities/tool-v2]]` mais lifecycle=draft (attendu archived)
- `wiki/concepts/drift-example.md` — drift base_confidence : stocké=0.80, recalculé=0.59 (delta=0.21)
```

Ajouter à l'entrée de log `LINT` :
```
- [TIMESTAMP] LINT ... lifecycle_issues=N
```

### 13. Validité des Relations Typées

Valider les champs `relationships::` dans les propriétés. Passer les pages sans ce champ — il est optionnel.

**Types autorisés :** `extends`, `implements`, `contradicts`, `derived_from`, `uses`, `replaces`, `related_to`

**Comment vérifier :**
- Grep les propriétés pour `^relationships::` sur toutes les pages du wiki
- Pour chaque page ayant un champ `relationships::`, lire ses propriétés (pas le corps entier)
- Pour chaque entrée dans le champ :
  1. **Validation du type** — signaler toute valeur `type:` absente de l'ensemble autorisé ci-dessus
  2. **Cible cassée** — retirer `[[` et `]]` de la chaîne `target:`, normaliser (minuscules, espaces→tirets, retirer `.md`), et vérifier si un fichier `.md` à ce chemin existe dans le wiki. Signaler les cibles non résolues.
  3. **Auto-référence** — signaler toute entrée où la cible résolue correspond au node id de la page elle-même

**Comment corriger :**
- Type invalide : corriger la valeur vers le type autorisé le plus proche, ou utiliser `related_to` si le type est ambigu
- Cible cassée : mettre à jour ou supprimer l'entrée ; si la page cible devrait exister, la créer d'abord
- Auto-référence : supprimer l'entrée

**Ajouts à l'output :**

```markdown
### Problèmes de Relations Typées (N trouvés)
- `wiki/concepts/foo.md` — relationships[1] : type "contradication" n'est pas un type autorisé (vouliez-vous dire "contradicts" ?)
- `wiki/concepts/bar.md` — relationships[0] : cible "[[wiki/skills/nonexistent-skill]]" ne correspond à aucune page du wiki
- `wiki/entities/baz.md` — relationships[2] : auto-référence (la cible correspond au node id de cette page)
```

Ajouter à l'entrée de log `LINT` :
```
... relationship_issues=N
```

---

## Format de sortie

Rapporter les résultats sous forme de liste structurée :

```markdown
## Wiki Health Report

### Pages Orphelines (N trouvées)
- `wiki/concepts/foo.md` — aucun lien entrant

### Liens Cassés (N trouvés)
- `wiki/entities/bar.md:15` — lien vers [[wiki/concepts/nonexistent-page]]

### Propriétés Logseq Manquantes (N trouvées)
- `wiki/skills/baz.md` — manquants : tags::, sources::

### Résumés Manquants (N trouvés — soft)
- `wiki/concepts/foo.md` — pas de champ `summary::`
- `wiki/entities/bar.md` — résumé dépasse 200 chars

### Contenu Obsolète (N trouvé)
- `wiki/references/paper-x.md` — source modifiée 2024-03-10, page mise à jour 2024-01-05

### Contradictions (N trouvées)
- `wiki/concepts/scaling.md` affirme "X" mais `wiki/synthesis/efficiency.md` affirme "pas X"

### Problèmes d'Index (N trouvés)
- `wiki/concepts/new-page.md` existe sur disque mais pas dans wiki/_master-index.md

### Problèmes de Provenance (N trouvés)
- `wiki/concepts/scaling.md` — AMBIGUOUS > 15% : 22% des claims sont ambigus (re-sourcer ou déplacer en synthesis/)
- `wiki/entities/some-tool.md` — drift : frontmatter dit inferred=0.10, recalculé=0.45
- `wiki/concepts/transformers.md` — page hub (31 liens entrants) avec INFERRED=28% : erreurs ici se propagent largement
- `wiki/synthesis/speculation.md` — unsourced synthesis : pas de champ `sources::`, 55% inféré

### Clusters de Tags Fragmentés (N trouvés)
- **#systems** — 7 pages, cohesion=0.06 ⚠️ — lancer cross-linker sur ce tag
- **#databases** — 5 pages, cohesion=0.10 ⚠️

### Problèmes de Visibilité (N trouvés)
- `wiki/entities/user-records.md` — contient un pattern `email:` mais pas de tag `visibility/pii`
- `wiki/concepts/auth-flow.md` — tagué `visibility/pii` mais `sources::` manquant
- `wiki/_meta/taxonomy.md` — contient l'entrée `visibility/internal` (tag système ne doit pas être dans la taxonomie)

### Candidats à la Promotion depuis misc/ (N trouvés)
Pages dans wiki/misc/ ayant ≥ 3 connexions avec un seul projet et prêtes à être promues :

| Page | Projet Principal | Score d'Affinité |
|---|---|---|
| `wiki/misc/web-martinfowler-articles-microservices.md` | `logseq-wiki` | 4 |

### Problèmes Confiance/Cycle de Vie (N trouvés)
- `wiki/concepts/foo.md` — champ `lifecycle::` manquant (warning : Phase 1)
- `wiki/synthesis/old-analysis.md` — OBSOLÈTE (182 jours) lifecycle=verified ⚠️ PRIORITÉ HAUTE

### Problèmes de Relations Typées (N trouvés)
- `wiki/concepts/foo.md` — relationships[1] : type "contradication" n'est pas un type autorisé
- `wiki/concepts/bar.md` — relationships[0] : cible "[[wiki/skills/nonexistent]]" ne correspond à aucune page

### Gaps de Synthèse (N trouvés)
Paires de concepts co-occurrentes sans page de synthèse :

| Paire | Co-occurrence | Action suggérée |
|---|---|---|
| [[wiki/concepts/caching]] × [[wiki/concepts/consistency]] | 5 pages | Lancer `/wiki-synthesize` |
| [[wiki/concepts/testing]] × [[wiki/concepts/observability]] | 3 pages | Lancer `/wiki-synthesize` |
```

## Après le Lint

Ajouter à `wiki/_log.md` :
```
- [TIMESTAMP] LINT issues_found=N orphans=X broken_links=Y stale=Z contradictions=W prov_issues=P missing_summary=S fragmented_clusters=F visibility_issues=V promotion_candidates=C synthesis_gaps=G lifecycle_issues=L relationship_issues=R
```

Proposer de corriger les problèmes automatiquement ou laisser l'utilisateur décider lesquels traiter.

---

## Mode Consolidation (`--consolidate`)

Déclenché par `wiki-lint --consolidate`. Passe du mode rapport-seul au mode **act-and-report** — le "dream cycle" qui tourne périodiquement pour que le wiki s'auto-guérisse.

### Protocole de sécurité

**Toujours lancer en dry-run d'abord.** Avant toute écriture :

1. Lancer tous les checks de lint (Étapes 1–13 ci-dessus).
2. Afficher les actions de consolidation planifiées sous forme de liste structurée (voir Dry-Run Output ci-dessous).
3. Demander à l'utilisateur : `"Appliquer ces N modifications ? [oui / non / sélection par numéro]"`.
4. Ne procéder aux écritures qu'après confirmation explicite. Si l'utilisateur sélectionne des actions individuelles, n'appliquer que celles-là.
5. Ne jamais fusionner des pages — utiliser `wiki-dedup` pour ça. Seulement lier, promouvoir, déclasser et signaler.

### Actions de consolidation (dans l'ordre, après confirmation)

#### Action 1 : Corriger les liens cassés

Pour chaque `[[wiki/thème/page]]` cassé trouvé dans le Check 2 :
- Chercher dans le wiki une page dont le titre ou le nom de fichier est la correspondance floue la plus proche (grep sur les titres `title::` dans `wiki/_master-index.md`)
- Si une meilleure correspondance unique existe (distance d'édition ≤ 2 caractères ou même mot racine) : réécrire le lien. Noter la réécriture : `[[wiki/old/original]] → [[wiki/correct/target]]`.
- Si aucune correspondance ou ambiguïté : convertir en texte brut (`~~[[wiki/thème/inconnu]]~~` → `inconnu`) et ajouter un commentaire `<!-- broken link: no match found -->`.
- Ne jamais créer une nouvelle page juste pour satisfaire un lien cassé.

#### Action 2 : Ajouter des cross-références manquantes pour les orphelins

Pour chaque page orpheline trouvée dans le Check 1 (zéro lien entrant) :
- Grep le texte des pages du wiki pour des mentions du titre ou des alias de la page (insensible à la casse).
- Pour chaque mention trouvée dans une autre page, ajouter un `[[wiki/thème/wikilink]]` remplaçant la mention en texte brut.
- Limiter à 3 insertions par orpheline — ne pas inonder les pages de liens.
- Limité aux orphelines uniquement (différent de `cross-linker` qui tourne sur l'ensemble du wiki).

#### Action 3 : Corriger les états de cycle de vie

Appliquer ces règles automatiquement (elles ne nécessitent pas de jugement humain — elles appliquent la machine d'états documentée) :
- **Promouvoir `draft` → `reviewed` :** pages où `lifecycle:: draft` ET `created::` > 30 jours ET `base_confidence:: > 0.7`. Définir `lifecycle:: reviewed`, `lifecycle_changed:: <aujourd'hui>`, `lifecycle_reason:: "auto-promoted by wiki-lint --consolidate: age>30d, confidence>0.7"`.
- **Déclasser `verified` → `stale` :** PAS une transition d'état — `stale` est un overlay calculé, pas une valeur de lifecycle. À la place : pour les pages verified où `is_stale = (aujourd'hui − updated) > 180 jours`, ajouter un callout en haut du corps de la page : `> ⚠️ **Obsolète** : Cette page a été mise à jour pour la dernière fois le <date>. Vérifier avant de s'y fier.` N'ajouter que si le callout n'est pas déjà présent.
- **Ne pas changer `reviewed` → `verified` ni aucune autre transition** — celles-là sont réservées aux humains.

#### Action 4 : Déclassement de tier

Pour les pages avec `tier:: supporting` (ou sans tier) ayant 0 lien entrant ET non mises à jour depuis 90+ jours :
- Définir `tier:: peripheral`.
- Émettre une liste des déclassements pour révision par l'utilisateur.
- Ne jamais déclasser les pages `tier:: core` automatiquement — elles ont été définies manuellement.

#### Action 5 : Normalisation des tags

Lire `wiki/_meta/taxonomy.md` pour le mapping d'alias (ex. `ml → machine-learning`). Pour chaque page, remplacer les tags alias connus par leur forme canonique dans le champ `tags::`. C'est un sous-ensemble du travail de `tag-taxonomy` — uniquement les corrections d'alias, pas d'audit complet.

#### Action 6 : Callouts de contradiction

Pour chaque paire de pages signalées comme se contredisant (via `relationships:: contradicts` dans les propriétés, ou signalées dans le Check 5) :
- Vérifier si un callout `> ⚠️ Contradiction signalée avec [[wiki/thème/autre-page]]` existe déjà près du claim concerné.
- Si non, l'ajouter en fin de la section "Idées clés" (ou avant "Questions ouvertes" s'il n'y a pas de section "Idées clés"). Rester concis — une ligne.
- Ne pas résoudre la contradiction ; seulement la signaler visuellement.

### Action 7 : Écrire le rapport de consolidation

Après toutes les actions, écrire un rapport dans `wiki/meta/consolidation-<YYYY-MM-DD>.md` :

```
title:: Rapport de Consolidation YYYY-MM-DD
category:: meta
tags:: maintenance, consolidation
sources:: []
summary:: Rapport d'auto-guérison généré par wiki-lint --consolidate le YYYY-MM-DD.
lifecycle:: draft
lifecycle_changed:: YYYY-MM-DD
tier:: peripheral
created:: YYYY-MM-DDTHH:MM:SSZ
updated:: YYYY-MM-DDTHH:MM:SSZ

# Rapport de Consolidation — YYYY-MM-DD

## Résumé
- Liens cassés corrigés : N
- Cross-références ajoutées : M
- États de cycle de vie mis à jour : K
- Déclassements de tier : D
- Tags normalisés : T
- Callouts de contradiction ajoutés : C

## Corrections de Liens Cassés
- `wiki/concepts/foo.md:12` — [[wiki/old/OldTarget]] → [[wiki/correct/correct-target]]
- `wiki/entities/bar.md:8` — [[wiki/missing/Missing]] → `Missing` (aucune correspondance trouvée)

## Cross-Références Ajoutées (sauvetage orphelins)
- `wiki/concepts/baz.md` — maintenant lié depuis : [[wiki/concepts/alpha]], [[wiki/skills/beta]]

## Mises à Jour de Cycle de Vie
- `wiki/concepts/old-draft.md` — draft → reviewed (age 45j, confidence 0.74)
- `wiki/synthesis/stale-verified.md` — callout d'obsolescence ajouté (dernière mise à jour 2025-10-01)

## Déclassements de Tier
- `wiki/concepts/unused-concept.md` — supporting → peripheral (0 liens, 120 jours obsolète)

## Normalisations de Tags
- `wiki/entities/some-tool.md` — `ml` → `machine-learning`

## Callouts de Contradiction
- `wiki/concepts/scaling.md` — contradiction signalée avec [[wiki/synthesis/efficiency]]
```

### Dry-Run Output (affiché avant toute écriture)

```
wiki-lint --consolidate — Dry Run

Actions planifiées (N au total) :
[1] Corriger lien cassé : wiki/concepts/foo.md:12 [[wiki/old/OldTarget]] → [[wiki/correct/correct-target]]
[2] Ajouter cross-ref : wiki/concepts/baz.md ← [[wiki/concepts/alpha]] (sauvetage orphelin)
[3] Lifecycle : wiki/concepts/old-draft.md → reviewed (age 45j, confidence 0.74)
[4] Déclassement tier : wiki/concepts/unused.md → peripheral (0 liens, 112 jours obsolète)
[5] Alias tag : wiki/entities/some-tool.md: ml → machine-learning
[6] Callout contradiction : wiki/concepts/scaling.md ↔ [[wiki/synthesis/efficiency]]

Appliquer ces 6 modifications ? [oui / non / sélection par numéro]
```

### Entrée de log pour le mode consolidate

```
- [TIMESTAMP] LINT_CONSOLIDATE links_fixed=N orphans_rescued=M lifecycle_updates=K tier_demotions=D tag_fixes=T contradiction_callouts=C report=wiki/meta/consolidation-YYYY-MM-DD.md
```
