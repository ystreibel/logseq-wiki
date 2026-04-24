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
| `codex` | `logseq-codex-history-ingest` |
| `hermes` | `logseq-hermes-history-ingest` |
| `openclaw` | `logseq-openclaw-history-ingest` |
| `auto` | infer from context using rules below |

## Routing Rules

1. If the user explicitly names an agent (`claude`, `codex`, `hermes`, `openclaw`), route directly.
2. If the user provides a path/source:
   - `~/.claude` or Claude memory/session JSONL artifacts → `logseq-claude-history-ingest`
   - `~/.codex` or Codex rollout/session files → `logseq-codex-history-ingest`
   - `~/.hermes` or Hermes memory/session files → `logseq-hermes-history-ingest`
   - `~/.openclaw` or OpenClaw MEMORY.md/session files → `logseq-openclaw-history-ingest`
3. If ambiguous, ask one short clarification:
   - "Which agent history? `claude`, `codex`, `hermes`, or `openclaw`?"

## Execution Contract

- After routing, execute the destination skill's workflow exactly.
- Do not duplicate destination logic in this file.
- Leave manifest/index/log update semantics to the destination skill.

## UX Convention

- Use `logseq-ingest` for **documents/content sources**
- Use `logseq-history-ingest` for **agent history sources**

Examples:

- `/logseq-history-ingest claude`
- `/logseq-history-ingest codex`
- `/logseq-history-ingest hermes`
- `/logseq-history-ingest openclaw`
- `$logseq-history-ingest claude` (agents that use `$skill` invocation)
