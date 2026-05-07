---
name: wiki-query
description: Query the wiki knowledge base. Returns a structured answer drawn from concept notes, thesaurus terms, and syntheses, with source references and flagged gaps where knowledge is missing.
when_to_use: Use when the user asks a question about the wiki topic, wants to look something up in the wiki, or says "query", "search wiki", "what does the wiki say about", or "find in wiki".
argument-hint: <question>
---

# wiki-query

Query the wiki knowledge base. Returns a structured answer drawn from concept notes,
thesaurus terms, and syntheses, with source references and gap flagging.

## Usage

```
/wiki-query <question>
```

## Steps

### 1. Extract key terms

Identify 2–5 key terms from the question. Generate kebab-case slugs for each
(e.g. "self attention" → `self-attention`).

### 2. Search concept notes

For each key term:
```bash
grep -ril "<term>" wiki/concepts/ 2>/dev/null
```

Collect all matching files. Also check filenames directly: if `wiki/concepts/<term-slug>.md`
exists, include it even if grep missed it.

### 3. Expand via thesaurus

For each key term, check if a thesaurus entry exists:
```bash
grep -ril "<term>" wiki/thesaurus/ 2>/dev/null
```

If a thesaurus entry is found, read its `aliases:`, `broader:`, `narrower:`, and
`related:` fields. Run the concept note search again for each of those terms.
This surfaces related knowledge the user may not have named explicitly.

### 4. Search syntheses

```bash
grep -ril "<term>" wiki/syntheses/ 2>/dev/null
```

### 5. Compose answer

Read all matching files. Write a direct answer to the question using only content
from the wiki. Structure:

```markdown
## Answer
<Direct answer to the question, 2–5 sentences. No fabrication — only what the wiki contains.>

## From the Wiki
- [[concept-slug]]: <one-line summary of the relevant content in that note>
- [[concept-slug]]: <one-line summary>

## Sources
- [[raw/source-slug]]: <source title>
```

### 6. Flag gaps

If the question mentions terms not found in concepts, thesaurus, or syntheses:

```markdown
## Not Yet in Wiki
- "<term>" — consider `/wiki-ingest` to add coverage
```

### 7. Honesty constraint

If the wiki does not contain enough information to answer the question, say so
explicitly:

> "The wiki does not have enough on this topic yet. Consider ingesting: [suggest 1–2
> specific sources that would cover this]."

Never answer from training knowledge when the question is about wiki content.
