---
name: wiki-capture
description: >
  Sauvegarder la conversation courante comme note wiki permanente et structurée. Déclencher
  quand l'utilisateur dit "sauvegarde ça", "/wiki-capture", "capture ça", "archive cette
  conversation", "préserve ça", "ajoute ça à mon wiki", ou veut transformer la discussion
  actuelle en connaissance durable. Le skill classe le contenu, le réécrit comme connaissance
  déclarative (pas un transcript), et le dépose dans le bon thème du wiki.
---

# Wiki Capture — Conversation → Note Wiki

Tu préserves la connaissance de la conversation actuelle comme note wiki permanente.
L'objectif est d'extraire la *substance* — la connaissance elle-même — pas un résumé
de ce qui a été dit.

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local) → `LOGSEQ_VAULT_PATH`
2. Lire `$LOGSEQ_VAULT_PATH/wiki/_master-index.md` pour connaître le contenu existant
   (éviter les doublons et choisir le bon thème)

## Étape 1 : Identifier ce qui vaut la peine d'être préservé

Scanner la conversation. Se demander : quelle connaissance est apparue ici qui aurait
de la valeur dans 3 mois sans aucun souvenir de ce chat ?

**À préserver :**
- Décisions prises et *pourquoi* elles ont été prises
- Analyses, frameworks, modèles mentaux développés
- Résultats techniques, patterns ou procédures
- Compréhension synthétisée d'un sujet
- Explications claires d'un concept qui ont demandé un effort
- Faits clés d'une source externe discutée dans la conversation

**À ignorer :**
- Logistique, planification, politesses
- Échanges exploratoires sans conclusion
- Contenu déjà présent dans le wiki

Si rien de substantiel n'est apparu, informer l'utilisateur et s'arrêter.

## Étape 2 : Classifier le type de contenu

Assigner l'un des cinq types — détermine le thème cible et le ton :

| Type | Description | Thème cible |
|---|---|---|
| `synthèse` | Analyse multi-étapes ou réponse à une question spécifique | `wiki/synthèse/` |
| `concept` | Définition, framework, modèle mental (ce qu'une chose *est*) | `wiki/concepts/` |
| `source` | Résumé d'un document, article ou ressource externe discuté | `wiki/références/` |
| `décision` | Choix stratégique, architectural ou de design et sa justification | `wiki/synthèse/` |
| `session` | Résumé de discussion quand la conversation couvre plusieurs sujets | `wiki/journal/` |

Si le contenu appartient clairement à un projet spécifique (détecté depuis le contexte),
le placer sous `wiki/projets/<nom-projet>/` à la place.

## Étape 3 : Réécrire comme connaissance déclarative

**Ne pas** écrire un résumé de la conversation. Écrire la connaissance elle-même,
au présent déclaratif :

- ❌ "L'utilisateur a demandé à propos de X et Claude a expliqué que..."
- ✅ "X fonctionne en..."
- ❌ "Nous avons décidé d'utiliser Y parce que..."
- ✅ "Y est préféré à Z car [raison]. [^[inféré] si la justification était implicite]"

Appliquer les marqueurs de provenance :
- *Extrait* — dit explicitement dans la conversation (aucun marqueur)
- *Inféré* — généralisé ou synthétisé → `^[inféré]`
- *Ambigu* — disputé, incertain ou contradictoire → `^[ambigu]`

## Étape 4 : Générer un slug et titre

Dériver un titre clair et descriptif depuis le contenu. Slugifier :
- Minuscules, mots séparés par des tirets
- Max 50 caractères
- Éviter les dates dans le slug (la propriété `created::` les a)

## Étape 5 : Écrire la note wiki

Créer le fichier au chemin cible. **Utiliser les propriétés Logseq** (jamais YAML) :

```
title:: <Titre>
category:: <synthèse|concepts|références|journal|skills>
tags:: <2-5 tags de domaine depuis la taxonomie>
sources:: conversation:<date-ISO>
created:: <timestamp ISO>
updated:: <timestamp ISO>
summary:: <1-2 phrases, ≤200 chars, répondant à "quelle connaissance cette page contient-elle ?">
base_confidence:: 0.42
lifecycle:: draft
lifecycle_changed:: <date du jour>

# <Titre>

<Corps de la note — connaissance déclarative, pas transcript>
```

Relier à des pages existantes via des wikilinks Logseq `[[wiki/thème/page]]` appropriés.
Viser 2-5 liens sortants vers des pages wiki existantes.

## Étape 6 : Mettre à jour les fichiers système

1. **`wiki/_master-index.md`** — ajouter la nouvelle page dans la section appropriée
2. **`wiki/_manifest.json`** — ajouter avec :
   ```json
   {
     "source": "conversation:<date-ISO>",
     "type": "capture",
     "ingested_at": "<timestamp>",
     "pages": ["<chemin-relatif>"]
   }
   ```
3. **`wiki/_log.md`** :
   ```
   - [TIMESTAMP] CAPTURE type=<type> slug=<slug> page=<chemin>
   ```

## Cas limites

| Situation | Traitement |
|---|---|
| Contenu trop bref (< 3 points substantiels) | Proposer d'enrichir manuellement ; créer quand même si l'utilisateur confirme |
| Page similaire déjà dans le wiki | Proposer de mettre à jour la page existante plutôt que créer un doublon |
| Sujet ambigu (plusieurs types possibles) | Demander à l'utilisateur quel type est le plus approprié |
| Contenu couvre plusieurs sujets distincts | Proposer de créer N pages plutôt qu'une seule |
