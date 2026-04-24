# Setup

A skill-based framework for AI coding agents — Claude Code, Cursor, Windsurf, Gemini CLI, Google Antigravity, Codex, Hermes, OpenClaw, OpenCode, Aider, Factory Droid, Trae / Trae CN, Kiro, GitHub Copilot (CLI + VS Code Chat) — to build and maintain a Logseq knowledge base using Karpathy's LLM Wiki pattern. No scripts, no API keys — the agent **is** the LLM.

> Running `bash setup.sh` wires up every supported agent: project-local skill symlinks (`.claude/skills/`, `.cursor/skills/`, `.windsurf/skills/`, `.agents/skills/`, `.kiro/skills/`), global symlinks (`~/.claude/skills/`, `~/.gemini/skills/`, `~/.codex/skills/`, `~/.hermes/skills/`, `~/.openclaw/skills/`, `~/.copilot/skills/`, `~/.trae/skills/`, `~/.trae-cn/skills/`, `~/.kiro/skills/`, `~/.agents/skills/`), and always-on rule files (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `.hermes.md`, `.cursor/rules/…`, `.windsurf/rules/…`, `.kiro/steering/…`, `.agent/rules/…`, `.agent/workflows/…`, `.github/copilot-instructions.md`). See the [Agent Compatibility table in README.md](README.md#agent-compatibility) for the full matrix.

## Quick Start

### 1. Set your vault path

```bash
cp .env.example .env
```

Open `.env` and set `LOGSEQ_VAULT_PATH` to your Logseq graph directory:

```
LOGSEQ_VAULT_PATH=/path/to/your/logseq/graph
```

That's the only required config.

### 2. Run setup

```bash
bash setup.sh
```

`setup.sh` asks for your vault path (if not already in `.env`), writes the config to `~/.logseq-wiki/config`, and symlinks skills into all your agents.

### 3. Point an agent at the skills

Open this project in your coding agent and tell it what you want:

| What you say | Skill triggered |
|---|---|
| "Set up my wiki" | `wiki-setup` |
| "Ingest my documents from ~/research" | `wiki-ingest` |
| "/wiki-history-ingest claude" | `wiki-history-ingest` |
| "Import my Claude history" | `claude-history-ingest` |
| "Process this ChatGPT export" | `data-ingest` |
| "Ingest this URL" | `ingest-url` |
| "What's the status of my wiki?" | `wiki-status` |
| "What do I know about X?" | `wiki-query` |
| "Audit my wiki" | `wiki-lint` |
| "Rebuild from scratch" | `wiki-rebuild` |

The agent reads the skills from `.skills/`, reads `.env` for your vault path, and does the work.

### 4. Open in Logseq

Open your vault directory in Logseq: **☰ (hamburger menu) → Open folder**, then select your `LOGSEQ_VAULT_PATH`. The wiki pages, namespace links, and graph view all work natively.

## What Can It Ingest?

Anything text-based:

| Source | Skill | What it reads |
|---|---|---|
| Markdown, PDFs, text files | `wiki-ingest` | Any document directory |
| Logseq pages | `wiki-ingest` | `pages/` directory of your graph |
| Logseq journals | `wiki-ingest` | `journals/` — read as source material, never written |
| Logseq assets | `wiki-ingest` | Images, PDFs in `assets/` |
| URLs | `ingest-url` | Any web page |
| Claude Code history | `claude-history-ingest` | `~/.claude/` — conversations, memories, sessions |
| ChatGPT exports | `data-ingest` | `conversations.json` from ChatGPT export |
| Slack / Discord logs | `data-ingest` | Channel export JSON files |
| Meeting transcripts | `data-ingest` | Any text transcript |
| Raw text dumps | `data-ingest` | Anything — CSV, logs, journals, notes |

## Tracking & Delta

The framework tracks everything it ingests via `wiki/_manifest.json`. This enables:

- **Status view** — "What's been ingested? What's new? What's changed?"
- **Delta ingestion** — Only process new/modified sources, skip what's already in the wiki
- **Provenance** — Which source produced which wiki page
- **Staleness detection** — Source changed but wiki page hasn't been updated

### Typical workflow

```
"What's the status?"     → wiki-status computes the delta
"Ingest the new stuff"   → wiki-ingest processes only the delta (append mode)
"What's the status now?" → wiki-status confirms everything is up to date
```

### When things drift too far

```
"Archive and rebuild"    → wiki-rebuild archives current wiki to _archive/, clears, ready for fresh ingest
"Restore the old one"    → wiki-rebuild restores from a previous archive
```

Archives live at `wiki/_archive/YYYY-MM-DD/` with full snapshots. Nothing is ever lost.

## Vault Structure

```
$LOGSEQ_VAULT_PATH/
├── pages/              # Named pages — your hand-written notes (READ ONLY)
├── journals/           # Daily journal pages YYYY_MM_DD.md (READ ONLY)
├── assets/             # Images and attachments (READ ONLY)
├── logseq/             # Logseq app config — do not touch (READ ONLY)
└── wiki/               # Generated wiki — only directory the agent writes to
    ├── _master-index.md   # Auto-maintained catalog of all wiki pages
    ├── _manifest.json     # Ingest tracking ledger
    ├── _log.md            # Chronological operation log
    ├── _meta/
    │   └── taxonomy.md    # Controlled tag vocabulary
    ├── _archive/          # Wiki snapshots for rebuild/restore
    └── [thème]/           # One subdirectory per theme
        ├── _index.md      # Theme index
        └── [page].md      # Wiki pages
```

Pages generated by the framework live under `wiki/[thème]/` (e.g. `wiki/kubernetes/capsule.md`). Links use Logseq namespace syntax: `[[wiki/kubernetes/capsule]]`. Journal pages (`journals/`) are treated as read-only source material — the framework ingests knowledge from them but never writes there.

## Optional Config

| Variable | What it does | Default |
|---|---|---|
| `LOGSEQ_VAULT_PATH` | Path to your Logseq graph directory | *(required)* |
| `LOGSEQ_SOURCES_DIR` | Directories with docs to ingest (comma-separated) | *(empty — point agent at specific files)* |
| *(no LOGSEQ_CATEGORIES)* | Themes are detected dynamically from `pages/` — not configured upfront | — |
| `LOGSEQ_MAX_PAGES_PER_INGEST` | Max pages updated per ingest | `15` |
| `CLAUDE_HISTORY_PATH` | Where to find Claude data | *auto-discovers from `~/.claude`* |
| `LINT_SCHEDULE` | Wiki health check frequency | `weekly` |

## Skills Reference

| Skill | Purpose |
|---|---|
| `llm-wiki` | Core pattern — 3-layer architecture, page templates, project org |
| `wiki-setup` | Initialize vault structure, create index/log, configure namespaces |
| `wiki-ingest` | Distill source documents into wiki pages (append or full mode) |
| `ingest-url` | Ingest a URL directly into the wiki |
| `wiki-history-ingest` | Unified history ingest router (`claude` or other agents) |
| `claude-history-ingest` | Mine `~/.claude` conversations and memories into wiki pages |
| `data-ingest` | Ingest any raw text — chat exports, logs, transcripts, anything |
| `wiki-status` | Audit: what's ingested, what's pending, delta, recommend action |
| `wiki-rebuild` | Archive current wiki, rebuild from scratch, or restore from archive |
| `wiki-query` | Answer questions from the compiled wiki with citations |
| `wiki-lint` | Find orphans, broken links, stale content, contradictions |
| `cross-linker` | Auto-discover and insert missing namespace links |
| `tag-taxonomy` | Enforce consistent tag vocabulary across pages |
| `wiki-update` | Sync current project's knowledge into the vault (works from any project) |
| `wiki-export` | Export vault graph to JSON, GraphML, Neo4j, HTML |
| `skill-creator` | Create new skills to extend the framework |

## How It Works

No scripts, no dependencies. The skills are markdown files that tell an AI agent *how* to operate on your Logseq vault:

1. Agent reads `.env` for vault path
2. Agent reads `.manifest.json` to know what's already been done
3. Agent reads the relevant skill for instructions
4. Agent uses its built-in tools (read, write, search) to do the work
5. Agent updates `.manifest.json` to track what it did
6. Output is Logseq-compatible markdown with `key:: value` properties and `[[namespace/page]]` links

**The wiki is the artifact. The agent is the maintainer. Logseq is the viewer.**

## Using from Other Projects

The whole point is that your wiki should stay up to date as you work across different codebases. `setup.sh` installs two global skills that work from any project: `wiki-update` and `wiki-query`.

After running `bash setup.sh`:

1. Config is written to `~/.logseq-wiki/config` with your vault path
2. `wiki-update` and `wiki-query` are symlinked into `~/.claude/skills/` (and other agent global paths)

Then from any project:

```bash
cd ~/projects/my-cool-app
claude

# Write to the wiki: distill what you've learned
> /wiki-update

# Read from the wiki: pull context about anything you've captured before
> /wiki-query what do I know about rate limiting?
```

## Extending

Want a new workflow? Use the `skill-creator` skill:

> "Create a skill that generates weekly summaries from my journal entries"

It walks you through drafting, testing, and refining a new skill in `.skills/`.
