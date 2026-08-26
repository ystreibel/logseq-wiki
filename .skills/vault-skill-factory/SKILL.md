---
name: vault-skill-factory
description: >
  Turn a mature cluster of wiki pages into a portable, self-contained "expert" skill. Use when the
  user says "make a skill from my wiki", "turn these notes into a skill", "package my X knowledge as
  a skill", "create an expert skill from my vault", or when a wiki theme has grown dense enough to act
  as reusable expertise. Builds on skill-creator.
---

# Vault Skill Factory — Notes → Portable Skill

**REQUIRED:** Invoke llm-wiki first for Logseq syntax; this skill also builds on `skill-creator`.

Compile a dense cluster of wiki pages into a distributable skill: the accumulated knowledge becomes an
"expert" other agents can load, instead of re-querying the vault each time
(the "compile once, keep current" principle applied to expertise).

## Before You Start

1. Read `~/.logseq-wiki/config` (preferred) or `.env` to get `LOGSEQ_VAULT_PATH`
2. Read `wiki/_master-index.md` to see themes and page density
3. Identify the target cluster: a theme, or a hub page + its neighbors (use `wiki-status` hubs or ask the user)

## Step 1: Assess Maturity

A cluster is skill-ready only if it is substantial and stable:
- **≥ 4–5 interconnected pages** on the topic (check density with the graph, excluding `_index`)
- Pages carry real distilled knowledge (facts, decisions, patterns), not mostly `TODO`/stubs
- Content is stable (not actively churning). If the cluster is thin or volatile, **say so and stop** —
  suggest more ingestion first rather than packaging premature knowledge.

## Step 2: Extract the Expertise

From the cluster, distill into skill material:
- **Scope** — what the expert knows and when it applies
- **Core facts & patterns** — the reusable knowledge (not vault-specific navigation)
- **Decision rules / heuristics** the pages encode
- **Pointers** back to the source pages `[[wiki/theme/page]]` for provenance
- Preserve `^[inferred]`/`^[ambiguous]` — an expert states its confidence

Strip anything vault-private that should not travel (personal notes, internal identifiers) unless the
user wants an internal-only skill.

## Step 3: Generate the Skill

**Invoke the `skill-creator` skill** to produce the new skill (it owns the authoring workflow, evals
and validation — do not hand-roll the SKILL.md structure). Pass it:
- `name`: a clear, hyphenated expert name (e.g. `gcp-architecture-expert`)
- `description`: third-person "Use when…" triggering conditions only (no workflow summary)
- Body: the distilled expertise, with a "Sources" section linking the originating wiki pages
- Keep under ~500 lines; move heavy reference to supporting files

**Output location** — ask the user, defaulting to a **personal** skill so it follows them across
projects: `~/.claude/skills/<expert-name>/SKILL.md` (or the equivalent skills dir of the active agent:
`~/.codex/skills/`, `~/.gemini/skills/`, `~/.agents/skills/`). Only write it into this framework repo's
`.skills/` if the user explicitly wants it distributed with logseq-wiki. Never write it into the vault.

## Step 4: Record the Lineage

- **`wiki/_log.md`** — append: `- [ISO8601] SKILL-FACTORY — <expert-name> built from wiki/<theme> (<N> pages)`
- Optionally add a note on the source cluster's `_index.md` pointing to the generated skill, so the
  wiki and the skill stay linked (re-run the factory when the cluster evolves).

## Quality Checklist

- [ ] Cluster maturity assessed (≥4–5 real pages, stable) — premature clusters refused
- [ ] Expertise distilled, not raw pages copied
- [ ] Vault-private content stripped unless internal skill requested
- [ ] Skill produced via skill-creator with a triggers-only description
- [ ] Source pages linked in the skill's Sources section
- [ ] Lineage logged
