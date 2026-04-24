# Logseq Wiki — Copilot Context

This project is a **skill-based framework** for building and maintaining a Logseq knowledge base using AI coding agents. There are no scripts or dependencies — everything is markdown instructions that the agent executes directly.

## Project Overview

- **Purpose:** Build and maintain a Logseq wiki using the LLM Wiki pattern (Andrej Karpathy).
- **Tech Stack:** Markdown only. No code, no dependencies. The AI agent IS the runtime.
- **Key Config:** `~/.logseq-wiki/config` (or `.env`) contains `LOGSEQ_VAULT_PATH` pointing to the Logseq vault.
- **Skills:** `.skills/` contains skill folders, each with a `SKILL.md` defining a workflow.

## Key Concepts

- The wiki is a **compiled artifact** — knowledge distilled from raw sources into interconnected pages.
- Every wiki page uses **Logseq property syntax**: `title::`, `category::`, `tags::`, `summary::`, `sources::`, `created::`, `updated::` — NEVER YAML frontmatter.
- Pages are connected with Logseq `[[wiki/thème/page]]` namespace links.
- `wiki/_manifest.json` tracks all ingested sources for delta-based updates.
- `wiki/_master-index.md` and `wiki/_log.md` must be updated after every operation.
- Logseq vault sources (`pages/`, `journals/`, `assets/`, `logseq/`) are **READ ONLY**.

## Skills Reference

| Skill | Folder | Purpose |
|---|---|---|
| LLM Wiki | `.skills/llm-wiki/` | Core architecture, Logseq syntax, manifest format |
| Setup | `.skills/wiki-setup/` | Initialize wiki structure in vault |
| Ingest | `.skills/wiki-ingest/` | Distill documents into wiki pages |
| Update | `.skills/wiki-update/` | Sync current project knowledge into wiki |
| Status | `.skills/wiki-status/` | Audit ingestion state and delta |
| Query | `.skills/wiki-query/` | Answer questions from wiki |
| Lint | `.skills/wiki-lint/` | Find broken links, orphans, stale content |
| Rebuild | `.skills/wiki-rebuild/` | Archive and rebuild from scratch |
| Export | `.skills/wiki-export/` | Export graph to JSON, GraphML, HTML |
| Cross-Linker | `.skills/cross-linker/` | Auto-discover and insert missing wikilinks |
| Tag Taxonomy | `.skills/tag-taxonomy/` | Enforce consistent tag vocabulary |
| Ingest URL | `.skills/ingest-url/` | Fetch and distill a web page |
| Data Ingest | `.skills/data-ingest/` | Process any text data (chat exports, logs, etc.) |
| History Router | `.skills/wiki-history-ingest/` | Route `/wiki-history-ingest <agent>` |
| Claude History | `.skills/claude-history-ingest/` | Mine `~/.claude` conversations |
| Codex History | `.skills/codex-history-ingest/` | Mine `~/.codex` sessions |
| Hermes History | `.skills/hermes-history-ingest/` | Mine `~/.hermes` memories |
| OpenClaw History | `.skills/openclaw-history-ingest/` | Mine `~/.openclaw` sessions |
| Skill Creator | `.skills/skill-creator/` | Create new skills |

## Logseq-Specific Rules

- Use `title:: value` syntax (double colon) — never `title: value` (YAML).
- Tags: `tags:: tag1, tag2` — plain text, comma-separated, never `[[wikilinks]]` or `#hashtags`.
- Journal format: `YYYY_MM_DD.md` (underscores, not hyphens).
- Wiki lives at `$LOGSEQ_VAULT_PATH/wiki/` — never write outside this directory.
- Themes are detected dynamically from `pages/` — never hardcode `concepts/`, `entities/`, etc.
