---
name: wiki-stage-commit
description: >
  Review and promote staged wiki pages to their final locations. Use when WIKI_STAGED_WRITES=true
  and the user says "/wiki-stage-commit", "review staged pages", "commit staged writes",
  "promote staged pages", "approve staged changes", or "what's waiting in staging".
  Shows each staged file, lets the user accept or reject it, and moves accepted files to
  their final wiki locations. Rejected files are moved back to wiki/_raw/ for manual editing.
---

# Wiki Stage Commit — Staged Write Promotion

You are reviewing LLM-written pages that are waiting in `wiki/_staging/` for human approval before they land in the live wiki. This skill is only useful when `WIKI_STAGED_WRITES=true` in the vault config.

## Before You Start

1. **Resolve config** — read `~/.logseq-wiki/config` first, then `.env` as fallback. This gives `LOGSEQ_VAULT_PATH` and `WIKI_STAGED_WRITES`.
2. If `WIKI_STAGED_WRITES` is not set or is `false`, tell the user: "Staged writes mode is not enabled. Set `WIKI_STAGED_WRITES=true` in your config to use this feature." Then stop.
3. Read the `wiki/_staging/` directory inventory.

## Invocation Forms

```
/wiki-stage-commit               # interactive review: show each file and ask accept/reject
/wiki-stage-commit --all         # accept all staged files without per-file review
/wiki-stage-commit --reject-all  # reject all staged files (move to wiki/_raw/ for manual editing)
/wiki-stage-commit --list        # list staged files with summary, no changes
```

## Step 1: Inventory Staged Files

Glob `$LOGSEQ_VAULT_PATH/wiki/_staging/**/*.md` — these are the pending pages.

Also glob `$LOGSEQ_VAULT_PATH/wiki/_staging/**/*.patch.md` — these are pending *updates* to existing pages (diff-style files showing proposed additions and deletions).

Report the inventory:

```
Staged files: 4 new pages, 2 updates

New pages:
  wiki/_staging/ia/attention-mechanism.md        (ingested 2 days ago)
  wiki/_staging/personnes/andrej-karpathy.md     (ingested 2 days ago)
  wiki/_staging/pratiques/fine-tuning-llms.md    (ingested yesterday)
  wiki/_staging/références/attention-is-all-you-need.md (ingested 3 hours ago)

Updates (patch files):
  wiki/_staging/ia/transformer-architecture.patch.md  (target: wiki/ia/transformer-architecture.md)
  wiki/_staging/pratiques/prompt-engineering.patch.md (target: wiki/pratiques/prompt-engineering.md)
```

If `wiki/_staging/` is empty, report: "Nothing staged. All writes have been committed or no staged writes have been produced yet."

## Step 2: Per-File Review (interactive mode)

For each staged file (new pages first, then updates):

### For new pages:

Display a summary using Logseq property syntax:

```
--- New page: wiki/ia/attention-mechanism.md ---
title::    Attention Mechanism
tags::     #ml #architecture
summary::  Core building block of transformers — computes weighted sum of values based on query-key similarity.
tier::     supporting
confidence:: 0.72
sources::  [[références/attention-is-all-you-need]]

[Preview first 20 lines of body]
...

Accept [a], Reject [r], Skip [s], Preview full [p]?
```

### For patch files:

Display a structured diff:

```
--- Update: wiki/ia/transformer-architecture.md ---
Source: wiki/_staging/ia/transformer-architecture.patch.md

Proposed additions (+):
+ Transformers outperform RNNs on tasks requiring long-range dependencies. ^[inferred]
+ New source: [[références/survey-2026]]

Proposed deletions (-):
- The attention mechanism was first described in [Bahdanau 2015].  (to be replaced by updated claim)

⚠️  Conflict check: target page was modified 3 days after staging. Review carefully.

Accept [a], Reject [r], Skip [s], Preview full diff [p]?
```

If `--all` flag is set, skip prompting and accept every file.
If `--reject-all` flag is set, skip prompting and reject every file.
If `--list` flag is set, stop after printing the inventory (Step 1).

## Step 3: Apply Decisions

### Accepting a new page

1. Move `wiki/_staging/<thème>/page.md` → `wiki/<thème>/page.md` (the final location)
2. Update `wiki/_master-index.md` with the new page entry
3. Remove the staged file

### Accepting a patch/update

1. Read the current page at the target path
2. Apply the proposed additions and deletions (merge, don't just overwrite)
3. Update the `updated::` Logseq property timestamp
4. Update `wiki/_master-index.md` if the summary changed
5. Remove the staged patch file

### Rejecting a file

Move it to `$LOGSEQ_VAULT_PATH/wiki/_raw/` for manual editing:
- `wiki/_staging/<thème>/page.md` → `$LOGSEQ_VAULT_PATH/wiki/_raw/rejected-<thème>-page.md`
- `wiki/_staging/<thème>/page.patch.md` → `$LOGSEQ_VAULT_PATH/wiki/_raw/rejected-patch-<thème>-page.md`
- Prefix with `rejected-` so the user can identify it

### Conflict detection on patch accept

Before applying a patch, check whether the target page's `updated::` Logseq property is newer than the patch file's own `updated::` field:
- If the target was modified AFTER the patch was staged, warn: `⚠️ Conflict: target was updated since this patch was staged. Applying may lose recent changes.`
- Give the user a chance to abort: `Apply anyway [y], Skip [s], Reject [r]?`

## Step 4: Update Tracking Files

After processing all staged files:

1. **`wiki/_hot.md`** — update the Recent Activity section: "Committed N staged pages; rejected M."
2. **`wiki/_log.md`** — append:
   ```
   - [TIMESTAMP] STAGE_COMMIT accepted=N rejected=M skipped=K
   ```

## Step 5: Report

```
Stage commit complete.

✅  Accepted (N):
  wiki/ia/attention-mechanism.md             → now live
  wiki/personnes/andrej-karpathy.md          → now live
  wiki/ia/transformer-architecture.md        → updated (patch applied)

❌  Rejected (M):
  wiki/pratiques/fine-tuning-llms.md         → moved to wiki/_raw/rejected-pratiques-fine-tuning-llms.md

⏭️  Skipped (K):
  wiki/références/attention-is-all-you-need.md → still in wiki/_staging/

Staging queue: K files remaining
```

## Notes

- Staged files use the same page template as live pages (Logseq property syntax `::`, no YAML frontmatter) — they are ready to land, just awaiting approval
- Patch files use a human-readable diff format: lines starting with `+` are additions, lines starting with `-` are deletions
- `wiki/_master-index.md` and `wiki/_log.md` are always updated immediately on ingest (they are low-risk tracking files) — only theme pages go through staging
- The `wiki/_staging/` directory is not tracked by Logseq's graph view — pages only appear in the wiki graph after promotion to `wiki/<thème>/page.md`
- Themes are free-form under `wiki/[thème]/` — adapt examples to the actual themes in use (e.g. `ia/`, `personnes/`, `pratiques/`, `références/`, `projets/`)
