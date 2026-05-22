---
name: wiki-dedup
description: >
  Scanne le wiki Logseq pour détecter les collisions d'identité au niveau des pages — des pages
  différentes couvrant le même concept sous des noms différents (ex: "RSC" vs "React Server Components")
  — et les fusionne.
  Use when the user says "dedup my wiki", "trouve les doublons", "fusionne les doublons",
  "résolution d'identité", "nettoie le wiki", "j'ai des doublons", "fusionner".
  Distinct de wiki-lint (qui valide la structure) et cross-linker (qui ajoute des liens) — ce skill
  effectue des fusions destructrices de pages et nécessite une confirmation prudente.
---

# Wiki Dedup — Résolution d'Identité et Déduplication de Pages

Ce skill identifie et fusionne les pages du wiki qui traitent du même concept sous des noms différents. Il s'agit d'une opération lourde en écriture et potentiellement destructive (les fusions ne peuvent pas être annulées automatiquement). Travaillez avec précaution et demandez confirmation avant d'agir en mode de fusion.

**Respectez les primitives de lecture de `llm-wiki/SKILL.md`.** La phase de détection des candidats utilise uniquement les propriétés de page et les titres (peu coûteux en jetons). Ne lisez le corps complet des pages que pour les paires de candidats confirmées.

## Avant de commencer

1. **Résoudre la configuration** — suivez le protocole de résolution de configuration dans `llm-wiki/SKILL.md` pour obtenir `LOGSEQ_VAULT_PATH`.
2. Lire `wiki/_master-index.md` pour obtenir l'inventaire complet des pages avec leur résumé et leurs tags.
3. Lire brièvement `wiki/_log.md` — si un run de déduplication vient d'avoir lieu, notez ce qui a déjà été fusionné.

## Modes

| Mode | Option | Comportement |
|---|---|---|
| **Audit** | *(défaut)* | Rapporte uniquement les candidats détectés — aucune écriture |
| **Fusion** | `--merge` | Affiche chaque paire confirmée et demande confirmation avant de fusionner |
| **Auto-fusion** | `--auto` | Fusionne toutes les paires à haute confiance (`score ≥ 0.90`) de manière non interactive |

Si l'utilisateur ne spécifie rien, lancez en mode **Audit** et présentez les résultats avant de demander s'il faut procéder à la fusion.

## Étape 1 : Construire le Registre des Pages

Lister tous les fichiers `.md` dans le dossier `wiki/` (en excluant `_archives/`, `_raw/`, `_staging/`, `_master-index.md`, `_log.md`, `hot.md`, et tout fichier qui contient la propriété `redirects_to::` à son début — ceux-ci sont déjà des stubs de redirection).

Pour chaque page restante, extraire des propriétés de début de fichier :
- `node_id` — chemin relatif depuis la racine du vault, sans `.md` (ex: `wiki/concepts/rsc`)
- `title` — propriété `title::`
- `aliases` — propriété `aliases::` (si présente)
- `tags` — propriété `tags::`
- `category` — dossier thématique parent

Construire une table de correspondance : `node_id → {title, aliases, tags, category, summary}`.

## Étape 2 : Détecter les Paires Candidates

Pour chaque paire de pages du registre, calculer un **score de similitude** en utilisant ces signaux :

### 2a. Signaux de similitude du titre

| Signal | Méthode d'évaluation | Contribution Max |
|---|---|---|
| **Token overlap** | Indice de Jaccard des tokens de mots en minuscules (séparés par des espaces, tirets, underscores, ponctuations) | 0.65 |
| **Distance d'édition** | Distance d'édition normalisée sur les titres en minuscules : `1 - (édits / max(longueur_a, longueur_b))` | 0.40 |
| **Inclusion de sous-chaîne** | Un titre est entièrement contenu dans l'autre (ex: "RSC" ⊂ "React Server Components") | 0.50 |
| **Alias croisé** | Le titre de la page A apparaît dans les `aliases` de la page B, ou inversement | 0.65 |

Score composite du titre = `min(max(token_overlap, edit_distance, substring), 0.65) + bonus_alias_croise`.

Une estimation confiante du degré de similitude suffit, pas besoin d'arithmétique exacte ultra-précise.

### 2b. Signaux sémantiques (rapides)

| Signal | Points |
|---|---|
| Même dossier de thématique (`category::`) | +0.10 |
| Recouvrement des tags ≥ 3 tags partagés | +0.15 |
| Recouvrement des tags ≥ 2 tags partagés | +0.05 |
| Même premier tag (tag dominant) | +0.05 |

### 2c. Seuil de détection

Considérez les paires avec un score composite ≥ **0.75** comme **candidates**. Les paires avec un score ≥ 0.90 sont à **haute confiance**.

Correspondance des scores et confiance :

| Score | Confiance |
|---|---|
| ≥ 0.90 | HAUTE — presque certainement le même concept |
| 0.75–0.89 | MOYENNE — très probablement identique, à vérifier |
| 0.60–0.74 | FAIBLE — spécialisation ou abréviation possible ; ignorer sauf demande explicite |

Ne conservez que les candidats de niveaux HAUT et MOYEN pour l'Étape 3.

### 2d. Règle de sortie rapide

Si le wiki compte moins de 10 pages, sauter la boucle et rapporter : `"Le wiki est trop petit pour contenir des doublons significatifs."` Si le wiki compte plus de 500 pages, traitez les candidats par lots de 50 paires et rapportez la progression entre chaque lot.

## Étape 3 : Verdict Sémantique

Pour chaque paire candidate (triée par score décroissant) :

1. Lire le corps complet des deux pages concernées.
2. Poser la question : ces pages traitent-elles du **même concept**, ou sont-elles distinctes ?

Attribuer l'un des trois verdicts suivants :

| Verdict | Signification |
|---|---|
| `merge` | Même concept — nom différent, abréviation, alias, ou doublon accidentel. Sûr à fusionner. |
| `keep-separate` | Liés mais distincts — ex: "Server Actions" et "Server Components" sont des fonctionnalités React liées, mais pas des doublons. |
| `needs-review` | Ambigu — chevauchement substantiel mais aussi différences notables. À soumettre à l'utilisateur. |

Associer une courte justification (une phrase) à chaque verdict. Celle-ci apparaîtra dans le rapport et le journal.

## Étape 4 : Rapport d'Audit

Générer systématiquement ce rapport, même en mode fusion ou auto-fusion (afin que l'utilisateur voie ce qui va se passer) :

```markdown
## Rapport de Déduplication du Wiki

### Candidats à Haute Confiance (score ≥ 0.90) : N paires

| Score | Page A | Page B | Verdict | Justification |
|---|---|---|---|---|
| 0.95 | `wiki/concepts/rsc.md` | `wiki/concepts/react-server-components.md` | merge | "RSC" est l'abréviation ; les deux pages couvrent le même sujet |
| 0.91 | `wiki/entities/vaswani-2017.md` | `wiki/references/attention-is-all-you-need.md` | keep-separate | L'un est une fiche de chercheur, l'autre une référence de papier |

### Candidats à Moyenne Confiance (score 0.75–0.89) : N paires

| Score | Page A | Page B | Verdict | Justification |
|---|---|---|---|---|
| 0.82 | `wiki/concepts/fine-tuning.md` | `wiki/concepts/finetuning.md` | merge | Même concept, variante d'orthographe (tiret) |

### Nécessite une revue humaine : N paires

| Score | Page A | Page B | Justification |
|---|---|---|---|
| 0.78 | `wiki/concepts/agents.md` | `wiki/concepts/autonomous-agents.md` | Chevauchement important mais "agents" est volontairement plus large |

### Résumé
- Pages scannées : N
- Paires candidates trouvées : M
- Fusions recommandées : X
- Maintenues séparées : Y
- Revues requises : Z
```

En **mode Audit**, s'arrêter ici et demander : `"Exécutez avec l'option --merge pour fusionner de manière interactive les paires recommandées, ou --auto pour fusionner automatiquement toutes les paires à haute confiance."`

## Étape 5 : Fusionner

Pour chaque paire ayant un verdict `merge` (en mode fusion ou auto-fusion) :

En **mode Fusion** : présenter la paire et le verdict sémantique, puis demander : `"Fusionner [Page A] dans [Page B] ? (oui/passer/revue)"`. Ignorer ou sauter si la réponse n'est pas positive.

En **mode Auto-fusion** : ne traiter que les fusions à HAUTE confiance (`score ≥ 0.90`) sans poser de question.

### 5a : Choisir la page canonique (survivante)

Appliquer ces critères de départage dans l'ordre jusqu'à désigner un vainqueur :

1. **Plus de wikilinks entrants** — rechercher dans tout le wiki les références à `[[page]]` ou `[[wiki/...]]` ; la plus référencée l'emporte.
2. **Contenu plus riche** — la page possédant le corps le plus long (nombre de lignes) l'emporte.
3. **Plus de sources** — la liste `sources::` la plus longue l'emporte.
4. **Titre plus long** — le titre le plus descriptif l'emporte (ex: "React Server Components" bat "RSC").
5. **Ordre alphabétique** — le titre arrivant en premier par ordre alphabétique l'emporte.

La page élue est la **survivante**. L'autre page devient la **secondaire** (qui sera fusionnée puis remplacée par un stub de redirection).

### 5b : Fusionner le contenu dans la page canonique

Lire les deux pages et mettre à jour la page canonique :

- **`aliases::`** — ajouter le titre de la page secondaire et tous ses alias (sans doublons).
- **`tags::`** — fusionner les listes de tags (dédupliquer, limiter à 5 tags de domaine + tags système).
- **`sources::`** — fusionner les deux listes de sources (dédupliquer).
- **`relationships::`** — fusionner les relations (dédupliquer par cible, privilégier les relations typées).
- **`base_confidence::`** — recalculer en fonction de l'union des sources et de la formule définie dans `llm-wiki/SKILL.md`.
- **`updated::`** — définir à la date du jour (`YYYY-MM-DD`).
- **`summary::`** — réécrire si la page secondaire couvrait des aspects non résumés dans la page canonique.
- **Corps de page** — fusionner intelligemment les sections uniques et les puces. Ne pas ajouter aveuglément à la fin ; intégrer les informations. Éviter les répétitions d'idées déjà présentes dans la page canonique. Utiliser le marqueur `^[inferred]` là où une synthèse ou déduction est nécessaire.
- **`provenance::`** — recalculer les ratios de provenance après fusion.

### 5c : Rédiger le stub de redirection sur le chemin de la page secondaire

Remplacer tout le contenu de la page secondaire par ce format strict Logseq :

```markdown
title:: <titre page secondaire>
redirects_to:: [[wiki/<chemin/page_canonique>]]
aliases:: [<alias page secondaire>]
category:: <categorie page secondaire>
tags::
created:: <date creation originale page secondaire>
updated:: <date du jour YYYY-MM-DD>

Cette page a été fusionnée dans [[wiki/<chemin/page_canonique>]].
```

La propriété `redirects_to::` signale à tout skill lisant cette page qu'il doit suivre la redirection au lieu de traiter ce fichier comme du contenu réel.

### 5d : Réécrire les wikilinks à l'échelle du wiki

Rechercher dans tout le wiki les liens pointant vers la page secondaire :

- `[[wiki/categorie/slug-secondaire]]` → `[[wiki/categorie/slug-canonique]]`
- `[[wiki/categorie/slug-secondaire|texte]]` → `[[wiki/categorie/slug-canonique|texte]]`
- `[texte]([[wiki/categorie/slug-secondaire]])` → `[texte]([[wiki/categorie/slug-canonique]])`

**Règles de sécurité :**
- Ne jamais réécrire dans les blocs de code (clôturés par ``` ou en code `inline`).
- Ne jamais réécrire à l'intérieur du stub de redirection lui-même (c'est le seul endroit où l'ancien slug doit rester).
- Ne jamais utiliser de commandes shell destructives (`rm`) — utilisez uniquement les outils d'édition/écriture d'Antigravity.
- Réécrire fichier par fichier, en validant chaque modification avant de continuer.

### 5e : Mettre à jour les fichiers de suivi

**`wiki/_master-index.md`** — Supprimer l'entrée de la page secondaire. Mettre à jour le résumé de la page canonique.
**`wiki/[thème]/_index.md`** — Effectuer les mêmes mises à jour au niveau de l'index thématique.
**`wiki/_manifest.json`** — Pour les sources associées à la page secondaire : ajouter `"merged_into": "wiki/[thème]/[page_canonique]"` ou mettre à jour la liste des pages générées.
**`wiki/hot.md`** — Ajouter à l'activité récente : `"Fusion de N paires de doublons ; pages canoniques mises à jour."`

### 5f : Vérification finale

Une fois toutes les fusions effectuées, recherchez s'il reste des références à `[[wiki/categorie/slug-secondaire]]` dans les fichiers autres que les stubs. Si c'est le cas, rapportez-les (il se peut qu'un format de lien non standard ait été manqué).

## Étape 6 : Journaliser (Log)

Ajouter une ligne dans `wiki/_log.md` :
```markdown
- [TIMESTAMP] DEDUP mode=audit|merge|auto-merge pages_scanned=N pairs_found=M merged=X kept_separate=Y needs_review=Z wikilinks_rewritten=W
```

## Gestion des stubs de redirection par les autres skills

Les autres skills doivent traiter les stubs de redirection comme suit :

- **`wiki-export`** — ignorer les pages contenant la propriété `redirects_to::`.
- **`wiki-query`** — si une recherche correspond à un stub, suivre `redirects_to::` pour renvoyer le contenu de la page canonique.
- **`wiki-lint`** — valider que chaque lien `redirects_to::` résout vers une page existante et non un stub (les redirections en chaîne — stub pointant vers stub — sont des erreurs).
- **`cross-linker`** — traiter les stubs comme des cibles interdites ; ne jamais ajouter un nouveau `[[wikilink]]` pointant vers une page stub.
