---
name: wiki-context-pack
description: >
  Génère un pack de contexte (context pack) de taille limitée en jetons (token-bounded)
  depuis le wiki Logseq. Regroupe les pages les plus pertinentes pour un sujet ou une activité récente,
  prêt à être transmis à un autre agent ou skill.
  Use when the user says "/wiki-context-pack", "génère un pack de contexte", "context slice",
  "contexte de jetons", "contexte compressé".
---

# Logseq Context Pack — Agrégation de Contexte Bounded

Ce skill produit un condensé structuré et limité en jetons du savoir contenu dans le wiki pour nourrir un autre agent, un sous-agent ou une tâche d'implémentation spécifique.

## Avant de commencer

1. **Résoudre la configuration** : Charger `.env` ou `~/.logseq-wiki/config` pour obtenir `LOGSEQ_VAULT_PATH`.
2. Lire `wiki/_master-index.md` pour connaître l'inventaire des pages physiques.
3. Lire `wiki/hot.md` si présent pour le contexte récent.

## Formes d'invocation

```
/wiki-context-pack "concepts/attention-mechanism" --budget 16000
/wiki-context-pack "mon-projet architecture" --budget 8000
/wiki-context-pack --recent --budget 4000
/wiki-context-pack "pattern auth"            # budget par défaut : 8000 tokens
```

Paramètres :
- **topic** : Terme ou page cible à packager.
- **`--budget N`** : Budget maximum en tokens (défaut : 8000, max : 100000).
- **`--recent`** : Packager l'activité récente (pages triées par `updated::` descendant).

## Algorithme de Packaging

### Étape 1 : Calcul de pertinence (léger)
1. Parcourir l'index et les propriétés en tête de fichier pour attribuer un score de pertinence :
   - **+5** : Match exact avec le titre ou un alias.
   - **+3** : Présence du tag recherché.
   - **+2** : Présence du terme dans la propriété `summary::`.
2. En mode `--recent` : Prendre les 20 pages wiki les plus récemment mises à jour (`updated::`).
3. En mode thématique : Sélectionner les 20 meilleures pages selon le score.

### Étape 2 : Filtrage par Tiers (Importance Tiering)
Trier les 20 candidats selon leur score de pertinence, puis par tier (selon `tier::` défini dans `llm-wiki/SKILL.md`) :
1. Pages `tier:: core` en premier.
2. Pages `tier:: supporting` ensuite.
3. Pages `tier:: peripheral` en dernier.

### Étape 3 : Compression du contenu
Pour chaque page sélectionnée, générer sa représentation compressée :
1. **Obligatoire** : titre, `tier::`, `tags::`, `summary::` (très économique, issu des premières lignes).
2. **Si le budget restant le permet** : ajouter le corps de la page dépouillé de :
   - Son bloc de propriétés head (déjà lu ci-dessus).
   - Sa section `## Liens` ou `## Sources` (qui sera résumée sur une ligne).
   - Les puces redondantes avec d'autres pages déjà intégrées.
3. Estimer la taille en tokens : `caractères / 4`.

### Étape 4 : Application du budget
Remplir le pack gloutonnement en suivant l'ordre pertinence/tier :
1. Toujours inclure au moins le titre et le `summary::` de chaque page candidate.
2. Si le corps complet d'une page ne rentre pas dans le budget, inclure uniquement son premier bloc descriptif et sa liste d'idées clés (`Key Ideas`).
3. Arrêter l'ajout dès que la page suivante dépasse le budget. Notez le nombre de pages exclues.

### Étape 5 : Rendu du pack

Émettre un unique bloc markdown :

```markdown
# Context Pack: <topic>
# Generated: <TIMESTAMP>
# Budget: <budget> tokens | Actual: <actual> tokens | Pages: <N incluses> / <M candidates>
# Methodology: 4 chars/token estimate

---

## [[wiki/<category>/<page-name>]] (<tier>, ~<tokens> tokens)
tags:: #tag1, #tag2
summary:: <summary field text>

<corps de page compressé ou extrait>

---

## [[wiki/<category>/<next-page>]] (<tier>, ~<tokens> tokens)
...
```

### Étape 6 : Log

Enregistrer le run dans `wiki/_log.md` :
```
- [TIMESTAMP] CONTEXT_PACK topic="<topic>" budget=<N> actual_tokens=<M> pages_included=<K> pages_dropped=<D>
```

## Cas d'usage

- **Alimenter `/wiki-research`** — passer le pack comme contexte pour éviter de redécouvrir des faits connus
- **Passer à `/wiki-synthesize`** — input ciblé pour une tâche de synthèse spécifique
- **Fournir à des agents externes** — contenu structuré, limité en taille, avec citations
- **Checkpoint avant une longue tâche** — savoir ce que le wiki sait déjà avant de démarrer

## Règles de déduplication

Si deux pages candidates partagent un paragraphe ou une claim quasi-identique, garder l'info uniquement dans la page la plus pertinente. Signaler la suppression : `_(contenu également dans [[wiki/thème/autre-page]])_`.

## Notes

- L'heuristique `4 chars/token` est cohérente avec `wiki-status` (token footprint)
- Le pack est un snapshot non écrit dans le vault — relancer pour actualiser
- Pour les gros budgets (> 50K tokens), avertir : "Ce pack est volumineux. Envisager de cibler le topic ou d'utiliser wiki-query pour une réponse précise."
- Le mode `--recent` est utile pour préparer le contexte de session en début de journée de travail
