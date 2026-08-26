---
name: wiki-query
description: >
  Answer questions by searching the compiled Logseq wiki. Use this skill when the user asks a question
  about their knowledge base, wants to find information across their wiki, asks "qu'est-ce que X",
  "trouve", "que sais-je sur", "find everything related to Y", or wants synthesized answers with
  citations from their wiki pages. Also use when the user wants to explore connections between topics
  in their wiki. Works from any project.
  Includes an index-only fast mode triggered by "quick answer", "just scan", "don't read the pages",
  "réponse rapide", "juste un aperçu", "sans lire les pages" — returns answers from page summaries
  and frontmatter without reading page bodies.
---

# Wiki Query — Interrogation du vault Logseq

**REQUIRED:** Invoke llm-wiki skill first for Logseq syntax and file format rules.

You are answering questions against a compiled Logseq wiki, not raw source documents. The wiki contains pre-synthesized, cross-referenced knowledge.

## Before You Start

1. **Resolve config** — read `~/.logseq-wiki/config` first (works cross-project); fall back to `.env` in the logseq-wiki repo. This gives `LOGSEQ_VAULT_PATH`.
2. If `$LOGSEQ_VAULT_PATH/wiki/_hot.md` exists, read it first — it gives instant context on recent activity. If the user's question is about something ingested recently, `_hot.md` may answer it before you even open `_master-index.md`.
3. Read `$LOGSEQ_VAULT_PATH/wiki/_master-index.md` to understand the wiki's scope and structure.

## Visibility Filter (optional)

By default, **all pages are returned** regardless of visibility tags. This preserves existing behavior — nothing changes unless the user asks for it.

If the user's query includes phrases like **"public only"**, **"user-facing"**, **"no internal content"**, **"as a user would see it"**, or **"exclude internal"**, activate **filtered mode**:

- Build a **blocked tag set**: `{visibility/internal, visibility/pii}`
- In the Index Pass (Step 2), skip any candidate whose `tags::` property contains a blocked tag
- In Section/Full Read passes (Steps 3–4), do not read or cite any blocked page
- Synthesize the answer **only from allowed pages** — do not mention that excluded pages exist

Pages with no `visibility/` tag, or tagged `visibility/public`, are always included.

In filtered mode, note the filter in the Step 6 log entry: `mode=filtered`.

## Retrieval Protocol

**Follow the Retrieval Primitives table in `llm-wiki/SKILL.md`.** Reading is the dominant cost of this skill — use the cheapest primitive that answers the question and escalate only when it can't. Never jump straight to full-page reads.

### Step 1: Understand the Question

Classify the query type:
- **Factual lookup** — "What is X?" / "Qu'est-ce que X ?" → Find the relevant page(s)
- **Relationship query** — "How does X relate to Y?" / "What contradicts X?" → Find both pages, their cross-references, and their `relationships::` property for typed edges
- **Synthesis query** — "What's the current thinking on X?" / "Résume tout ce que je sais sur X" → Find all pages that touch X, synthesize
- **Gap query** — "What don't I know about X?" → Find what's missing, check open questions sections
- **Decision** ("qu'a-t-on décidé sur X ?") → search wiki pages + journals
- **Temporal** ("que s'est-il passé en avril ?") → search journals by period

Also decide the **mode**:
- **Index-only mode** — triggered by "quick answer", "just scan", "don't read the pages", "fast lookup", "réponse rapide", "juste un aperçu", "sans lire les pages". Stops at Step 3. Answers from property fields + `_master-index.md` only.
- **Normal mode** — the full tiered pipeline below.

### Step 2: Index Pass (cheap)

**First, extract clean search terms from the question:**
- Strip trailing punctuation glued to a word — "que sais-je sur mise ?" → term `mise`, never `mise?` (which matches nothing)
- Drop interrogatives and stop-words (que, quoi, sur, le, la, what, about…)
- Grep **case-insensitively** (`-i`); if a term has accents, also try the unaccented variant (vaults in French: "déploiement" / "deploiement")
- For a concept, grep the stem rather than the inflected form ("certif" catches "certification", "certifications")

Build a candidate set *without opening any page bodies*:

- You've already read `_master-index.md` above — use it as the first filter. It lists every page with a one-line description and tags.
- Use `Grep` to scan page **properties only** for title, tag, and summary matches. A pattern like `^(title|tags|summary)::` scoped to `wiki/` `.md` files is far cheaper than content grep.
- Collect the top 5–10 candidate page paths ranked by:
  1. Exact title match
  2. Tag match
  3. `summary::` field contains the query term
  4. `_master-index.md` entry contains the query term
- **Apply tier ordering within each rank bucket:** when two candidates score equally, prefer `tier:: core` over `tier:: supporting` over `tier:: peripheral`. Read the `tier::` property with the same cheap grep as other fields. Pages without a `tier::` field are treated as `supporting`.

If you're in **index-only mode**, stop here. Answer from `summary::` fields, titles, and `_master-index.md` descriptions only. Label the answer clearly: **"(index-only answer — page bodies not read; facts below are from page summaries and may miss nuance)"**. Then skip to Step 5.

### Step 3: Section Pass (medium cost — only if Step 2 is inconclusive)

For each of the top candidates, pull the relevant section *without reading the whole page*:

- Use `Grep -A 10 -B 2 "<query-term>" <candidate-file>` to get just the lines around the match.
- This usually returns 15–30 lines per hit instead of 100–500.
- If the section grep gives a clear answer, go straight to Step 5.

If Step 2 wiki results are insufficient, also grep `pages/` and `journals/`:
```
Grep pattern=[key terms] path=pages/ output_mode=files_with_matches
Grep pattern=[key terms] path=journals/ output_mode=files_with_matches
```
Take the 5 most recent or most relevant files.

### Step 4: Full Read (expensive — last resort)

Only when Steps 2 and 3 don't answer the question:

- `Read` the top **3** candidates in full. When choosing which 3 to read, apply tier ordering: read `core` pages before `supporting`, and skip `peripheral` pages unless they are the only match.
- Follow at most one hop of `[[wiki/thème/page]]` links from those pages if the answer requires cross-references.
- **For relationship queries** ("How does X relate to Y?" / "What contradicts X?"): also read the `relationships::` property of the candidate pages. Each entry gives a typed, directional edge (`extends`, `implements`, `contradicts`, `derived_from`, `uses`, `replaces`, `related_to`). Surface these explicitly in your answer — "Page A *contradicts* Page B (typed edge)" is more useful than "Page A links to Page B".
- Check "Open Questions" sections for known gaps.
- If you're still short, **then** fall back to a broad content grep across the vault. **Tell the user you escalated** — this is the expensive path and they should know.

### Step 5: Synthesize an Answer

Compose your answer from wiki content:
- Répondre en français, de façon synthétique
- Cite specific wiki pages using `[[wiki/thème/page]]` notation
- Note which step the answer came from ("found in summary" vs "grepped section" vs "full page read") — helps the user understand confidence
- If the wiki has contradictions, present both sides
- If the wiki doesn't cover something, say so explicitly
- Suggest which sources might fill the gap
- Si aucune information trouvée : le dire et suggérer "ingère mon vault" si le wiki est vide

**Page trust annotations:** For every page cited in your answer, check its `lifecycle::` property and compute `is_stale = (today − updated::) > 90 days`. Annotate risky pages inline so the user knows which citations to verify:

| Condition | Annotation |
|---|---|
| `lifecycle:: archived` | `(ARCHIVED: superseded by [[wiki/thème/page]])` — use the successor instead |
| `lifecycle:: disputed` | `(DISPUTED, marked <lifecycle_changed::>: <lifecycle_reason:: or "reason unspecified">)` |
| `is_stale` + `lifecycle:: verified` | `(VERIFIED but stale: last updated <updated::>)` — reader should re-verify before relying |
| `is_stale` (other lifecycle) | `(stale: last updated <updated::>)` |

Examples in a synthesized answer:
```
[[wiki/tech/concept-page]] (stale: last updated 2026-01-15) — Original claim was X.
[[wiki/tech/verified-page]] (VERIFIED but stale: last updated 2025-09-10) — Reader should reverify before relying.
[[wiki/projets/disputed-page]] (DISPUTED, marked 2026-04-30: contradicted by [[wiki/tech/new-source]]) — Earlier said Y, now uncertain.
[[wiki/tech/old-page]] (ARCHIVED: superseded by [[wiki/tech/new-page]]) — Use the successor.
```

Pages with no `lifecycle::` field (legacy pages predating the schema) are treated the same as `draft` — annotate if stale, skip otherwise. Never fabricate a `lifecycle_reason`; if the field is absent, omit the reason from the annotation.

### Step 6: Log the Query

Append to `wiki/_log.md`:
```
- [TIMESTAMP] QUERY query="the user's question" result_pages=N mode=normal|index_only|filtered escalated=true|false
```

## Answer Format

Structure answers like this:

> **Basé sur le wiki :**
>
> [Your synthesized answer with [[wiki/thème/page]] links to source pages]
>
> **Pages consultées :** [[wiki/thème/page-a]], [[wiki/thème/page-b]], [[wiki/thème/page-c]]
>
> **Lacunes :** [What the wiki doesn't cover that might be relevant]
