---
name: logseq-query
description: >
  Interroge le vault Logseq et son wiki pour répondre à des questions. Use when the user asks
  "qu'est-ce que...", "trouve...", "qu'a-t-on décidé sur...", "résume...", "que sais-je sur...",
  "cherche dans mes notes...", "qu'est-il arrivé à...", ou toute question sur le contenu du vault.
  Also use when the user wants to find information across journals or pages.
---

# Logseq Query — Interrogation du vault

**REQUIRED:** Invoke logseq-llm-wiki skill first for Logseq syntax and file format rules.

## Protocole de retrieval

Utilise toujours la primitive la moins coûteuse d'abord :

### Étape 1 : Classifier la question

- **Factuelle** ("qu'est-ce que X ?") → chercher la page wiki dédiée
- **Décision** ("qu'a-t-on décidé sur X ?") → chercher pages wiki + journaux
- **Temporelle** ("que s'est-il passé en avril ?") → chercher journaux par période
- **Synthèse** ("résume tout ce que je sais sur X") → chercher wiki + sources

### Étape 2 : Grep sur wiki/ d'abord

```
Grep pattern=[termes clés] path=wiki/ output_mode=files_with_matches
```

Si résultats suffisants (2+ fichiers pertinents) → passer à l'étape 4.
Si résultats insuffisants → étape 3.

### Étape 3 : Grep élargi sur pages/ + journals/

```
Grep pattern=[termes clés] path=pages/ output_mode=files_with_matches
Grep pattern=[termes clés] path=journals/ output_mode=files_with_matches
```

Prendre les 5 fichiers les plus récents ou les plus pertinents.

### Étape 4 : Lire les fichiers ciblés

Lire uniquement les fichiers identifiés aux étapes précédentes.
Ne jamais lire tous les fichiers d'un dossier sans grep préalable.

### Étape 5 : Répondre

- Répondre en français, de façon synthétique
- Citer les sources avec `[[liens]]` Logseq
- Si la question porte sur une décision, mettre en avant le contexte et le raisonnement
- Si les informations sont partielles, le dire explicitement
- Si aucune information trouvée : le dire et suggérer "ingère mon vault" si le wiki est vide

## Mode rapide

Déclenché par "réponse rapide", "juste un aperçu", "sans lire les pages" :
- Lire uniquement les `summary::` des pages wiki (grep sur `summary::`)
- Répondre depuis les résumés sans lire le corps des pages
