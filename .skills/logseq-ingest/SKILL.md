---
name: logseq-ingest
description: >
  Distille tout le vault Logseq dans le wiki. Use when the user says "ingère mon vault",
  "ingère tout", "distille mes notes", "crée le wiki depuis mes notes", "ingest complet".
  Reads pages/, journals/, and referenced assets, then creates wiki pages organized by theme.
  Default mode: append (skip unchanged sources). Full mode: reprocess everything.
---

# Logseq Ingest — Ingestion complète

**REQUIRED:** Invoke logseq-llm-wiki skill first for Logseq syntax and file format rules.

## Avant de commencer

1. Lire `wiki/_manifest.json` — si absent, dire à l'utilisateur de lancer `logseq-setup` d'abord
2. Lire `wiki/_master-index.md` pour connaître les thèmes existants
3. Déterminer le mode :
   - **Mode append (défaut)** : skip les sources dont le hash SHA-256 n'a pas changé
   - **Mode full** : si l'utilisateur dit "tout réingérer" ou "force ingest"

## Étape 1 : Inventaire des sources

Lister toutes les sources :
- `pages/*.md` — exclure : `contents.md`, `excalidraw-*.md`, `hls__*.md`,
  `excalidraw-library-items-storage.md`
- `journals/*.md` — tous les fichiers
- Assets référencés : pour chaque `.md` déjà listé, extraire les refs `![](../assets/...)` et
  `[texte](../assets/...)` pour identifier les assets à ingérer

## Étape 2 : Filtrage (mode append)

Pour chaque source :
1. Calculer son hash : utiliser Bash `shasum -a 256 <fichier> | awk '{print $1}'`
2. Comparer au `content_hash` dans `_manifest.json`
3. Si hash identique → skip (source inchangée)
4. Si hash différent ou source absente du manifest → à ingérer

Annoncer à l'utilisateur : "X sources à ingérer, Y skippées (inchangées)"

## Étape 3 : Distillation source par source

Pour chaque source à ingérer :

### Pour une page `pages/*.md`
1. Lire le fichier complet
2. Identifier le ou les thèmes couverts (sections `##`, projets nommés)
3. Pour chaque thème/sujet identifié, créer ou mettre à jour une page wiki :
   - **Ce qui vaut la peine d'être distillé :**
     - Décisions techniques et leur justification
     - Patterns et concepts réutilisables
     - Entités importantes (outils, services, personnes, projets)
     - Liens vers tickets, PRs, ressources externes
     - États actuels (DONE/NOW/LATER) des tâches importantes
   - **Ce qui ne vaut pas la peine :**
     - Détails d'implémentation lisibles directement dans la source
     - Entrées LOGBOOK (temps tracké) sauf si notable
     - Blocs `collapsed:: true` de faible valeur
4. Écrire la page wiki avec le format défini dans logseq-llm-wiki

### Pour un journal `journals/YYYY_MM_DD.md`
1. Lire le fichier
2. Identifier les événements notables : décisions, apprentissages, résolutions de problèmes,
   liens vers tickets
3. Enrichir les pages wiki existantes des thèmes concernés (merge, pas doublon)
4. Si un sujet nouveau émerge sans page existante, créer la page

### Pour un asset `assets/fichier`
1. Lire le fichier via Read (supporte images et PDFs)
2. Extraire le contenu pertinent
3. Enrichir la page wiki du thème concerné avec une section "Ressources"

## Étape 4 : Mettre à jour les index

Après avoir créé/mis à jour toutes les pages :
1. Mettre à jour `wiki/[thème]/_index.md` pour chaque thème : ajouter les nouvelles pages
2. Mettre à jour `wiki/_master-index.md` si de nouveaux thèmes ont été créés

## Étape 5 : Mettre à jour le manifest

Pour chaque source ingérée, ajouter ou mettre à jour dans `_manifest.json` :
```json
"chemin/source.md": {
  "ingested_at": "[ISO8601]",
  "content_hash": "sha256:[hash]",
  "pages_created": ["wiki/thème/page1"],
  "pages_updated": ["wiki/thème/page2"]
}
```
Mettre à jour `stats.total_sources_ingested` et `stats.total_pages_created`.
Mettre à jour `last_ingest` avec l'heure actuelle.

## Étape 6 : Logger et confirmer

Ajouter dans `wiki/_log.md` :
```
- [ISO8601] INGEST — [N] sources ingérées, [M] pages créées, [P] pages mises à jour
```

Afficher le résumé à l'utilisateur :
- Nombre de sources traitées
- Nombre de pages wiki créées / mises à jour
- Thèmes couverts
- Prochaine étape suggérée : "Lance 'mets à jour mon wiki' régulièrement pour rester à jour."
