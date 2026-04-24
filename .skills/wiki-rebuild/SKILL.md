---
name: wiki-rebuild
description: >
  Archive le wiki existant et repart de zéro. Use when the user says "reparts de zéro",
  "rebuild le wiki", "archive et reconstruit", "wiki à reconstruire", "nuke et repave".
  Always asks for confirmation before proceeding — this is a destructive operation.
---

# Logseq Rebuild — Reconstruction

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

## ⚠️ Opération destructive — confirmation requise

Avant toute action, afficher :

```
⚠️ ATTENTION : Cette opération va archiver tout le wiki actuel.
Contenu actuel : [N pages, M thèmes, dernière mise à jour le DATE]
Archive destination : wiki/_archive/YYYY-MM-DD/

Veux-tu continuer ? (oui/non)
```

Attendre la réponse. Si non ou ambiguë : arrêter.

## Étape 1 : Archiver

1. Créer `wiki/_archive/YYYY-MM-DD/` (date du jour)
2. Déplacer tous les fichiers de `wiki/` vers `wiki/_archive/YYYY-MM-DD/`
   (sauf `wiki/_archive/` lui-même)

Utiliser Bash :
```bash
DATE=$(date +%Y-%m-%d)
mkdir -p wiki/_archive/$DATE
find wiki -mindepth 1 -not -path 'wiki/_archive' -not -path 'wiki/_archive/*' | sort -r | xargs -I{} mv {} wiki/_archive/$DATE/ 2>/dev/null || true
```

## Étape 2 : Réinitialiser

Créer un nouveau `wiki/_manifest.json` vide :
```json
{
  "version": 1,
  "last_ingest": null,
  "stats": {
    "total_sources_ingested": 0,
    "total_pages_created": 0
  },
  "sources": {}
}
```

Créer un nouveau `wiki/_log.md` :
```
title:: Wiki — Log des opérations
category:: meta
tags:: log, wiki
summary:: Historique de toutes les opérations du wiki.
created:: [DATE]
updated:: [DATE]

# Wiki — Log

## Log

- [ISO8601] REBUILD — archive vers wiki/_archive/[DATE]/, manifest réinitialisé
```

## Étape 3 : Proposer un re-ingest

Afficher :
```
✅ Wiki archivé dans wiki/_archive/[DATE]/
   [N] pages archivées.

Lance 'initialise mon wiki' puis 'ingère mon vault' pour reconstruire.
Ou dis 'reconstruis et réingère' pour que je le fasse maintenant.
```

Si l'utilisateur veut reconstruire et réingérer : invoquer wiki-setup puis wiki-ingest.
