# Logseq Wiki — Agent Context

A **skill-based framework** for building and maintaining a Logseq knowledge base. No scripts or dependencies — everything is markdown instructions that you execute directly.

## Configuration

Read config in this order (first found wins):

1. **`~/.logseq-wiki/config`** — global config, works from any project directory
2. **`.env`** in the logseq-wiki repo — local fallback

Both files set `LOGSEQ_VAULT_PATH` (where the wiki lives). The global config also sets `LOGSEQ_WIKI_REPO` (where this repo is cloned).

## Vault Structure

```
$LOGSEQ_VAULT_PATH/
├── pages/
│   ├── index.md                # Master index — every page listed, always kept current
│   ├── log.md                  # Chronological activity log (ingests, updates, lints)
│   ├── _meta.md                # Controlled tag vocabulary
│   ├── _insights.md            # Graph analysis output (hubs, bridges, dead ends)
│   ├── concepts/               # Abstract ideas, patterns, mental models
│   ├── entities/               # Concrete things — people, tools, libraries, companies
│   ├── skills/                 # How-to knowledge, techniques, procedures
│   ├── references/             # Factual lookups — specs, APIs, configs
│   ├── synthesis/              # Cross-cutting analysis connecting multiple concepts
│   └── projects/
│       └── <project-name>.md   # One page per project synced via logseq-update
├── journals/                   # Time-bound entries — daily logs, session notes
├── .manifest.json              # Tracks every ingested source: path, timestamps, pages produced
└── _raw/                       # Staging area — drop rough notes here, next ingest promotes them
```

Every wiki page has required properties: `title`, `category`, `tags`, `sources`, `created`, `updated` (using Logseq `::` property syntax). Pages connect via `[[wikilinks]]`.

## Skill Routing

Skills live in `.skills/<name>/SKILL.md`. Match the user's intent to the right skill:

| User says something like… | Skill |
|---|---|
| "set up my wiki" / "initialize" | `logseq-setup` |
| "/logseq-history-ingest claude" / "/logseq-history-ingest codex" / "/logseq-history-ingest hermes" | `logseq-history-ingest` |
| "/ingest-url <url>" / "add this URL" / "ingest this link" / "save this page" | `ingest-url` |
| "ingest" / "add this to the wiki" / "process these docs" | `logseq-ingest` |
| "import my Claude history" / "mine my conversations" | `claude-history-ingest` |
| "import my Codex history" / "mine my Codex sessions" | `codex-history-ingest` |
| "import my Hermes history" / "mine my Hermes memories" / "ingest ~/.hermes" | `hermes-history-ingest` |
| "import my OpenClaw history" / "mine my OpenClaw sessions" / "ingest ~/.openclaw" | `openclaw-history-ingest` |
| "process this export" / "ingest this data" / logs, transcripts | `data-ingest` |
| "what's the status" / "what's been ingested" / "show the delta" | `logseq-status` |
| "wiki insights" / "hubs" / "wiki structure" | `logseq-status` (insights mode) |
| "what do I know about X" / "find info on Y" / any question | `logseq-query` |
| "audit" / "lint" / "find broken links" / "wiki health" | `logseq-lint` |
| "rebuild" / "start over" / "archive" / "restore" | `logseq-rebuild` |
| "link my pages" / "cross-reference" / "connect my wiki" | `logseq-cross-linker` |
| "fix my tags" / "normalize tags" / "tag audit" | `tag-taxonomy` |
| "update wiki" / "sync to wiki" / "save this to my wiki" | `logseq-update` |
| "export wiki" / "export graph" / "graphml" / "neo4j" | `logseq-export` |
| "create a new skill" | `skill-creator` |

## Cross-Project Usage

The main use case: you're working in some other project and want to sync knowledge into your wiki or query it. Two global skills handle this — `logseq-update` and `logseq-query`. They work from any directory.

### logseq-update (write to wiki)

1. Read `~/.logseq-wiki/config` to get `LOGSEQ_VAULT_PATH`
2. Scan the current project: README, source structure, git log, package metadata
3. Distill what's worth remembering (architecture decisions, patterns, trade-offs — not code listings)
4. Write to `$VAULT/pages/projects/<project-name>.md`, cross-linking to concept/entity pages as needed
5. Update `.manifest.json`, `pages/index.md`, and `pages/log.md`

On repeat runs, it checks `last_commit_synced` in `.manifest.json` and only processes the delta via `git log <last_commit>..HEAD`.

### logseq-query (read from wiki)

1. Read `~/.logseq-wiki/config` to get `LOGSEQ_VAULT_PATH`
2. Scan titles, tags, and `summary::` property fields first (cheap pass)
3. Only open page bodies when the index pass can't answer
4. Return a synthesized answer with `[[wikilink]]` citations

## Visibility Tags (optional)

Pages can carry a `visibility/` tag to mark their intended reach. **This is entirely optional** — untagged pages behave exactly as they always have (visible everywhere). The system stays single-vault, single source of truth.

| Tag | Meaning |
|---|---|
| *(no tag)* | Same as `visibility/public` — visible in all modes |
| `visibility/public` | Explicitly public — visible in all modes |
| `visibility/internal` | Team-only — excluded when querying in filtered mode |
| `visibility/pii` | Sensitive data — excluded when querying in filtered mode |

**Filtered mode** is opt-in, triggered by phrases like "public only", "user-facing answer", "no internal content", or "as a user would see it" in a query. Default mode shows everything.

`visibility/` tags are **system tags** — they don't count toward the 5-tag limit and are listed separately from domain/type tags in the taxonomy.

See `logseq-query` and `logseq-export` skills for how the filter is applied.

## Core Principles

- **Compile, don't retrieve.** The wiki is pre-compiled knowledge. Update existing pages — don't append or duplicate.
- **Track everything.** Update `.manifest.json` after ingesting, `pages/index.md` and `pages/log.md` after any operation.
- **Connect with `[[wikilinks]]`.** Every page should link to related pages. This is what makes it a knowledge graph, not a folder of files.
- **Properties are required.** Every wiki page needs: `title`, `category`, `tags`, `sources`, `created`, `updated` (using Logseq `::` syntax).
- **Single source of truth.** Visibility tags shape how content is surfaced — they don't duplicate or separate it.

## Architecture Reference

For the full pattern (three-layer architecture, page templates, project org), read `.skills/logseq-llm-wiki/SKILL.md`.
