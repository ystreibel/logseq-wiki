---
name: logseq-codex-history-ingest
description: >
  Ingest Codex CLI conversation history into the Logseq wiki. Use this skill when the user wants to mine
  their past Codex sessions for knowledge, import their ~/.codex folder, extract insights from previous coding
  sessions, or says things like "process my Codex history", "add my Codex conversations to the wiki", or
  "what have I discussed in Codex before". Also triggers when the user mentions .codex sessions, rollout files,
  session_index.jsonl, or Codex transcript logs.
---

# Codex History Ingest — Conversation Mining for Logseq

**REQUIRED:** Invoke `logseq-llm-wiki` skill first for Logseq syntax and file format rules.

You are extracting knowledge from the user's past Codex sessions and distilling it into the Logseq wiki. Session logs are rich but noisy: focus on durable knowledge, not operational telemetry.

This skill can be invoked directly or via the `logseq-history-ingest` router (`/logseq-history-ingest codex`).

## Before You Start

1. Read `~/.logseq-wiki/config` to get `LOGSEQ_VAULT_PATH` and `CODEX_HISTORY_PATH` (default to `~/.codex` if unset)
2. Read `wiki/_manifest.json` at the vault root to check what has already been ingested
3. Read `wiki/_master-index.md` at the vault root to understand what the wiki already contains

## Ingest Modes

### Append Mode (default)

Check `wiki/_manifest.json` for each source file. Only process:

- Files not in the manifest (new session rollouts, new index files)
- Files whose modification time is newer than `ingested_at` in the manifest

Use this mode for regular syncs.

### Full Mode

Process everything regardless of manifest. Use after `logseq-rebuild` or if the user explicitly asks for a full re-ingest.

## Codex Data Layout

Codex stores local artifacts under `~/.codex/`.

```
~/.codex/
├── sessions/                          # Session rollout logs by date
│   └── YYYY/MM/DD/
│       └── rollout-<timestamp>-<id>.jsonl
├── archived_sessions/                 # Archived rollout logs
├── session_index.jsonl                # Lightweight index of thread id/name/updated_at
├── history.jsonl                      # Local transcript history (if persistence enabled)
├── config.toml                        # User config (contains history settings)
└── state_*.sqlite / logs_*.sqlite     # Runtime DBs (usually skip)
```

### Key data sources ranked by value

1. `session_index.jsonl` — best inventory source for IDs, titles, and freshness
2. `sessions/**/rollout-*.jsonl` — rich structured transcript events
3. `history.jsonl` — useful fallback/timeline aid if enabled

Avoid ingesting SQLite internals unless the user explicitly asks.

## Step 1: Survey and Compute Delta

Scan `CODEX_HISTORY_PATH` and compare against `wiki/_manifest.json`:

- `~/.codex/session_index.jsonl`
- `~/.codex/sessions/**/rollout-*.jsonl`
- `~/.codex/archived_sessions/**` (optional; only if user asks for archived history)
- `~/.codex/history.jsonl` (optional fallback)

Classify each file:

- **New** — not in manifest
- **Modified** — in manifest but file is newer than `ingested_at`
- **Unchanged** — already ingested and unchanged

Report a concise delta summary before deep parsing.

## Step 2: Parse Session Index First

`session_index.jsonl` typically has entries like:

```json
{"id":"...","thread_name":"...","updated_at":"..."}
```

Use it to:

- Build a canonical session inventory
- Prioritize recent/high-signal sessions
- Map rollout IDs to human-readable thread names

## Step 3: Parse Rollout JSONL Safely

Each `rollout-*.jsonl` line is an event envelope with:

```json
{
  "timestamp": "...",
  "type": "session_meta|turn_context|event_msg|response_item",
  "payload": { ... }
}
```

### Extraction rules

- Prioritize user intent and assistant-visible outputs
- Favor `response_item` records with user/assistant message content
- Use `event_msg` selectively for meaningful milestones; ignore pure telemetry
- Treat `session_meta` as metadata (cwd, model, ids), not user knowledge

### Skip/noise filters

- Token accounting events
- Tool plumbing with no semantic content
- Raw command output unless it contains reusable decisions/patterns
- Repeated plan snapshots unless they add novel decisions

### Critical privacy filter

Rollout logs can include injected instructions, tool payloads, and sensitive text.

- Remove API keys, tokens, passwords, credentials
- Redact private identifiers unless relevant and approved
- Summarize instead of quoting raw transcripts

## Step 4: Cluster by Topic

Do not create one wiki page per session.

- Group by stable topics across many sessions
- Split mixed sessions into separate themes
- Merge recurring concepts across dates/projects
- Use `cwd` from metadata to infer project scope

## Step 5: Distill into Wiki Pages (Logseq Format)

Route extracted knowledge into the correct vault namespaces:

- Project-specific architecture/process → `wiki/projects/<name>/`
- General concepts → `wiki/concepts/`
- Recurring techniques/debug playbooks → `wiki/skills/`
- Tools/services → `wiki/entities/`
- Cross-session patterns → `wiki/synthesis/`

For each impacted project, create/update `wiki/projects/<name>/<name>.md`.

### Logseq Properties Format

```markdown
title:: Page Title
tags:: concept, codex, debugging
summary:: Ce que cette page documente en 1–2 phrases. ^[inferred]
provenance:: Synthèse de N sessions Codex (inferred)
category:: concept
```

**Règles d'écriture :**
- Logseq properties `::` en tête — jamais de YAML frontmatter
- `[[wiki/thème/page]]` pour tous les liens internes
- `summary::` obligatoire sur chaque page (≤200 chars)
- `^[inferred]` pour les synthèses, `^[ambiguous]` pour les contradictions
- Langue : **français**

## Step 6: Update Manifest and Special Files

### Update `wiki/_manifest.json`

For each processed source file:

```json
{
  "ingested_at": "TIMESTAMP",
  "size_bytes": 0,
  "modified_at": "TIMESTAMP",
  "source_type": "codex_rollout",
  "project": "project-name-or-null",
  "pages_created": [],
  "pages_updated": []
}
```

`source_type` values: `codex_rollout` | `codex_index` | `codex_history`

Also update the top-level project block:

```json
{
  "project-name": {
    "source_path": "~/.codex/sessions/...",
    "last_ingested": "TIMESTAMP",
    "sessions_ingested": 12,
    "sessions_total": 40,
    "index_updated_at": "TIMESTAMP"
  }
}
```

### Update `wiki/_log.md`

```
- [TIMESTAMP] CODEX_HISTORY_INGEST sessions=N pages_updated=X pages_created=Y mode=append|full
```

## Privacy and Compliance

- Distill and synthesize; avoid raw transcript dumps
- Default to redaction for anything that looks sensitive
- Ask the user before storing personal/sensitive details
- Keep references to other people minimal and purpose-bound
