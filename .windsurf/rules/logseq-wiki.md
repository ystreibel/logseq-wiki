---
name: "Logseq Wiki"
activation: "always-on"
---

# Logseq Wiki — Agent Context

This project is a **skill-based framework** for building and maintaining a Logseq knowledge base.

## Quick Orientation

1. Read `~/.logseq-wiki/config` (or `.env` in this repo) for `LOGSEQ_VAULT_PATH` — this is where the Logseq vault lives.
2. Read `wiki/_manifest.json` inside the vault to see what's already been ingested.
3. Skills are in `.skills/` (also at `.windsurf/skills/`). Each subfolder has a `SKILL.md`.

## When to Use Skills

| User says something like… | Read this skill |
|---|---|
| "set up my wiki" / "initialize" | `.skills/wiki-setup/SKILL.md` |
| "ingest" / "add this to the wiki" | `.skills/wiki-ingest/SKILL.md` |
| "/wiki-history-ingest claude\|codex\|hermes\|openclaw" | `.skills/wiki-history-ingest/SKILL.md` |
| "import my Claude history" / "mine my conversations" | `.skills/claude-history-ingest/SKILL.md` |
| "import my Codex history" | `.skills/codex-history-ingest/SKILL.md` |
| "import my Hermes history" | `.skills/hermes-history-ingest/SKILL.md` |
| "import my OpenClaw history" | `.skills/openclaw-history-ingest/SKILL.md` |
| "process this export" / "ingest this data" | `.skills/data-ingest/SKILL.md` |
| "ingest this URL" / "/ingest-url <url>" | `.skills/ingest-url/SKILL.md` |
| "what's the status" / "show the delta" | `.skills/wiki-status/SKILL.md` |
| "what do I know about X" / any question | `.skills/wiki-query/SKILL.md` |
| "audit" / "lint" / "find broken links" | `.skills/wiki-lint/SKILL.md` |
| "rebuild" / "archive" / "restore" | `.skills/wiki-rebuild/SKILL.md` |
| "link my pages" / "cross-reference" | `.skills/cross-linker/SKILL.md` |
| "fix my tags" / "normalize tags" | `.skills/tag-taxonomy/SKILL.md` |
| "update wiki" / "sync to wiki" | `.skills/wiki-update/SKILL.md` |
| "export wiki" / "export graph" | `.skills/wiki-export/SKILL.md` |
| "create a new skill" | `.skills/skill-creator/SKILL.md` |

## Key Rules

- **Compile, don't retrieve** — update existing pages, don't append or duplicate.
- **Track everything** — update `wiki/_manifest.json`, `wiki/_master-index.md`, `wiki/_log.md` after every operation.
- **Connect with `[[wikilinks]]`** — every page should link to related pages.
- **Logseq properties required** — every page needs `title::`, `category::`, `tags::`, `summary::`, `created::`, `updated::` — NEVER YAML frontmatter.
- **Read-only sources** — never modify `pages/`, `journals/`, `assets/`, `logseq/`.

For full context, read `AGENTS.md` at the repo root.
