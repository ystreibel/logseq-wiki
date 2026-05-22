---
name: wiki-history-ingest
description: >
  Unified entry point for ingesting conversation/session history into the Logseq wiki.
  Use when the user says "/wiki-history-ingest claude|codex|hermes|openclaw|copilot|pi"
  or asks to ingest agent history. Routes to the specialized history skill.
---

# Logseq History Ingest — Router

This is a thin router for **history sources only**. It does not replace `wiki-ingest` for documents.

## Subcommands

If the user invokes `/wiki-history-ingest <target>` (or equivalent text command), dispatch directly:

| Subcommand | Route To |
|---|---|
| `claude` | `claude-history-ingest` |
| `codex` | `codex-history-ingest` |
| `hermes` | `hermes-history-ingest` |
| `openclaw` | `openclaw-history-ingest` |
| `copilot` | `copilot-history-ingest` |
| `pi` | `pi-history-ingest` |
| `auto` | infer from context using rules below |

## Routing Rules

1. If the user explicitly names an agent, route directly.
2. If the user provides a path/source:
   - `~/.claude` ou artefacts JSONL Claude → `claude-history-ingest`
   - `~/.codex` ou fichiers rollout Codex → `codex-history-ingest`
   - `~/.hermes` ou fichiers mémoire Hermes → `hermes-history-ingest`
   - `~/.openclaw` ou MEMORY.md OpenClaw → `openclaw-history-ingest`
   - `~/.copilot` ou `session-store.db` → `copilot-history-ingest`
   - `~/.pi/agent/sessions` ou fichiers JSONL Pi → `pi-history-ingest`
3. Si ambigu, poser une courte question de clarification :
   - "Quel historique agent ? `claude`, `codex`, `hermes`, `openclaw`, `copilot`, ou `pi` ?"

## Execution Contract

- After routing, execute the destination skill's workflow exactly.
- Do not duplicate destination logic in this file.
- Leave manifest/index/log update semantics to the destination skill.

## UX Convention

- Use `wiki-ingest` for **documents/content sources**
- Use `wiki-history-ingest` for **agent history sources**

Examples:

- `/wiki-history-ingest claude`
- `/wiki-history-ingest codex`
- `/wiki-history-ingest copilot`
- `/wiki-history-ingest pi`
