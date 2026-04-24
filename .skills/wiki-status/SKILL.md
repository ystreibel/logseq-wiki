---
name: wiki-status
description: >
  Affiche l'état du wiki Logseq. Use when the user says "statut de mon wiki", "état du wiki",
  "qu'est-ce qui est ingéré", "combien de pages", "delta depuis dernier update",
  "tableau de bord wiki", "wiki dashboard".
---

# Logseq Status — Dashboard

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

## Étape 1 : Lire le manifest et le log

- Lire `wiki/_manifest.json`
- Lire `wiki/_log.md` (les 20 dernières lignes suffisent)

Si `_manifest.json` absent : informer que le wiki n'est pas initialisé, suggérer `wiki-setup`.

## Étape 2 : Compter les sources actuelles

- `Glob pattern=pages/*.md` → compter (exclure contents.md, excalidraw-*.md, hls__*.md)
- `Glob pattern=journals/*.md` → compter
- `Glob pattern=wiki/**/*.md` → compter (exclure _master-index.md, _log.md)

## Étape 3 : Calculer le delta

Sources dans manifest vs sources actuelles du vault :
- Sources ingérées : count des clés dans `_manifest.sources`
- Sources non ingérées : sources actuelles - sources ingérées
- Sources supprimées : sources dans manifest absentes du vault

Pour les sources non ingérées : lister les 5 plus récentes (journaux récents prioritaires).

## Étape 4 : Afficher le dashboard

```
📊 Statut du Wiki Logseq
========================

📁 Sources
  Pages     : [N] total, [X] ingérées, [Y] non ingérées
  Journaux  : [N] total, [X] ingérés, [Y] non ingérés

📝 Wiki
  Pages créées     : [N] (dans [M] thèmes)
  Dernière mise à jour : [DATE]

🔄 Delta
  Sources modifiées depuis dernier ingest : [N]
  Sources nouvelles non ingérées : [N]
  [Liste des 5 plus récentes si > 0]

⚠️ Alertes
  Sources supprimées encore dans manifest : [N]

💡 Suggestion : [selon l'état — "lance 'update' pour ingérer X nouvelles sources" ou "wiki à jour"]
```
