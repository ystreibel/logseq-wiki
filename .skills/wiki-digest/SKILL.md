---
name: wiki-digest
description: >
  Génère un digest périodique des connaissances — résumé lisible de ce qui a été appris,
  mis à jour et connecté dans le wiki Logseq sur une période donnée (jour/semaine/mois).
  Déclencher quand l'utilisateur dit "qu'ai-je appris cette semaine", "donne-moi un digest",
  "résumé hebdomadaire", "rapport de connaissance", "quoi de neuf dans mon wiki",
  "/wiki-digest [période]", "résume mon apprentissage récent". Distinct de wiki-status
  (qui rapporte le delta des sources) — wiki-digest résume les *connaissances*, pas les sources.
---

# Wiki Digest — Générateur de Newsletter de Connaissance

Tu génères un digest lisible de l'activité récente du wiki : ce qui a été appris, mis à jour,
quels thèmes émergent, et ce qui mérite une relecture. Ce skill résume les *connaissances*,
pas les sources — pense à une session de revue hebdomadaire, pas un rapport d'ingestion.

## Avant de commencer

1. Lire `~/.logseq-wiki/config` (ou `.env` local, premier trouvé) → `LOGSEQ_VAULT_PATH`
2. **Parser la période** depuis la requête de l'utilisateur :
   - "quotidien" / "aujourd'hui" / "hier" → dernières 24h
   - "hebdomadaire" / "cette semaine" / sans argument (défaut) → 7 derniers jours
   - "mensuel" / "ce mois" → 30 derniers jours
   - Date ISO "depuis 2026-05-01" → pages mises à jour depuis cette date
   - Nombre explicite "14 derniers jours" → cette durée
3. Lire `$LOGSEQ_VAULT_PATH/wiki/_log.md` — 200 dernières lignes — pour les entrées
   dans la période (timestamps en préfixe ISO-8601)
4. Si `$LOGSEQ_VAULT_PATH/wiki/_insights.md` existe, lire son tableau **Pages Ancres**

## Étape 1 : Collecter les pages actives dans la période

Lister tous les `.md` sous `$LOGSEQ_VAULT_PATH/wiki/`. Ignorer :
- `wiki/_master-index.md`, `wiki/_log.md`, `wiki/_manifest.json`
- Tout ce qui est sous `wiki/_meta/`, `wiki/_archive/`
- Les pages digest elles-mêmes (`wiki/journal/digest-*.md`)

Pour chaque page restante, lire ses propriétés Logseq (lignes `propriété:: valeur`
en début de fichier) :
- `created::` — date de création
- `updated::` — date de dernière modification

Classer :
- **Nouvelles pages** : `created::` est dans la période
- **Pages mises à jour** : `updated::` est dans la période mais `created::` est antérieur
- **Inchangées** : aucune date dans la période → ignorer

Si moins de 5 pages actives, proposer d'élargir :
*"Seulement 3 pages actives ces 7 derniers jours — veux-tu un digest mensuel à la place ?"*

Pour chaque page active, collecter : `title::`, `tags::`, `summary::`, `lifecycle::`,
les marqueurs `^[ambigu]` ou `^[inféré]` dans le corps.

## Étape 2 : Identifier les thèmes

Depuis les tags de toutes les pages actives, compter la fréquence :

```
Pour chaque tag des nouvelles pages + pages mises à jour :
  compter combien de pages actives le portent
Trier décroissant, prendre le top 5
```

Lire `$LOGSEQ_VAULT_PATH/wiki/_meta/taxonomy.md` si présent. Signaler les tags de l'étape 1
absents de la taxonomie — nouveau vocabulaire apparu cette période.

## Étape 3 : Trouver les nouvelles connexions notables

Scanner les pages nouvelles et mises à jour pour les wikilinks cross-thèmes — liens
qui relient des espaces de nommage différents (ex: `[[wiki/concepts/X]]` → `[[wiki/entités/Y]]`).

Classer par intérêt :
- **+3** si le lien relie deux thèmes qui se croisent rarement (données `_insights.md`)
- **+2** si la page cible est dans le top-10 des hubs (`_insights.md`)
- **+2** si le lien est dans une page `wiki/synthèse/`
- **+1** si la source contient `^[inféré]`

Prendre les 3-5 meilleures connexions. Écrire chacune en français clair :
pas "A → B" mais *pourquoi* cette connexion est intéressante.

## Étape 4 : Détecter les fils ouverts

- **Brouillons** : pages `lifecycle:: draft` ou `lifecycle:: stub`
- **Claims ambigu** : compter les `^[ambigu]` (ne pas lister chacun — juste le total)
- **Écarts de taxonomie** : tags de l'étape 2 absents de `_meta/taxonomy.md`

## Étape 5 : Recommander des relectures

Parmi les pages *existantes avant la période*, identifier 2-3 à relire vu le nouveau contexte.

Heuristique : pages pré-période partageant le plus de tags avec les pages actives.
Ces pages fondatrices sont étendues par les nouvelles — l'utilisateur ne les a peut-être
pas relues.

Aussi inclure toute page pré-période qui a maintenant 2+ nouveaux liens entrants issus
des pages actives (elle est devenue plus connectée — signe qu'elle est structurante).

## Étape 6 : Générer le Digest

Produire un rapport Markdown structuré et scannable. Utiliser des wikilinks Logseq
au format `[[wiki/thème/page]]`.

```markdown
# Wiki Digest — [Label Période]
> [N nouvelles pages · M mises à jour · période : YYYY-MM-DD → YYYY-MM-DD]

## Titres

- [Insight concret #1 — synthétiser la vraie connaissance, pas juste "appris sur X"]
- [Insight concret #2]
- [Insight concret #3]

## Nouvelles Connaissances

### Nouvelles pages ([count])
| Page | Thème | Résumé |
|---|---|---|
| [[wiki/concepts/foo]] | concepts | Résumé en une phrase |
| [[wiki/entités/bar]] | entités | Résumé en une phrase |

### Mises à jour notables ([count])
| Page | Ce qui a changé |
|---|---|
| [[wiki/skills/react-hooks]] | Ajout de patterns pour useCallback avec effets async |

## Thèmes Émergents

- **[tag]** ([N pages]) — [Une phrase sur pourquoi ce sujet était actif]
- **[NOUVEAU TAG]** ([N pages]) ⭐ *Nouveau vocabulaire — pas encore dans la taxonomie*

Thème le plus actif : **[thème]** ([N pages ajoutées ou mises à jour])

## Connexions Clés

- [[wiki/concepts/A]] → [[wiki/entités/B]] — [Raison en français clair]
- [[wiki/synthèse/X]] créé — relie [[wiki/concepts/Y]] et [[wiki/concepts/Z]]

## Fils Ouverts

- **Brouillons à compiler** ([count]): [[wiki/concepts/foo]] — encore en lifecycle draft
- **Claims ambigus** : [N] marqueurs `^[ambigu]` sur [M] pages — lancer `/wiki-synthesize`
- **Écarts taxonomie** : Tags `newtag1`, `newtag2` utilisés mais absents — lancer `/tag-taxonomy`

## Relectures Recommandées

- [[wiki/concepts/X]] — [Raison précise : "3 nouvelles pages cette semaine l'étendent"]
- [[wiki/synthèse/Y]] — [Raison précise : "2 nouvelles pages créées cette semaine y font référence"]

---
*Généré par wiki-digest · [TIMESTAMP] · [N pages scannées dans [LOGSEQ_VAULT_PATH]]*
```

**Visibilité** : si une page a le tag `visibility/pii`, l'exclure des tableaux et listes
(mais la compter dans les totaux, notée "+ N privées").

## Étape 7 : Sortie & Sauvegarde optionnelle

**Défaut (sortie chat) :** Afficher le digest directement. À la fin, demander :
*"Veux-tu que je le sauvegarde comme `wiki/journal/digest-YYYY-MM-DD.md` ?"*

**Si l'utilisateur préfixe avec "sauvegarder"** (ex: `/wiki-digest sauvegarder`) :
- Écrire dans `$LOGSEQ_VAULT_PATH/wiki/journal/digest-YYYY-MM-DD.md`
- Utiliser les propriétés Logseq en début de fichier :
  ```
  title:: Wiki Digest — [Label Période]
  category:: journal
  tags:: digest, meta/review
  created:: TIMESTAMP
  updated:: TIMESTAMP
  summary:: Digest hebdomadaire : [N nouvelles, M mises à jour]. Thèmes : [tag1], [tag2].
  ```
- Mettre à jour `wiki/_master-index.md`
- Ne **pas** ajouter à `wiki/_manifest.json` (les digests ne sont pas des ingestions sources)

Dans tous les cas, ajouter dans `wiki/_log.md` :
```
- [TIMESTAMP] DIGEST période="7j" nouvelles_pages=N mises_à_jour=M thèmes=T connexions=C sauvegardé=false
```

## Cas limites

| Situation | Traitement |
|---|---|
| Moins de 5 pages actives | Proposer d'élargir la période ; continuer seulement si confirmé |
| Wiki vide (aucune page) | Dire à l'utilisateur de lancer un ingest d'abord |
| Pas de `_meta/taxonomy.md` | Ignorer la vérification des écarts taxonomie |
| Pas de `_insights.md` | Ignorer le scoring basé sur les hubs |
| Toutes les pages sont `visibility/pii` | Rapporter "N pages privées actives" sans détails |
| La période couvre un rebuild du wiki | Le noter dans le digest |
