---
name: wiki-narrate
description: >
  Produce a developed, cited briefing on a transversal topic from the Logseq wiki — a long
  structured exposé, not a short answer. Use when the user says "brief me on X", "fais-moi un
  briefing sur", "un exposé complet sur", "tell me everything I know about X", "narrate",
  "synthèse développée sur", "walk me through what my wiki says about". For a short answer to a
  pointed question, use wiki-query instead. Works from any project.
---

# Wiki Narrate — Developed Briefing

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

## narrate ≠ query

| | wiki-query | wiki-narrate |
|---|---|---|
| Question | closed, pointed | open, transversal topic |
| Output | minimal answer (a few lines) + 1–2 sources | long structured exposé, narrative arc, abundant citations |
| Method | grep → read targeted pages → answer | aggregate many pages, rebuild a thread, surface tensions and gaps |

A briefing is not a padded query: it **makes the pages talk to each other** instead of juxtaposing them.
Read-only by default.

## Before You Start

1. Resolve config — read `~/.logseq-wiki/config` first (cross-project); fall back to `.env`. Gives `LOGSEQ_VAULT_PATH`.
2. If `wiki/_hot.md` exists, read it first for recent-activity context.
3. Read `wiki/_master-index.md` to understand scope and themes.

## Step 1: Gather (multi-angle sweep)

Do not stop at the first batch:
- **Broad, multilingual grep** on bodies + `tags::`: the term plus FR/EN synonyms (e.g. "AI/IA/LLM/agents")
- **`tags::` overlap** to find the core pages
- **Transitive link-following** through `[[wiki/...]]` (the `## Related` / `## Liens` sections) to widen scope
- **Classify core / context / false positives** from the grep — explicitly drop off-topic hits
- **Trace back to original sources**: `sources::` points into `pages/` (namespace encoded `___`:
  `[[web/x]]` = file `pages/web___x.md`, `[[videos/x]]` = `pages/videos___x.md`). For a briefing,
  open at least the core pages' sources to verify a number or pull an exact quote before asserting it.

Respect the **Retrieval Primitives** table in `llm-wiki` — cheapest primitive first, escalate only when needed.

## Step 2: Structure the Exposé

A narrative plan that links the pages, not one-section-per-page:
1. **Executive summary** (2–3 sentences: the transversal message)
2. **Thesis** — the thread that unifies the pages
3. **Thematic sections** (by angle, not by page) with transitions
4. **Cross-page synthesis**: make sources talk — agreements and contrasts. A contradiction between
   two pages becomes a paragraph of analysis, not an inconvenience.
5. **Conclusion + gaps**: what the wiki does not yet say
6. **Bibliography** at the end

## Step 3: Cite at Two Levels

- **Wiki page**: `[[wiki/theme/page]]` (navigation inside the second brain)
- **Original source**: the page's `sources::` — `[[web/<slug>]]` / `[[videos/<slug>]]` — with the
  attribution found in the body (author, outlet, date)
- Anchor every quantified claim to its page; list everything at the end (wiki pages + primary sources)

## Step 4: Preserve Uncertainty

Do not smooth over the wiki's provenance markers:
- `^[inferred]` → present as a deduction, not a sourced fact
- `^[ambiguous]` → flag the uncertainty (e.g. names garbled by auto-transcription)
- Contradictions between pages → surface them as analytical content
- `TODO`/gaps → note them in the gaps section

## Step 5: Language and Output

- Answer in the **user's language** (French if the vault is in French)
- **No writes** by default: the briefing is rendered in the conversation. On explicit request, it may be
  saved to the day's journal `journals/YYYY_MM_DD.md` — never a wiki page (a briefing is not an ingested source)

## Quality Checklist

- [ ] Output is a developed exposé (narrative plan), not a short query-style answer
- [ ] Pages made to dialogue (agreements/contrasts), not juxtaposed
- [ ] Two-level citation: wiki page `[[wiki/...]]` AND original source `[[web/...]]`/`[[videos/...]]`
- [ ] `^[inferred]`/`^[ambiguous]` preserved and flagged
- [ ] `___` conversion applied when tracing sources
- [ ] Read-only; save only on request, to the journal
