---
name: graph-colorize
description: >
  Coloriser la vue graphe de Logseq via custom.css. Déclencher quand l'utilisateur dit
  "colorie mon graphe", "coloriser le graphe logseq", "distinguer les thèmes dans le graphe",
  "couleurs par tag", "rendre le graphe coloré", ou veut que les nœuds de la vue graphe
  Logseq soient colorés par tag, thème ou visibilité.
---

# Graph Colorize — Coloriser la Vue Graphe Logseq

> **Note Logseq vs Obsidian :** Logseq ne supporte pas les `colorGroups` JSON comme Obsidian.
> La colorisation du graphe Logseq se fait via **`logseq/custom.css`** en ciblant les nœuds
> SVG du graphe avec des sélecteurs CSS. Les capacités sont limitées comparé à Obsidian —
> la colorisation par tag nécessite du CSS avancé et est sujette à casser lors des mises
> à jour de Logseq.

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local) → `LOGSEQ_VAULT_PATH`
2. Vérifier que `$LOGSEQ_VAULT_PATH/logseq/` existe. Si non, demander à l'utilisateur
   d'ouvrir le vault dans Logseq d'abord.
3. **Avertir l'utilisateur si Logseq est probablement ouvert** : Logseq peut écraser
   `custom.css` au redémarrage. Fermer Logseq avant de continuer.

## Étape 1 : Sauvegarder l'existant

```bash
cp "$LOGSEQ_VAULT_PATH/logseq/custom.css" \
   "$LOGSEQ_VAULT_PATH/logseq/custom.css.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
```

## Étape 2 : Choisir un mode

Inférer le mode depuis la formulation de l'utilisateur. Défaut : **by-tag**.

| Intention utilisateur | Mode |
|---|---|
| "colorie par tag", "colorie mon graphe" (défaut) | `by-tag` |
| "couleur par thème", "colorie par dossier" | `by-theme` |
| "mettre en évidence la visibilité", "montrer internal/pii" | `by-visibility` |
| Mapping explicite fourni | `custom` |

## Étape 3 : Construire le CSS

### Palette (10 couleurs distinctes, accessibles aux daltoniens)

| # | Hex | Rôle |
|---|---|---|
| 0 | `#4E79A7` | bleu |
| 1 | `#F28E2B` | orange |
| 2 | `#E15759` | rouge |
| 3 | `#76B7B2` | teal |
| 4 | `#59A14F` | vert |
| 5 | `#EDC948` | jaune |
| 6 | `#B07AA1` | violet |
| 7 | `#FF9DA7` | rose |
| 8 | `#9C755F` | brun |
| 9 | `#BAB0AC` | gris |

### Mode : `by-tag`

1. Lister tous les `.md` sous `$LOGSEQ_VAULT_PATH/wiki/` (exclure `_archive/`, `_meta/`)
2. Pour chaque page, extraire la ligne `tags:: <valeurs>` et parser les tags (séparés par `,`)
3. Compter la fréquence de chaque tag ; trier décroissant ; prendre le top 10
4. Générer le CSS :

```css
/* logseq-wiki graph colorize — by-tag — généré le YYYY-MM-DD */
/* AVERTISSEMENT : Le ciblage CSS du graphe Logseq peut changer entre versions */

/* Logseq graph nodes : les cercles SVG portent un attribut data-page-title ou
   sont identifiables via le texte du label adjacent — la colorisation exacte
   dépend de la version Logseq. Le CSS ci-dessous cible les nœuds via leurs
   labels texte en utilisant :has() quand disponible. */

/* Méthode alternative recommandée : utiliser les namespaces Logseq.
   Les pages du wiki Logseq utilisent [[wiki/thème/page]] — coloriser par
   premier composant du namespace. */

/* Couleurs par namespace (thème wiki) */
.graph-page-node[data-title^="wiki/concepts"] circle { fill: #4E79A7 !important; }
.graph-page-node[data-title^="wiki/entités"] circle { fill: #F28E2B !important; }
.graph-page-node[data-title^="wiki/skills"] circle { fill: #59A14F !important; }
.graph-page-node[data-title^="wiki/synthèse"] circle { fill: #B07AA1 !important; }
.graph-page-node[data-title^="wiki/références"] circle { fill: #76B7B2 !important; }
.graph-page-node[data-title^="wiki/journal"] circle { fill: #9C755F !important; }
.graph-page-node[data-title^="wiki/projets"] circle { fill: #EDC948 !important; }

/* Pages source Logseq (hors wiki/) */
.graph-page-node:not([data-title^="wiki/"]) circle { fill: #BAB0AC !important; opacity: 0.6; }
```

### Mode : `by-visibility`

```css
/* Colorisation par visibilité — nécessite que les pages portent visibility/pii etc. */
/* Note: Logseq ne peut pas filtrer par tag dans le graphe nativement via CSS */
/* Cette approche colorie par préfixe de titre uniquement */

/* Pages PII — rouge discret */
.graph-page-node[data-title*="pii"] circle,
.graph-page-node[data-title*="privé"] circle { fill: #E15759 !important; opacity: 0.7; }

/* Pages internes */
.graph-page-node[data-title*="internal"] circle { fill: #F28E2B !important; opacity: 0.7; }
```

### Mode : `by-theme` (namespace-based)

Identique à `by-tag` mais grouper par namespace Logseq (premier composant après `wiki/`).
Lister tous les thèmes uniques depuis `$LOGSEQ_VAULT_PATH/wiki/` et assigner une couleur
à chacun.

## Étape 4 : Fusionner dans custom.css

1. Lire `$LOGSEQ_VAULT_PATH/logseq/custom.css` (peut être vide)
2. Supprimer le bloc précédent entre `/* logseq-wiki graph colorize` et le prochain
   bloc de même signature (s'il existe)
3. Ajouter le nouveau CSS généré à la fin du fichier

## Étape 5 : Informer l'utilisateur

```
✅ CSS de colorisation du graphe écrit dans logseq/custom.css

Mode : by-tag (namespace)
Thèmes colorés :
  wiki/concepts   → bleu    (#4E79A7)
  wiki/entités    → orange  (#F28E2B)
  wiki/skills     → vert    (#59A14F)
  wiki/synthèse   → violet  (#B07AA1)
  wiki/références → teal    (#76B7B2)
  wiki/journal    → brun    (#9C755F)
  wiki/projets    → jaune   (#EDC948)
  autres pages    → gris    (#BAB0AC)

⚠️  Limitations Logseq :
  - Les sélecteurs CSS du graphe dépendent de la version de Logseq
  - Tester dans la vue graphe après rechargement (Ctrl+Shift+R)
  - En cas de régression visuelle, restaurer depuis la sauvegarde :
    logseq/custom.css.bak.<timestamp>
```

## Notes

- Logseq utilise un rendu SVG/Canvas pour le graphe — les sélecteurs peuvent varier
  selon les versions. Le mode `by-namespace` (ciblant `data-title^="wiki/..."`) est
  le plus stable car les namespaces sont une feature core de Logseq.
- Pour une colorisation plus robuste, envisager des plugins Logseq dédiés
  (ex: `logseq-graph-analysis`) ou attendre une future API native de colorisation.
- La sauvegarde `custom.css.bak.*` permet un rollback immédiat.
