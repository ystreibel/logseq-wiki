---
name: cross-linker
description: >
  Scan the Logseq wiki and automatically discover missing cross-references between pages.
  Use this skill when the user says "tisse les liens", "ajoute les liens manquants",
  "connecte mon wiki", "liens wiki", "pages non connectées", "cross-link", "link my pages",
  "find missing links", "cross-reference", "add wikilinks", "what pages should be linked",
  or after any large ingestion to ensure new pages are woven into the existing knowledge graph.
  Also trigger when the user mentions "orphan pages" in the context of wanting to connect them,
  or says things like "my wiki feels disconnected" or "pages aren't linked well".
  This is a write-heavy skill — it actually modifies pages to add links, unlike wiki-lint
  which just reports issues.
---

# Cross-Linker — Tissage automatique des liens wiki

You are weaving the wiki's knowledge graph tighter by finding and inserting missing `[[wikilinks]]` between pages that should reference each other but currently don't.

**Follow the Retrieval Primitives table in `llm-wiki/SKILL.md`.** Build the registry in Step 1 by grepping properties only (not full pages). Reserve full `Read` for the unlinked-mention detection pass, and even there, only read pages whose summaries/titles make them plausible link targets. Blind full-vault reads are what this framework exists to avoid.

## Before You Start

1. **Resolve config** — read `~/.logseq-wiki/config` first (contains `LOGSEQ_VAULT_PATH`); fall back to `.env` in the logseq-wiki repo if the global config is absent. Prompt setup if neither exists.
2. Read `$LOGSEQ_VAULT_PATH/wiki/_master-index.md` to get the full inventory of pages and their one-line descriptions.
3. Skim `$LOGSEQ_VAULT_PATH/wiki/_log.md` to see what was recently ingested (focus linking effort on new pages).

## Step 1: Build the Page Registry

Glob all `.md` files under `$LOGSEQ_VAULT_PATH/wiki/` (excluding `wiki/_archive/`). For each page, extract:

- **Filename** (without `.md`) — this is the wikilink target
- **Title** from `title::` property
- **Aliases** from `aliases::` property (if any)
- **Tags** from `tags::` property
- **Category** from directory inference
- **One-line summary** — first sentence or `summary::` property

Build a lookup table:

```
page_name → { path, title, aliases, tags, summary }
```

This is your "vocabulary" — every entry in this table is a valid wikilink target.

## Step 2: Scan for Missing Links

For each page in the vault:

1. **Read the full content**
2. **Extract existing wikilinks** — find all `[[...]]` references already present
3. **Search for unlinked mentions** — check if the page's text contains any of these, without being wrapped in `[[...]]`:
   - Page filenames (e.g., the word "MyProject" appears but `[[wiki/projects/my-project]]` is missing)
   - Page titles from `title::` property
   - Aliases from `aliases::` property
   - Entity names, project names, concept names from the registry

4. **Check for semantic connections** — pages that share multiple tags or are in the same project directory but don't link to each other

### Matching Rules

- **Case-insensitive matching** for names (e.g., "my-project" matches page `MyProject`)
- **Diacritic-insensitive matching** — normalize both the page name and the body text with Unicode NFKD (decompose accented characters to base + combining marks, strip combining marks) before comparing. This ensures body text "Muller" matches page `[[wiki/entities/müller]]` and vice versa.
- **Skip self-references** — a page shouldn't link to itself
- **Skip common words** — don't link "the", "and", generic terms (le, la, un, de…). Only match on distinctive names (≥ 3 chars, non-generic)
- **Prefer the shortest unambiguous wikilink path** — use `[[wiki/thème/page]]` with the full namespace path (Logseq requires it for proper graph resolution)
- **Don't link inside code blocks** or Logseq property lines
- **Don't double-link** — if `[[wiki/foo/bar]]` already appears on the page, don't add another

## Step 3: Score and Rank Suggestions

Not every possible link is worth adding. Score each candidate using a composite signal, then tag it with a confidence label.

### Scoring

| Signal | Points | Example |
|---|---|---|
| **Exact name match in text** | +4 | "MyProject" appears in body text → link to `wiki/projects/my-project` |
| **Shared tags (2+)** | +2 | Both tagged `#ia #agent` but no link between them |
| **Same project, no link** | +2 | Both under `wiki/projects/my-project/` but don't reference each other |
| **Mentioned entity/concept** | +2 | Page mentions "knowledge graphs" → link to `[[wiki/concepts/knowledge-graphs]]` |
| **Cross-category connection** | +2 | Source is in `wiki/concepts/`, target is in `wiki/entities/` (or `wiki/skills/` ↔ `wiki/synthesis/`) — different knowledge layers make this link more architecturally valuable |
| **Peripheral→hub reach** | +2 | Source page has ≤ 2 total links (peripheral) but target has ≥ 8 (hub) — connecting a loose page to a load-bearing concept |
| **Partial name match** | +1 | "graph" appears but page is `knowledge-graphs` — plausible but ambiguous |

### Confidence labels

Tag each candidate with a confidence label based on its score:

| Score | Label | Action |
|---|---|---|
| ≥ 6 | **EXTRACTED** | Link is effectively certain — exact mention or very strong match. Apply inline. |
| 3–5 | **INFERRED** | Link is a reasonable inference — shared context, cross-category, peripheral→hub. Apply inline or as Related section. |
| 1–2 | **AMBIGUOUS** | Weak or partial match. Skip unless user specifically asks to connect loose pages. |

Only act on **EXTRACTED** and **INFERRED** candidates. Include the confidence label in the Cross-Link Report so the user can review INFERRED links before trusting them.

## Step 4: Apply Links

For each page with missing links:

### 4a: Inline linking (preferred)

Find the first natural mention of the term in the body text and wrap it in wikilinks:

**Before:**
```markdown
Ce projet utilise des knowledge graphs pour connecter les entités.
```

**After:**
```markdown
Ce projet utilise des [[wiki/concepts/knowledge-graphs|knowledge graphs]] pour connecter les entités.
```

Use the `[[wiki/thème/page|texte d'affichage]]` format when the wikilink path differs from the display text.

### 4b: Related section (fallback)

If the term isn't mentioned naturally in the body but the pages are semantically related (shared tags, same project), add a `## Liens` section at the bottom of the page:

```markdown
## Liens

- [[wiki/projects/my-project/my-project]] — Utilise aussi des agents IA pour l'automatisation
- [[wiki/concepts/knowledge-graphs]] — Technique centrale utilisée dans ce projet
```

If a `## Liens` or `## Related` section already exists, append to it. Don't duplicate existing entries.

### 4c: Infer and write relationship type

For every EXTRACTED or INFERRED link added (inline or related section), infer a semantic relationship type from the surrounding sentence context and write it to the page's `relationships::` Logseq property. Skip AMBIGUOUS links.

**Type inference rules** — scan the sentence containing the mention (or, for related-section links, the page title and shared-tag context):

| Sentence pattern | Inferred type |
|---|---|
| "X extends / builds on / generalises Y" | `extends` |
| "X implements / is an implementation of Y" | `implements` |
| "X contradicts / opposes / refutes / is at odds with Y" | `contradicts` |
| "X is derived from / based on / adapted from Y" | `derived_from` |
| "X uses / relies on / depends on / requires Y" | `uses` |
| "X replaces / supersedes / deprecates Y" | `replaces` |
| Shared tags or cross-category inference with no directional cue | `related_to` |

If the surrounding context is ambiguous or the link came from shared-tag matching (no in-body mention), default to `related_to`.

**Writing the property:**

Read the page's existing Logseq properties. If a `relationships::` property already exists, append new entries without duplicating existing targets. If the property is absent, add it after `tags::` (or after `summary::` when `tags::` is missing).

Format: inline Logseq property with comma-separated entries:

```
relationships:: [[wiki/concepts/knowledge-graphs]] (uses), [[wiki/entities/jane-doe]] (related_to)
```

Always use `[[wiki/thème/page]]` format for all targets in `relationships::`. This is the standard Logseq namespace wikilink format — there is no alternative link format in logseq-wiki.

Only add entries for links added in this cross-linker run — do not touch typed entries that were already present.

## Step 5: Score Misc Page Affinity

After the main linking pass, update affinity scores for all pages in `wiki/misc/` (pages located under the `wiki/misc/` directory or carrying `promotion_status:: misc` in their properties).

For each misc page:

1. **Collect outgoing links** — all `[[wikilinks]]` in the page body
2. **Collect incoming links** — grep the vault for `[[wiki/misc/<slug>]]` and `[[<slug>]]` references
3. For each linked page (both directions), check if it belongs to a project:
   - Lives under `wiki/projects/<project-name>/`
   - Has a `project::` property matching a project name
4. Group by project name and sum: `outgoing_links + incoming_links`
5. Update the `affinity::` Logseq property on the misc page:

```
affinity:: logseq-wiki: 3, another-project: 1
```

6. If any project's score ≥ 3: flag this page as a **promotion candidate** and record it for the report

**Efficiency note:** only read the full body of misc pages — other pages only need a property grep to determine their project membership.

## Step 6: Report

Present a summary:

```markdown
## Cross-Link Report

### Links Added: 23 across 12 pages

| Page | Links Added | Confidence | Placement | Relationship Types |
|---|---|---|---|---|
| `wiki/projects/my-project/my-project.md` | 3 | EXTRACTED | 2 inline, 1 related | uses ×2, related_to ×1 |
| `wiki/entities/jane-doe.md` | 5 | INFERRED | 3 inline, 2 related | extends ×1, uses ×3, related_to ×1 |
| ... | | | | |

### Orphan Pages Remaining: 2
- `wiki/references/foo.md` — no incoming or outgoing links found
- `wiki/concepts/bar.md` — could not find related pages

### Misc Promotion Candidates: N
Pages in wiki/misc/ that have ≥ 3 connections to a single project — ready to be promoted:

| Page | Top Project | Score |
|---|---|---|
| `wiki/misc/web-martinfowler-articles-microservices.md` | `logseq-wiki` | 4 |

To promote: move the page to `wiki/projects/<project-name>/references/` and update all backlinks.

### Pages Skipped: 3
- `wiki/_master-index.md`, `wiki/_log.md` — special files
- `wiki/_archive/*` — archived content
```

## Step 7: Update Log

Append to `$LOGSEQ_VAULT_PATH/wiki/_log.md`:
```
- [TIMESTAMP] CROSS_LINK pages_scanned=N links_added=M typed_relations_written=T pages_modified=P orphans_remaining=Q misc_affinity_updated=R promotion_candidates=S
```

## Tips

- **Run after every ingest.** New pages are almost always poorly connected. This is the fix.
- **Be conservative with inline links.** Only link the first natural mention, not every occurrence.
- **Don't touch pages in `wiki/_archive/`.** Those are frozen snapshots.
- **Respect existing structure.** If a page carefully curates its links in a `## Concepts clés` section, add to that section rather than creating a separate `## Liens`.
- **Entity pages are link magnets.** An entity like `jane-doe` should be linked from almost every project page. Prioritize these.
