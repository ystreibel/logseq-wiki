---
name: logseq-wiki
description: Logseq wiki workflows — query, update, ingest, lint, status.
commands:
  - name: wiki-query
    description: Answer questions from the compiled Logseq wiki with [[wikilink]] citations.
    skill: .skills/wiki-query/SKILL.md
  - name: wiki-update
    description: Sync the current project's knowledge into the Logseq wiki.
    skill: .skills/wiki-update/SKILL.md
  - name: wiki-ingest
    description: Ingest documents into the Logseq wiki.
    skill: .skills/wiki-ingest/SKILL.md
  - name: wiki-status
    description: Show what's been ingested, what's pending, and the delta.
    skill: .skills/wiki-status/SKILL.md
  - name: wiki-lint
    description: Audit the wiki for orphans, broken links, stale content.
    skill: .skills/wiki-lint/SKILL.md
  - name: wiki-rebuild
    description: Archive the current wiki and rebuild from scratch.
    skill: .skills/wiki-rebuild/SKILL.md
  - name: wiki-export
    description: Export the wiki knowledge graph to JSON, GraphML, or HTML.
    skill: .skills/wiki-export/SKILL.md
  - name: wiki-history-ingest
    description: Ingest agent conversation history (claude, codex, hermes, openclaw).
    skill: .skills/wiki-history-ingest/SKILL.md
---

# Logseq Wiki — Workflow Registry

Each command above maps to a `SKILL.md` in `.skills/`. When a user invokes one
of these commands, read the mapped skill file and follow its instructions
exactly. The skills handle vault path resolution, manifest tracking, and
`[[wikilink]]` connectivity on their own.

For the full routing table (all 19 skills), see `AGENTS.md` at the repo root.
