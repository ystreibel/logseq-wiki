---
alwaysApply: true
description: Logseq Wiki skill-based framework — routing, conventions, and core rules.
---

# Logseq Wiki — Agent Context

This project is a **skill-based framework** for building and maintaining a Logseq knowledge base.

## Quick Orientation

1. Read `~/.logseq-wiki/config` (or `.env` in this repo) for `LOGSEQ_VAULT_PATH` — this is where the Logseq vault lives.
2. Read `wiki/_manifest.json` inside the vault to see what's already been ingested.
3. Skills are in `.skills/` (also at `.agents/skills/`). Each subfolder has a `SKILL.md`.

## When to Use Skills

| User says something like… | Read this skill |
|---|---|
| "set up my wiki" / "initialize" | `wiki-setup` |
| "ingest" / "add this to the wiki" | `wiki-ingest` |
| "import my Claude history" / "mine my conversations" | `claude-history-ingest` |
| "import my Codex history" | `codex-history-ingest` |
| "import my Hermes history" | `hermes-history-ingest` |
| "import my OpenClaw history" | `openclaw-history-ingest` |
| "process this export" / "ingest this data" | `data-ingest` |
| "ingest this URL" / "/ingest-url <url>" | `ingest-url` |
| "what's the status" / "show the delta" | `wiki-status` |
| "what do I know about X" / any question | `wiki-query` |
| "audit" / "lint" / "find broken links" | `wiki-lint` |
| "rebuild" / "archive" / "restore" | `wiki-rebuild` |
| "link my pages" / "cross-reference" | `cross-linker` |
| "fix my tags" / "normalize tags" | `tag-taxonomy` |
| "update wiki" / "sync to wiki" | `wiki-update` |
| "export wiki" / "export graph" | `wiki-export` |

## Core Rules

- **Compile, don't retrieve** — update existing pages, don't append or duplicate.
- **Track everything** — update `wiki/_manifest.json`, `wiki/_master-index.md`, `wiki/_log.md` after every operation.
- **Connect with `[[wikilinks]]`** — every page should link to related pages.
- **Logseq properties required** — every page needs `title::`, `category::`, `tags::`, `summary::`, `created::`, `updated::` — NEVER YAML frontmatter.
- **Read-only sources** — never modify `pages/`, `journals/`, `assets/`, `logseq/`.

For full context, read `AGENTS.md` at the repo root.
