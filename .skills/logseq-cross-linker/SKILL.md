---
name: logseq-cross-linker
description: >
  Tisse les liens manquants entre les pages du wiki Logseq. Use when the user says
  "tisse les liens", "ajoute les liens manquants", "connecte mon wiki", "liens wiki",
  "pages non connectées", "cross-link", après un ingest important.
---

# Logseq Cross-Linker — Tissage des liens

**REQUIRED:** Invoke logseq-llm-wiki skill first for Logseq syntax and file format rules.

## Étape 1 : Construire le registre des pages

Grep `title::` dans `wiki/**/*.md` pour extraire tous les titres de pages.
Construire une map : titre → chemin de fichier.

Exemple :
```
"Kubernetes 3488 - Gestion des clés JSON" → "wiki/kubris/kubernetes-3488.md"
"Capsule" → "wiki/kubris/capsule.md"
```

## Étape 2 : Détecter les mentions sans lien

Pour chaque page wiki :
1. Lire son contenu
2. Pour chaque titre du registre (sauf le titre de la page elle-même) :
   - Chercher si le titre ou des mots-clés significatifs (≥3 mots) apparaissent dans le texte
   - Vérifier qu'ils ne sont pas déjà sous forme `[[lien]]`
3. Collecter les mentions candidates

Filtrer les faux positifs : mots trop courts (<3 chars), termes génériques (le, la, un, de...).

## Étape 3 : Ajouter les liens

Pour chaque mention détectée :
1. Remplacer la première occurrence du terme dans la page par `[[wiki/thème/page|terme]]`
   (ne pas lier toutes les occurrences — juste la première apparition)
2. Mettre à jour la propriété `updated::` de la page modifiée

Exemple :
```
Avant : "...la gestion de Capsule implique..."
Après : "...la gestion de [[wiki/kubris/capsule|Capsule]] implique..."
```

## Étape 4 : Vérifier la bidirectionnalité

Pour chaque lien ajouté A → B :
- Vérifier que B a un lien vers A dans sa section "Liens"
- Si absent : ajouter `- [[wiki/thème/A]]` dans la section "Liens" de B

## Étape 5 : Rapport

```
🔗 Cross-Linker — Résultat
==========================
Pages analysées   : [N]
Liens ajoutés     : [N]
Liens bidirectionnels vérifiés : [N]

Pages les plus liées :
  1. [[wiki/thème/page]] — [N] liens entrants
  2. ...
```
