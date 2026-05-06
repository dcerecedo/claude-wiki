# wiki-synth

Cross-source synthesis: identifies term relationships across concept notes, builds and
updates the thesaurus, creates or updates Maps of Content (MOCs).

Invoked automatically by wiki-ingest, or called standalone for a full rebuild.

## Steps

### 1. Identify concept notes to process

**When called by wiki-ingest:** process only the concept notes written or modified
during that ingest:
```bash
git diff --name-only HEAD -- wiki/concepts/
```

**When called standalone:** process all concept notes:
```bash
find wiki/concepts/ -name "*.md"
```

### 2. Build term relationships

For each concept note to process, read its full content and identify:

| Relationship | Definition |
|---|---|
| Synonyms | Other terms in the wiki that mean the same thing |
| Broader | A more general concept this falls under |
| Narrower | More specific concepts under this one |
| Contrasting | Concepts frequently opposed or compared to this one |
| Related | Concepts frequently used together with this one |

Cross-check against existing `wiki/concepts/` and `wiki/thesaurus/` files to find
matches by name or alias.

### 3. Update thesaurus

For each term identified in step 2:

**Determine the term slug:** lowercase, hyphens for spaces.

**If `wiki/thesaurus/<term-slug>.md` exists:**
- Update `aliases:` frontmatter with any new synonyms (no duplicates)
- Update `broader:`, `narrower:`, `related:` frontmatter links
- Add any missing `[[wikilinks]]` to concept notes in the body under `## In the Wiki`

**If `wiki/thesaurus/<term-slug>.md` does not exist:**
Create it:

```markdown
---
title: <term name>
tags: [thesaurus]
aliases: [<synonym1>, <synonym2>]
created: <YYYY-MM-DD>
broader: [[<broader-term-slug>]]
narrower: [[<narrower-term-slug>]]
related: [[<related-term-slug>]]
---

<1–2 sentence definition of the term>

## In the Wiki
- [[<concept-slug>]]: <one-line description of how this concept uses the term>
```

Omit frontmatter fields (`broader`, `narrower`, `related`) that have no value rather
than leaving them blank.

### 4. Identify MOC candidates

A new MOC is worth creating when 3 or more concept notes share a common theme or
domain cluster that does not yet have a MOC.

Check `wiki/mocs/` to see if modified concepts already belong to an existing MOC.

**If a new cluster is identified:**
Create `wiki/mocs/<cluster-slug>.md`:

```markdown
---
title: <cluster name>
tags: [moc]
created: <YYYY-MM-DD>
---

## Concepts
- [[<concept-slug>]]
- [[<concept-slug>]]

## Thesaurus
- [[<term-slug>]]
```

**If an existing MOC should include new concepts:** add the `[[links]]`.

MOCs contain only links — no prose summaries.

### 5. Report

Tell the user:
- How many thesaurus terms were created vs updated, with names
- How many MOCs were created vs updated, with names

Example:
"Synthesis complete. Created thesaurus terms: [[attention]], [[encoder]].
Updated: [[decoder]]. Updated MOC: [[transformer-models]]."
