---
name: logseq-lint
description: >
  Vérifie la cohérence du wiki Logseq. Use when the user says "vérifie mon wiki", "lint",
  "check le wiki", "liens cassés", "pages orphelines", "problèmes dans le wiki".
---

# Logseq Lint — Vérification de cohérence

**REQUIRED:** Invoke logseq-llm-wiki skill first for Logseq syntax and file format rules.

## Checks à effectuer

### Check 1 : Liens cassés

Pour chaque page wiki dans `wiki/**/*.md` :
1. Extraire tous les `[[liens]]` avec Grep
2. Pour chaque lien de la forme `[[wiki/thème/page]]` : vérifier que le fichier
   `wiki/thème/page.md` existe via Glob
3. Reporter les liens cassés avec leur fichier source

### Check 2 : Pages orphelines

Construire la liste de toutes les pages wiki (Glob `wiki/**/*.md`).
Pour chaque page, vérifier qu'au moins un autre fichier la mentionne (Grep sur son titre
ou son chemin). Les pages sans liens entrants sont orphelines.
Exclure `_master-index.md` et `_index.md` de ce check.

### Check 3 : Sources supprimées

Pour chaque source dans `_manifest.json` : vérifier que le fichier existe.
Si absent : lister comme source supprimée.

### Check 4 : Pages wiki sans propriétés requises

Pour chaque page wiki, vérifier la présence de :
- `title::`
- `summary::`
- `sources::`
- `updated::`
Lister les pages avec propriétés manquantes.

### Check 5 : NOWs sans trace wiki

Grep `NOW` dans `journals/*.md` pour trouver les tâches en cours.
Vérifier que les sujets de ces tâches ont une page wiki correspondante.
Signaler les tâches NOW sans page wiki (suggère un ingest).

## Rapport

Afficher un rapport structuré :

```
🔍 Rapport Lint — Wiki Logseq
==============================

🔗 Liens cassés : [N]
  [liste des liens cassés avec fichier source]

👻 Pages orphelines : [N]
  [liste des pages sans liens entrants]

🗑️ Sources supprimées (encore dans manifest) : [N]
  [liste des sources]

📋 Pages avec propriétés manquantes : [N]
  [liste]

⏰ Tâches NOW sans page wiki : [N]
  [liste]

✅ [Si tout est clean :] Wiki en bonne santé !
```
