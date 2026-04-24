# logseq-wiki

A skill-based framework for building and maintaining a Logseq knowledge base with LLMs.

Inspired by [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — instead of asking an LLM the same questions over and over (or doing RAG every time), you compile knowledge once into interconnected pages and keep them current. In this case Logseq is the viewer and the LLM is the maintainer.

We took that pattern and built a framework around it for Logseq. The whole thing is a set of markdown skill files that any AI coding agent (Claude Code, Cursor, Windsurf, whatever you use) can read and execute. You point it at your Logseq graph and tell it what to do.

## Quick Start

### Install via Skills CLI (recommended)

```bash
npx skills add <github-user>/logseq-wiki
```

This installs all wiki skills into your current agent (Claude Code, Cursor, Codex, etc.). Then open your agent and say **"set up my wiki"**.

### Install via git clone

```bash
git clone https://github.com/<github-user>/logseq-wiki.git
cd logseq-wiki
bash setup.sh
```

`setup.sh` asks for your vault path, writes the config to `~/.logseq-wiki/config`, symlinks skills into all your agents, and installs `wiki-update` globally so you can use it from any project.

`LOGSEQ_VAULT_PATH` is any Logseq graph directory you want your wiki documents to live in. It can be a new empty folder or an existing Logseq graph.

Open the project in your agent and say **"set up my wiki"**. That's it.

## Skills

Everything lives in `.skills/`. Each skill is a markdown file the agent reads when triggered:

| Skill                        | What it does                                                             | Slash Command                                      |
| ---------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------- |
| `wiki-setup`               | Initialize vault structure                                               | `/wiki-setup`                                    |
| `wiki-ingest`              | Distill documents into wiki pages                                        | `/wiki-ingest`                                   |
| `ingest-url`          | Ingest a URL into the wiki                                               | `/ingest-url`                               |
| `wiki-history-ingest`      | Unified history router (`claude`, `codex`, `hermes`, `openclaw`)         | `/wiki-history-ingest <agent>`                   |
| `claude-history-ingest` | Mine your `~/.claude` conversations and memories                       | `/claude-history-ingest`                    |
| `codex-history-ingest` | Mine your `~/.codex` sessions and rollouts                              | `/codex-history-ingest`                     |
| `hermes-history-ingest` | Mine your `~/.hermes` memories and sessions                            | `/hermes-history-ingest`                    |
| `openclaw-history-ingest` | Mine your `~/.openclaw` MEMORY.md and sessions                       | `/openclaw-history-ingest`                  |
| `data-ingest`         | Ingest any text — chat exports, logs, transcripts                        | `/data-ingest`                              |
| `wiki-status`              | Show what's ingested, what's pending, the delta                          | `/wiki-status`                                   |
| `wiki-rebuild`             | Archive, rebuild from scratch, or restore                                | `/wiki-rebuild`                                  |
| `wiki-query`               | Answer questions from the wiki                                           | `/wiki-query`                                    |
| `wiki-lint`                | Find broken links, orphans, contradictions                               | `/wiki-lint`                                     |
| `cross-linker`        | Auto-discover and insert missing page links                              | `/cross-linker`                             |
| `tag-taxonomy`        | Enforce consistent tag vocabulary across pages                           | `/tag-taxonomy`                             |
| `llm-wiki`            | The core pattern and architecture reference                              | `/llm-wiki`                                 |
| `wiki-update`              | Sync current project's knowledge into the vault                          | `/wiki-update`                                   |
| `wiki-export`              | Export vault graph to JSON, GraphML, Neo4j, HTML                         | `/wiki-export`                                   |
| `skill-creator`              | Create new skills                                                        | `/skill-creator`                                   |

> **Note:** Slash commands (`/skill-name`) work in Claude Code, Cursor, and Windsurf. In other agents, just describe what you want and the agent will find the right skill.

## Agent Compatibility

This framework works with **any AI coding agent** that can read files. The `setup.sh` script automatically configures skill discovery for each one:

| Agent                                                     | Bootstrap Files                                                           | Skills Directory                                    | Slash Commands                                                    |
| --------------------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------- |
| **[Claude Code](https://claude.ai/code)**                 | `CLAUDE.md`                                                               | `.claude/skills/` + `~/.claude/skills/` (portable)  | `/wiki-ingest`, `/wiki-status`, etc.                          |
| **[Cursor](https://cursor.com)**                          | `.cursor/rules/logseq-wiki.mdc`                                           | `.cursor/skills/`                                   | `/wiki-ingest`, `/wiki-status`, etc.                          |
| **[Windsurf](https://windsurf.com)**                      | `.windsurf/rules/logseq-wiki.md`                                          | `.windsurf/skills/`                                 | via Cascade                                                       |
| **[Codex (OpenAI)](https://openai.com/codex)**            | `AGENTS.md`                                                               | `~/.codex/skills/`                                  | `$wiki-ingest` (Codex uses `$`)                                 |
| **[Gemini CLI](https://github.com/google-gemini/gemini-cli)** | `GEMINI.md`                                                           | `~/.gemini/skills/`                                 | `/wiki-ingest`, `/wiki-query`, etc.                           |
| **[Google Antigravity](https://antigravity.google)**      | `.agent/rules/logseq-wiki.md` + `.agent/workflows/logseq-wiki.md`         | `.agents/skills/` + `~/.gemini/antigravity/skills/` | slash commands via workflows registry                             |
| **[Kiro IDE/CLI](https://kiro.dev)**                      | `.kiro/steering/logseq-wiki.md` (`inclusion: always`)                     | `.kiro/skills/` + `~/.kiro/skills/`                 | `/wiki-ingest`, `/wiki-status`, etc.                          |
| **[Hermes (NousResearch)](https://hermes-agent.nousresearch.com)** | `.hermes.md` (→ `AGENTS.md`)                                    | `~/.hermes/skills/`                                 | `/wiki-history-ingest hermes`, etc.                             |
| **[OpenClaw](https://openclaw.ai)**                       | `AGENTS.md`                                                               | `~/.openclaw/skills/` + `~/.agents/skills/`         | `/wiki-ingest`, `/wiki-history-ingest openclaw`, etc.         |
| **[OpenCode](https://opencode.ai)**                       | `AGENTS.md`                                                               | `~/.agents/skills/`                                 | `/wiki-ingest`, `/wiki-query`, etc.                           |
| **[Aider](https://aider.chat)**                           | `AGENTS.md`                                                               | `~/.agents/skills/`                                 | Describe intent in chat — Aider reads the skill it needs          |
| **[Factory Droid](https://factory.ai)**                   | `AGENTS.md`                                                               | `~/.agents/skills/`                                 | `/wiki-ingest`, `/wiki-query`, etc.                           |
| **[Trae](https://trae.ai)**                               | `AGENTS.md`                                                               | `~/.trae/skills/`                                   | via Agent tool                                                    |
| **Trae CN**                                               | `AGENTS.md`                                                               | `~/.trae-cn/skills/`                                | via Agent tool                                                    |
| **GitHub Copilot (VS Code Chat)**                         | `.github/copilot-instructions.md`                                         | —                                                   | Describe intent in chat                                           |
| **GitHub Copilot (CLI)**                                  | —                                                                         | `~/.copilot/skills/`                                | `/wiki-ingest`, `/wiki-query`, etc.                           |
| **[Kilocode](https://kilo.ai/)**                          | `AGENTS.md` (primary) or `CLAUDE.md` (compatibility)                      | `.agents/skills/` + `.claude/skills/`               | `/wiki-ingest`, `/wiki-status`, etc.                          |

> **How it works:** Each agent has its own convention for discovering skills. `setup.sh` symlinks the canonical `.skills/` directory into each agent's expected location, and creates the bootstrap file that tells the agent about the project. You write skills once, every agent can use them.

## Differences from obsidian-wiki

This framework is a Logseq-native adaptation of [obsidian-wiki](https://github.com/Ar9av/obsidian-wiki). The core pattern is the same — ingest, extract, resolve, evolve — but the format and structure match Logseq conventions:

### Page format

Logseq uses **property syntax** instead of YAML frontmatter:

```
title:: My Page Title
tags:: concept, architecture
summary:: A brief description of this page.
```

No YAML front matter (`---` delimiters). Properties sit at the top of the page as `key:: value` pairs, which Logseq reads natively.

### Vault structure

Logseq vaults have a fixed layout. The framework only writes into `wiki/` — everything else is read-only:

```
$LOGSEQ_VAULT_PATH/
├── pages/              # Your notes (READ ONLY)
├── journals/           # Daily notes YYYY_MM_DD.md (READ ONLY)
├── assets/             # Images and attachments (READ ONLY)
├── logseq/             # Logseq app config — do not touch (READ ONLY)
└── wiki/               # Generated wiki — only directory written by the framework
    ├── _master-index.md   # Auto-maintained catalog
    ├── _manifest.json     # Ingest tracking ledger
    ├── _log.md            # Chronological operation log
    ├── _meta/
    │   └── taxonomy.md    # Controlled tag vocabulary
    ├── _archive/          # Snapshots for rebuild/restore
    └── [thème]/           # One subdirectory per theme (detected from pages/)
        ├── _index.md
        └── [page].md
```

Journal pages (`journals/`) are treated as **read-only source material** — the framework ingests knowledge from them but never writes there. All generated pages go under `wiki/`.

### Links

Logseq uses **namespace links** rather than flat wikilinks:

```
[[wiki/concepts/stale-closure]]
[[wiki/entities/react]]
```

The `wiki/` prefix makes it clear which pages were generated by this framework vs. your hand-written notes. Page names with `/` create Logseq namespaces, which show up as a tree in the left sidebar.

### Configuration

- Config file: `~/.logseq-wiki/config` (written by `setup.sh`)
- Required env var: `LOGSEQ_VAULT_PATH` (path to your Logseq graph directory)
- Optional: `CLAUDE_HISTORY_PATH` (defaults to `~/.claude`)

### What you can ingest

| Source | Skill | What it reads |
|---|---|---|
| Markdown, PDFs, text files | `wiki-ingest` | Any document directory |
| Logseq pages | `wiki-ingest` | `pages/` directory of your graph |
| Logseq journals | `wiki-ingest` | `journals/` — read as source material |
| Logseq assets | `wiki-ingest` | Images, PDFs in `assets/` |
| Claude Code history | `claude-history-ingest` | `~/.claude/` — conversations, memories, sessions |
| Codex history | `codex-history-ingest` | `~/.codex/` — rollout JSONL, session index |
| Hermes history | `hermes-history-ingest` | `~/.hermes/` — memories, session transcripts |
| OpenClaw history | `openclaw-history-ingest` | `~/.openclaw/` — MEMORY.md, daily notes, sessions |
| ChatGPT exports | `data-ingest` | `conversations.json` from ChatGPT export |
| Slack / Discord logs | `data-ingest` | Channel export JSON files |
| Meeting transcripts | `data-ingest` | Any text transcript |
| Raw text dumps | `data-ingest` | Anything — CSV, logs, journals, notes |
| URLs | `ingest-url` | Any web page |

## How it works

Every ingest runs through four stages:

**1. Ingest** — The agent reads your source material directly. It handles markdown files, PDFs, JSONL conversation exports, plain text logs, chat exports, meeting transcripts, and images. No preprocessing step, no pipeline to run.

**2. Extract** — From the raw source, the agent pulls out concepts, entities, claims, relationships, and open questions. Noise gets dropped, signal gets kept. Each page also gets a 1–2 sentence `summary::` property at write time — later queries use this to preview pages without opening them.

**3. Resolve** — New knowledge gets merged against what's already in the wiki. If a concept page exists, the agent updates it. If it's genuinely new, a page gets created. Nothing is duplicated. Sources are tracked so every claim stays attributable.

**4. Schema** — The wiki schema isn't fixed upfront. It emerges from your sources and evolves as you add more. The agent maintains coherence: namespaces stay consistent, links point to real pages, the index reflects what's actually there.

A `.manifest.json` tracks every source that's been ingested — path, timestamps, which wiki pages it produced. On the next ingest, the agent computes the delta and only processes what's new or changed.

## Contributing

This is early. The skills work but there's a lot of room to make them smarter. PRs are welcome.

### Adding a new skill

1. Create a folder in `.skills/your-skill-name/`
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and markdown instructions
3. Run `bash setup.sh` to symlink into all agent directories
4. Test with your agent by saying something that matches the description

See `.skills/skill-creator/SKILL.md` for the full guide on writing effective skills.
