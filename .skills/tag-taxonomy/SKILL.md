---
name: tag-taxonomy
description: >
  Enforce consistent tagging across the Logseq wiki. Use when the user says "fix my tags",
  "normalize tags", "clean up tags", "tag audit", "tag taxonomy", or whenever creating/updating
  wiki pages. Always consult this skill before assigning tags to any wiki page.
---

# Tag Taxonomy — Controlled Vocabulary for Logseq Wiki Tags

You are enforcing consistent tagging across the Logseq wiki by normalizing tags to a controlled vocabulary.

## Before You Start

**REQUIRED:** Invoke `llm-wiki` skill first for Logseq syntax and file format rules.

1. Read `~/.logseq-wiki/config` to get `WIKI_PATH` (usually `./wiki`)
2. Read `$WIKI_PATH/_meta/taxonomy.md` — this is the canonical tag list
3. Read `index.md` to understand the wiki's scope

## The Taxonomy File

The canonical tag vocabulary lives at `wiki/_meta/taxonomy.md`. It defines:

- **Canonical tags** — the tags that should be used
- **Aliases** — common alternatives that should be mapped to the canonical form
- **Rules** — max 5 tags per page, lowercase/hyphenated, prefer broad over narrow
- **Migration guide** — specific renames for known inconsistencies

**Always read this file before tagging.** It's the source of truth.

### Initial Taxonomy Creation

If `wiki/_meta/taxonomy.md` does not exist, create it with this Logseq format:

```
title:: Taxonomie — Tags Contrôlés
category:: meta
tags:: taxonomy, wiki, meta
summary:: Vocabulaire contrôlé de tags pour le wiki Logseq.
created:: YYYY-MM-DD
updated:: YYYY-MM-DD

# Taxonomie des Tags

## Règles
- Maximum 5 tags par page (hors tags de visibilité)
- Minuscules et tirets uniquement : `mon-tag` pas `MonTag`
- Préférer large à spécifique : `kubernetes` pas `kubernetes-3488`
- Les tags `visibility/public`, `visibility/internal`, `visibility/pii` sont réservés

## Tags canoniques

| Tag | Usage |
|---|---|
| index | Pages _index.md |
| wiki | Pages méta du wiki |
| log | Fichiers de log |
| meta | Fichiers de configuration wiki |

## Alias → Canonique

| Alias | Canonique |
|---|---|
| k8s | kubernetes |
| js | javascript |
```

## Reserved System Tags

`visibility/` is a reserved tag group with special rules. These tags are **not** domain or type tags and are managed separately from the taxonomy vocabulary:

| Tag | Purpose |
|---|---|
| `visibility/public` | Explicitly public — shown in all modes (same as no tag) |
| `visibility/internal` | Team-only — excluded in filtered query/export mode |
| `visibility/pii` | Sensitive data — excluded in filtered query/export mode |

**Rules for `visibility/` tags:**
- They do **not** count toward the 5-tag limit
- Only one `visibility/` tag per page
- Omit entirely when content is clearly public — no tag needed
- Never add `visibility/internal` just because content is technical; use it only for genuinely team-restricted knowledge
- When running a tag audit, report `visibility/` tag usage separately — do not flag them as unknown or non-canonical

When normalizing tags, leave `visibility/` tags untouched — they are not subject to alias mapping.

## Mode 1: Tag Audit

When the user wants to see the current state of tags:

### Step 1: Scan all pages

```
Glob: wiki/**/*.md (excluding _archive/, _meta/)
Extract: tags:: property from Logseq frontmatter (comma-separated values)
```

Example Logseq tag syntax:
```
tags:: kubernetes, devops, infrastructure
```

Not YAML syntax (which is Obsidian):
```yaml
tags: [kubernetes, devops, infrastructure]
```

### Step 2: Build a tag frequency table

For each tag found, count how many pages use it. Flag:

- **Unknown tags** — not in the taxonomy's canonical list
- **Alias tags** — using an alias instead of the canonical form (e.g., `nextjs` instead of `react`)
- **Over-tagged pages** — pages with more than 5 tags (excluding `visibility/` tags)
- **Untagged pages** — pages with no tags or empty tags field

### Step 3: Report

```markdown
## Tag Audit Report

### Summary

- Total unique tags: 47
- Canonical tags used: 32
- Non-canonical tags found: 15
- Pages over tag limit (5): 3
- Untagged pages: 2

### Non-Canonical Tags Found

| Current Tag | → Canonical | Pages Affected |
| ----------- | ----------- | -------------- |
| `nextjs`    | `react`     | 4              |
| `next-js`   | `react`     | 2              |
| `robotics`  | `ml`        | 1              |
| `windows98` | `retro`     | 3              |

### Unknown Tags (not in taxonomy)

| Tag          | Pages | Recommendation                   |
| ------------ | ----- | -------------------------------- |
| `flutter`    | 1     | Add to taxonomy under Frameworks |
| `kubernetes` | 2     | Add to taxonomy under DevOps     |

### Over-Tagged Pages

| Page                   | Tag Count | Tags                 |
| ---------------------- | --------- | -------------------- |
| `wiki/personnes/jane-doe.md` | 8    | ai, ml, founder, ... |
```

## Mode 2: Tag Normalization

When the user wants to fix the tags:

### Step 1: Run audit (above)

### Step 2: Apply fixes

For each page with non-canonical tags:

1. Read the page
2. Replace alias tags with their canonical form from the taxonomy (using `tags::` Logseq syntax)
3. If page has > 5 tags, suggest which to drop (keep the most specific/relevant ones)
4. Write the updated frontmatter

**Example:**

```
# Before
tags:: nextjs, ai, ml-engineer, windows98, creative-coding, game, 8-bit, portfolio

# After
tags:: react, ai, ml, retro, generative-art
```

### Step 3: Handle unknowns

For tags that aren't in the taxonomy and aren't aliases:

- If the tag is used on 2+ pages, suggest adding it to the taxonomy
- If the tag is used on 1 page, suggest replacing it with the closest canonical tag
- Ask the user before making changes to unknown tags

### Step 4: Update taxonomy

If new canonical tags were agreed upon, append them to `wiki/_meta/taxonomy.md` in the correct section.

## Mode 3: Tagging a New Page

When you're creating a wiki page and need to choose tags:

1. Read `wiki/_meta/taxonomy.md`
2. Select up to 5 tags that best describe the page:
   - 1-2 **domain tags** (what subject area)
   - 1 **type tag** (what kind of thing)
   - 0-1 **project tags** (if project-specific)
   - 0-1 additional descriptive tags
3. Use only canonical tags — never aliases
4. If no existing tag fits, check if it's worth adding to the taxonomy
5. Format tags using Logseq property syntax: `tags:: tag1, tag2, tag3`

## Mode 4: Adding a New Tag

When the user wants to add a tag to the vocabulary:

1. Check if an existing tag already covers the concept (suggest it if so)
2. If genuinely new, determine which section it belongs in (Domain, Type, Project)
3. Add it to `wiki/_meta/taxonomy.md` with:
   - The canonical tag name
   - What it's used for
   - Any aliases to redirect

## After Any Tag Operation

Append to `wiki/_log.md`:

```
- [TIMESTAMP] TAG_AUDIT tags_normalized=N unknown_tags=M pages_modified=P
```

Or for normalization:

```
- [TIMESTAMP] TAG_NORMALIZE tags_renamed=N pages_modified=M new_tags_added=P
```
