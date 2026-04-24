---
name: wiki-update
description: >
  Mise à jour incrémentale du wiki Logseq. Use when the user says "mets à jour mon wiki",
  "update wiki", "sync mon wiki", "nouvelles notes à intégrer", "wiki à jour".
  Only reprocesses sources modified since last ingest (hash-based detection).
---

# Logseq Update — Mise à jour incrémentale

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

## Avant de commencer

1. Lire `wiki/_manifest.json` — si absent ou `last_ingest` est null, dire à l'utilisateur
   de lancer `wiki-ingest` d'abord pour un ingest complet initial
2. Lire `wiki/_master-index.md` pour connaître les thèmes existants

## Étape 1 : Détecter les changements

Pour chaque source (pages/*.md, journals/*.md, assets référencés) :
1. Calculer le hash actuel : `shasum -a 256 <fichier> | awk '{print $1}'`
2. Comparer au `content_hash` dans `_manifest.json`

Catégoriser :
- **Modifiée** : hash différent de celui du manifest
- **Nouvelle** : absente du manifest
- **Supprimée** : dans le manifest mais fichier introuvable (signaler, ne pas supprimer la page wiki)
- **Inchangée** : hash identique → skip

Si aucun changement détecté : informer l'utilisateur et s'arrêter.

Annoncer : "X sources modifiées, Y nouvelles, Z supprimées (signalées)"

## Étape 2 : Traiter les sources modifiées et nouvelles

Pour chaque source modifiée ou nouvelle, appliquer la même logique que wiki-ingest
(Étapes 3 à 5), en mode **merge** :
- Lire la page wiki existante avant d'écrire
- Intégrer les nouvelles informations sans supprimer l'existant
- Mettre à jour la propriété `updated::` de la page wiki

## Étape 3 : Signaler les sources supprimées

Pour chaque source supprimée :
- Ne pas supprimer la page wiki correspondante
- Ajouter une note dans la page wiki : `> ⚠️ Source [chemin] introuvable depuis [DATE]`
- Logger dans `_log.md`

## Étape 4 : Mettre à jour manifest et log

Mettre à jour `_manifest.json` pour les sources traitées (hash, timestamp, pages).
Ajouter dans `wiki/_log.md` :
```
- [ISO8601] UPDATE — [N] sources modifiées, [M] pages mises à jour, [P] nouvelles pages
```

## Étape 5 : Confirmer

Afficher le résumé : sources traitées, pages mises à jour, sources supprimées signalées.
