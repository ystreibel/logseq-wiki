---
name: logseq-history-ingest
description: >
  Unified entry point for ingesting conversation/session history into the Logseq wiki.
  Use when the user says "/logseq-history-ingest claude" or asks to ingest agent history.
  Routes to the specialized history skill.
---

# Logseq History Ingest — Router

This is a thin router for **history sources only**. It does not replace `logseq-ingest` for documents.

## Subcommands

If the user invokes `/logseq-history-ingest <target>` (or equivalent text command), dispatch directly:

| Subcommand | Route To |
|---|---|
| `claude` | `logseq-claude-history-ingest` |
| `auto` | infer from context using rules below |

## Routing Rules

1. If the user explicitly says `claude`, route directly to `logseq-claude-history-ingest`.
2. If the user provides a path/source:
   - `~/.claude` or Claude memory/session JSONL artifacts -> `logseq-claude-history-ingest`
3. If ambiguous, ask one short clarification:
   - "Should I ingest `claude` history?"

## Execution Contract

- After routing, execute the destination skill's workflow exactly.
- Do not duplicate destination logic in this file.
- Leave manifest/index/log update semantics to the destination skill.

## UX Convention

- Use `logseq-ingest` for **documents/content sources**
- Use `logseq-history-ingest` for **agent history sources**

Examples:

- `/logseq-history-ingest claude`
- `$logseq-history-ingest claude` (agents that use `$skill` invocation)
