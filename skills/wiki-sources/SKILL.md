---
name: wiki-sources
description: Scout authoritative, high-quality sources for a topic and store them as a catalogue in raw/. A pre-ingest research shortlist — not linked to concept notes or thesaurus.
when_to_use: Use before ingesting sources when you want to discover what's worth reading first, or when the user says "find sources", "what should I read about", "catalogue sources", "scout sources", or "research sources for".
argument-hint: <topic>
---

# wiki-sources

Scout authoritative, high-quality sources for a topic. Fetches a brief preview of
each candidate, evaluates quality, and stores the results as a catalogue file in
`raw/`. The catalogue is a pre-ingest shortlist — use it to drive future
`/wiki-ingest` calls.

## Usage

```
/wiki-sources <topic>
```

`<topic>` is required. Be as specific or as broad as the research need warrants.

## Steps

### 1. Search for candidate sources

Run multiple targeted web searches to surface authoritative material. Vary the
queries to cover different source types:

- Foundational / seminal: `"<topic>" seminal paper OR foundational work`
- Academic: `"<topic>" research paper OR study site:arxiv.org OR site:scholar.google.com`
- Survey / overview: `"<topic>" survey OR review OR overview 2023 OR 2024 OR 2025`
- Technical depth: `"<topic>" tutorial OR guide OR explained site:distill.pub`
- Books / long-form: `"<topic>" textbook OR book OR handbook`

Adjust queries to the domain:
- Scientific/academic topics → prioritize arxiv, PubMed, Nature, Science, ACM, IEEE
- Technical/engineering → prioritize official docs, RFCs, IETF, well-known engineering blogs
- Humanities/philosophy → prioritize SEP (Stanford Encyclopedia of Philosophy), JSTOR, Oxford
- General → prioritize reputable publications (The Atlantic, Quanta, Aeon, LWN, etc.)

Aim for **8–15 unique candidate URLs** before moving to evaluation.

### 2. Fetch and evaluate each candidate

For each candidate URL, use the WebFetch tool to retrieve the page. Extract:

- **Title** — the document's actual title, not the search snippet
- **Author / Venue** — author name(s), journal, conference, publication, or institution
- **Type** — one of: `paper`, `article`, `book`, `video`, `doc`, `note`
- **Abstract or opening** — the abstract if present, otherwise the first substantive
  paragraph (not navigation, not boilerplate). 2–4 sentences maximum.

Evaluate each source against these criteria:

| Criterion | What to look for |
|---|---|
| Authority | Author credentials or institutional affiliation; peer-reviewed venue; primary source |
| Depth | Covers mechanisms and reasoning, not just surface-level description |
| Relevance | Directly addresses the topic and is unlikely to be superseded by another entry |
| Accessibility | Fetchable content (skip hard paywalls if a clearly better open alternative exists) |
| Recency | Recent for fast-moving domains; classics are fine for foundational topics |

Discard weak candidates (thin content, broken links, low-authority sources). Keep
the strongest **5–12 sources** — fewer is better if quality is high.

### 3. Generate slug

Create a slug from the topic:
- Lowercase
- Replace spaces and special characters with hyphens
- Remove consecutive hyphens
- Truncate to 60 characters

Example: "attention mechanisms in transformers" → `attention-mechanisms-in-transformers`

### 4. Store catalogue

Read `skills/wiki-sources/templates/catalogue.md.template`. Fill in every placeholder:

| Placeholder | Value |
|---|---|
| `{{TOPIC}}` | Topic as provided by the user |
| `{{DATE}}` | Today's date in YYYY-MM-DD format |
| `{{SOURCE_ENTRIES}}` | Rendered source entries (see template for entry format) |

Render `{{SOURCE_ENTRIES}}` as a sequence of entries, one per source, separated by
a horizontal rule (`---`). Each entry follows this format:

```markdown
## <Title>

- **URL:** <url>
- **Type:** <paper | article | book | video | doc | note>
- **Author / Venue:** <author name(s), journal or publication>

**Abstract / Opening:**
> <2–4 sentence abstract or first substantive paragraph, verbatim or lightly trimmed>

**Why authoritative:** <1–2 sentences on credibility and value for this topic>

`/wiki-ingest <url>`

---
```

Write the filled template to `raw/catalogue-<slug>.md`.

### 5. Report

Tell the user:
- How many sources were catalogued and stored at which path
- A brief breakdown by type (e.g. "4 papers, 3 articles, 2 docs")
- The suggested next step

Example:
```
Catalogued 9 sources for 'attention mechanisms in transformers'.
Stored `raw/catalogue-attention-mechanisms-in-transformers.md`.

Found: 5 papers, 3 articles, 1 book.

To start ingesting: `/wiki-ingest <url>`
```
