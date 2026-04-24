---
name: wiki-ingest
description: >
  Distille tout le vault Logseq dans le wiki. Use when the user says "ingère mon vault",
  "ingère tout", "distille mes notes", "crée le wiki depuis mes notes", "ingest complet".
  Reads pages/, journals/, and referenced assets, then creates wiki pages organized by theme.
  Default mode: append (skip unchanged sources). Full mode: reprocess everything.
---

# Logseq Ingest — Ingestion complète

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

**Règle paths :** Tous les chemins lus depuis LOGSEQ_VAULT_PATH doivent être quotés dans les
commandes shell (ex: `"$LOGSEQ_VAULT_PATH/pages/"`) pour supporter les espaces et caractères
spéciaux (OneDrive, chemins Windows via WSL).

## Avant de commencer

1. Lire `wiki/_manifest.json` — si absent, dire à l'utilisateur de lancer `wiki-setup` d'abord
2. Lire `wiki/_master-index.md` pour connaître les thèmes existants
3. **Lire `wiki/_meta/exclusions.yml`** si présent — mémoriser les exclusions à appliquer :
   - `files:` — chemins exacts à exclure
   - `patterns:` — globs à exclure (ex: `pages/entretiens_*.md`)
   - `tags:` — exclure toute source dont le frontmatter contient un de ces tags
   - `themes:` — ne pas créer de pages wiki pour ces thèmes
4. Déterminer le mode :
   - **Mode append (défaut)** : skip les sources dont le hash SHA-256 n'a pas changé
   - **Mode full** : si l'utilisateur dit "tout réingérer" ou "force ingest"

## Étape 1 : Inventaire des sources

Lister toutes les sources :
- `pages/*.md` — exclure : `contents.md`, `excalidraw-*.md`, `hls__*.md`,
  `excalidraw-library-items-storage.md`
- `journals/*.md` — tous les fichiers
- Assets référencés : pour chaque `.md` déjà listé, extraire les refs `![](../assets/...)` et
  `[texte](../assets/...)` pour identifier les assets à ingérer

Appliquer les exclusions de `exclusions.yml` : retirer les sources correspondant aux `files:`,
`patterns:`, et celles dont les tags frontmatter recoupent `tags:`.

## Étape 2 : Filtrage (mode append)

Pour chaque source :
1. Calculer son hash : utiliser Bash `shasum -a 256 <fichier> | awk '{print $1}'`
2. Comparer au `content_hash` dans `_manifest.json`
3. Si hash identique → skip (source inchangée)
4. Si hash différent ou source absente du manifest → à ingérer

Annoncer à l'utilisateur : "X sources à ingérer, Y skippées (inchangées)"

## Gros volumes

Si le vault contient plus de 100 fichiers journaux, traiter par batch annuel :
1. Ingérer d'abord `pages/*.md` en une seule passe (toujours prioritaire)
2. Puis ingérer les journaux par année : `journals/2023_*.md`, puis `journals/2024_*.md`, etc.
3. Annoncer avant chaque batch : "Batch [YYYY] — ~N fichiers, estimation ~M minutes"
   (estimation indicative : ~1 min pour 10 journaux simples)

Cette approche évite les timeouts et permet de reprendre en cas d'interruption.

## Étape 3 : Distillation source par source

Pour chaque source à ingérer :

### Pour une page `pages/*.md`
1. Lire le fichier complet
2. Identifier le ou les thèmes couverts (sections `##`, projets nommés)
3. Vérifier que les thèmes identifiés ne sont pas dans `exclusions.yml` → `themes:`
4. Pour chaque thème/sujet identifié, créer ou mettre à jour une page wiki :
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
4. Écrire la page wiki avec le format défini dans llm-wiki

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

Mettre à jour les stats globales en recalculant depuis les données réelles (pas par incrémentation) :
```json
"stats": {
  "total_sources_ingested": <len(sources) — nombre de clés dans sources{}>,
  "total_pages_created": <nombre de fichiers .md dans wiki/ excluant _master-index.md,
                          _log.md, et tous fichiers dans wiki/_meta/ et wiki/_archive/>
}
```

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
