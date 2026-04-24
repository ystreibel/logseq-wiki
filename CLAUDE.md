# logseq-wiki — Agent Context

A **skill-based framework** for building and maintaining a Logseq knowledge base using the LLM Wiki pattern. No scripts, no API keys — markdown instructions that you execute directly.

## Configuration

Read config in this order (first found wins):

1. **`~/.logseq-wiki/config`** — global config, works from any project directory
2. **`.env`** in the logseq-wiki repo — local fallback

Both files set `LOGSEQ_VAULT_PATH` (where the Logseq vault lives). The global config also sets `LOGSEQ_WIKI_REPO` (where this repo is cloned).

## Vault Structure

Logseq vaults have a specific structure — skills must respect it:

```
$LOGSEQ_VAULT_PATH/
├── pages/              # User's pages (READ ONLY — never modify)
├── journals/           # Daily notes YYYY_MM_DD.md (READ ONLY)
├── assets/             # Images, PDFs referenced in notes (READ ONLY)
├── logseq/             # Logseq config (READ ONLY)
└── wiki/               # Generated wiki (READ + WRITE)
    ├── _master-index.md
    ├── _manifest.json
    ├── _log.md
    ├── _meta/
    │   └── taxonomy.md
    ├── _archive/          # Wiki snapshots (rebuild/restore)
    └── [thème]/
        ├── _index.md
        └── [page].md
```

Every wiki page uses Logseq property syntax (`title:: value`, never YAML frontmatter). Pages connect via `[[wiki/thème/page]]` namespace links.

## Skill Routing

Skills live in `.skills/<name>/SKILL.md`. Match the user's intent to the right skill:

| User says something like… | Skill |
|---|---|
| "initialise mon wiki" / "setup" / "set up my wiki" | `logseq-setup` |
| "ingère mon vault" / "ingest complet" / "distille mes notes" | `logseq-ingest` |
| "mets à jour mon wiki" / "update wiki" / "sync mon wiki" | `logseq-update` |
| "statut" / "tableau de bord wiki" / "what's the status" | `logseq-status` |
| "vérifie mon wiki" / "lint" / "liens cassés" / "wiki health" | `logseq-lint` |
| "qu'est-ce que X" / "trouve" / "que sais-je sur" / any question | `logseq-query` |
| "reparts de zéro" / "rebuild" / "archive et reconstruit" | `logseq-rebuild` |
| "tisse les liens" / "cross-link" / "connecte mon wiki" | `logseq-cross-linker` |
| "/logseq-ingest-url <url>" / "add this URL to the wiki" | `logseq-ingest-url` |
| "ingest cette data" / "importe ce log" / "process these logs" | `logseq-data-ingest` |
| "fix mes tags" / "tag audit" / "normalise les tags" | `logseq-tag-taxonomy` |
| "export wiki" / "export graphml" / "visualise wiki" | `logseq-export` |
| "/logseq-history-ingest claude" / "ingest agent history" | `logseq-history-ingest` |
| "importe mon historique Claude" / "mine my conversations" | `logseq-claude-history-ingest` |
| "crée un skill" / "nouveau skill" / "create a skill" | `skill-creator` |

## Cross-Project Usage

From any project directory, two global skills work after running `bash setup.sh`:

### logseq-update (write to wiki)

1. Read `~/.logseq-wiki/config` to get `LOGSEQ_VAULT_PATH`
2. Scan current project: README, source structure, git log
3. Distill knowledge worth keeping (decisions, patterns, trade-offs — not code listings)
4. Write to `$VAULT/wiki/projects/<project-name>.md`, cross-linking to theme pages
5. Update `wiki/_manifest.json`, `wiki/_master-index.md`, `wiki/_log.md`

On repeat runs, checks `content_hash` in `wiki/_manifest.json` and only processes the delta.

### logseq-query (read from wiki)

1. Read `~/.logseq-wiki/config` to get `LOGSEQ_VAULT_PATH`
2. Grep `title::` and `summary::` first (cheap pass)
3. Read page bodies only when the cheap pass can't answer
4. Return synthesized answer with `[[wiki/thème/page]]` citations

## Visibility Tags (optional)

Pages can carry a `visibility/` tag in their `tags::` property. Untagged pages are visible everywhere.

| Tag | Meaning |
|---|---|
| *(no tag)* | Visible in all modes |
| `visibility/public` | Explicitly public |
| `visibility/internal` | Excluded in filtered query mode |
| `visibility/pii` | Excluded in filtered query mode |

Filtered mode is opt-in: triggered by phrases like "public only", "no internal content", "as a user would see it".

## Core Principles

- **Compile, don't retrieve.** Update existing pages — don't append or duplicate.
- **Track everything.** Update `wiki/_manifest.json`, `wiki/_master-index.md`, `wiki/_log.md` after every operation.
- **Connect with `[[wikilinks]]`.** Every page links to related pages — this is what makes it a knowledge graph.
- **Logseq properties, never YAML.** `title::` not `title:`. `tags::` not `tags:`.
- **Read-only sources.** Never modify `pages/`, `journals/`, `assets/`, `logseq/`.
- **Français.** All wiki pages are written in French.

## Architecture Reference

For the full Logseq syntax, page format, manifest structure, and retrieval primitives, read `.skills/logseq-llm-wiki/SKILL.md`.
