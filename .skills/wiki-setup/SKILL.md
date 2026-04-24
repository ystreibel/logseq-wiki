---
name: wiki-setup
description: >
  Initialise le wiki Logseq. Use when the user says "initialise mon wiki", "setup mon wiki",
  "crée mon wiki", "démarre le wiki". Creates wiki/ structure with _master-index.md,
  _manifest.json, _log.md, and theme subdirectories detected from pages/.
---

# Logseq Setup — Initialisation du wiki

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

## Étape 1 : Vérifier l'état actuel

- Lire `wiki/_manifest.json` si il existe
- Si le manifest existe et contient des sources ingérées : avertir l'utilisateur que le wiki
  existe déjà et demander confirmation avant de continuer
- Si `wiki/` existe mais est vide : procéder sans confirmation

## Étape 2 : Détecter les thèmes

Lire tous les fichiers `pages/*.md` (sauf `contents.md`, `excalidraw-*.md`, `hls__*.md`).
Pour chaque fichier, identifier les thèmes/projets principaux en lisant les titres de niveau 2
(`## `). Ce sont les candidats pour les sous-dossiers wiki.

Exemple : `MON ORGANISATION.md` contient `## 🏭 U-TECH` → thèmes : kubris, capsule, packmind...

## Étape 3 : Créer la structure wiki/

Créer les fichiers suivants :

### `wiki/_master-index.md`
```
title:: Wiki — Index Principal
category:: meta
tags:: index, wiki
summary:: Index principal du wiki Logseq — point d'entrée pour la navigation.
created:: [DATE]
updated:: [DATE]

# Wiki — Index Principal

## Thèmes

[Pour chaque thème détecté :]
- [[wiki/[thème]/_index]] — [description courte]

## Méta

- [[wiki/_log]] — Historique des opérations
```

### `wiki/_log.md`
```
title:: Wiki — Log des opérations
category:: meta
tags:: log, wiki
summary:: Historique de toutes les opérations du wiki (ingest, update, rebuild).
created:: [DATE]
updated:: [DATE]

# Wiki — Log

## Log

- [DATE]T[HEURE] SETUP — initialisation du wiki, [N] thèmes détectés
```

### `wiki/_manifest.json`
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

### `wiki/_meta/taxonomy.md`
```
title:: Taxonomie — Tags Contrôlés
category:: meta
tags:: taxonomy, wiki, meta
summary:: Vocabulaire contrôlé de tags pour le wiki Logseq.
created:: [DATE]
updated:: [DATE]

# Taxonomie des Tags

## Règles
- Maximum 5 tags par page (hors tags de visibilité)
- Minuscules et tirets uniquement : `mon-tag` pas `MonTag`
- Préférer large à spécifique : `kubernetes` pas `kubernetes-3488`
- Les tags `visibility/public`, `visibility/internal`, `visibility/pii` sont réservés

## Tags canoniques

| Tag | Usage |
|---|---|
| index | Pages _index.md |
| wiki | Pages méta du wiki |
| log | Fichiers de log |
| meta | Fichiers de configuration wiki |
```

### Pour chaque thème détecté : `wiki/[thème]/_index.md`
```
title:: [Thème] — Index
category:: [thème]
tags:: index, [thème]
summary:: Index du thème [thème] — toutes les pages associées.
created:: [DATE]
updated:: [DATE]

# [Thème] — Index

## Pages

_(à remplir lors de l'ingest)_

## Liens

- [[wiki/_master-index]]
```

## Étape 4 : Confirmer à l'utilisateur

Afficher :
- Les thèmes détectés et les dossiers créés
- Le chemin vers `wiki/_master-index.md`
- La prochaine étape : "Lance 'ingère mon vault' pour distiller tes notes dans le wiki."
