---
name: wiki-switch
description: >
  Basculer entre plusieurs profils de vault Logseq wiki. Déclencher quand l'utilisateur dit
  "/wiki-switch NOM", "bascule vers mon wiki pro", "changer de vault", "changer de wiki",
  "sur quel wiki suis-je", "liste mes wikis", "montre mes vaults", "crée un nouveau config",
  ou "ajoute un nouveau profil wiki". Le skill gère les fichiers de config nommés à
  ~/.logseq-wiki/config.<nom> et active l'un d'eux en créant un symlink vers ~/.logseq-wiki/config.
---

# Wiki Switch — Gérer plusieurs profils de vault

Chaque vault est un fichier de config complet à `~/.logseq-wiki/config.<nom>`. Le vault actif
est celui vers lequel pointe le symlink `~/.logseq-wiki/config`. Changer de vault = re-pointer
ce symlink.

## Dispatch

Parser l'invocation et router vers la bonne section :

| Invocation | Action |
|---|---|
| `/wiki-switch <nom>` | → **Basculer** |
| `/wiki-switch list` | → **Lister** |
| `/wiki-switch show [nom]` | → **Afficher** |
| `/wiki-switch new <nom>` | → **Nouveau** |
| `/wiki-switch` (sans args) | → **Lister** |

---

## Basculer (action par défaut)

Activer un profil de vault nommé.

1. Vérifier que `~/.logseq-wiki/config.<nom>` existe. Sinon, informer l'utilisateur et lister
   les vaults disponibles (lancer **Lister**).
2. Exécuter :
   ```bash
   ln -sf ~/.logseq-wiki/config.<nom> ~/.logseq-wiki/config
   ```
3. Lire `LOGSEQ_VAULT_PATH` depuis la config nouvellement activée.
4. Confirmer à l'utilisateur :
   ```
   Vault activé : <nom>
   Chemin du vault : <valeur de LOGSEQ_VAULT_PATH>
   ```

---

## Lister

Afficher tous les profils de vault enregistrés et lequel est actif.

1. Trouver tous les fichiers correspondant à `~/.logseq-wiki/config.*` (exclure `config`
   lui-même — c'est le symlink).
2. Résoudre la cible du symlink actuel : `readlink ~/.logseq-wiki/config`
3. Pour chaque fichier de config, lire la première ligne de commentaire non vide (lignes
   commençant par `#`) comme description humaine. Sinon, utiliser le suffixe du fichier.
4. Afficher :
   ```
   Vaults :
     perso    Mon wiki de recherche personnel    ← actif
     pro      Wiki projets professionnels
   ```
   Marquer l'actif avec `← actif`. Si le symlink est cassé ou `config` n'existe pas,
   afficher `(aucun actif)`.

---

## Afficher

Afficher la config complète d'un vault.

- Si un nom est donné, lire `~/.logseq-wiki/config.<nom>`.
- Si aucun nom, lire `~/.logseq-wiki/config` (le vault actif).
- Si le fichier n'existe pas, informer l'utilisateur et lister les disponibles.
- Afficher le contenu verbatim (masquer toute ligne contenant `API_KEY` ou `SECRET` —
  afficher `***` à la place de la valeur).

---

## Nouveau

Créer un nouveau fichier de config de vault à partir du config actif comme template.

1. Vérifier que `~/.logseq-wiki/config.<nom>` n'existe pas déjà. Abandonner si oui.
2. Copier `~/.logseq-wiki/config` vers `~/.logseq-wiki/config.<nom>` :
   ```bash
   cp ~/.logseq-wiki/config ~/.logseq-wiki/config.<nom>
   ```
3. Dans la copie, mettre à jour `LOGSEQ_VAULT_PATH` en demandant à l'utilisateur le
   nouveau chemin de vault :
   *"Quel est le chemin de ton vault Logseq pour le profil '<nom>' ?"*
4. Optionnellement : ajouter un commentaire en première ligne décrivant le vault :
   ```
   # <description du vault>
   ```
5. Confirmer :
   ```
   Nouveau profil créé : <nom>
   Config : ~/.logseq-wiki/config.<nom>
   Pour l'activer : /wiki-switch <nom>
   ```

---

## Notes

- Les configs Logseq wiki sont des fichiers shell-compatibles : `CLE=valeur` (pas de YAML)
- Les clés standards : `LOGSEQ_VAULT_PATH`, `LOGSEQ_WIKI_REPO`, `WIKI_TOKEN_WARN_THRESHOLD`
- Ne jamais modifier `LOGSEQ_VAULT_PATH/pages/` ou tout autre répertoire source Logseq
- Après un switch, toutes les commandes wiki utilisent le nouveau `LOGSEQ_VAULT_PATH`
