# wiki-synth Skill Design

**Date:** 2026-05-07
**Status:** Approved

## Overview

A new skill that writes narrative synthesis articles for the wiki — thorough, rigorous, logically structured explanations of concept clusters, in the style of Feynman, Sagan, or Tyson giving a masterclass. Output lives in `wiki/syntheses/`.

This spec also covers renaming the existing `wiki-synth` skill to `wiki-index` to free the `wiki-synth` name for this higher-level synthesis work.

---

## Skill: wiki-synth

### Invocation

```
/wiki-synth <topic>    # named topic
/wiki-synth            # infer from concepts added/modified since last synthesis
```

**With a topic:** search `wiki/concepts/` by filename and content for matching notes, then expand via thesaurus links (`broader`, `narrower`, `related`) to pull in adjacent concepts.

**Without a topic:** find the most recently modified file in `wiki/syntheses/`, read its `updated` frontmatter date, and collect all concept notes created or modified after that date. If no synthesis files exist yet, consider the entire `wiki/concepts/` corpus.

A single invocation may produce **one or more synthesis files** — the agent decides how to cluster concepts into coherent topics and links related syntheses to each other via `[[wikilinks]]`.

### Step 1: Gather concepts

- Search `wiki/concepts/` by topic name (filename and content)
- Expand via thesaurus: read `broader`, `narrower`, `related` links from matching thesaurus entries in `wiki/thesaurus/`
- Read all matching concept notes in full

### Step 2: Present plan and confirm

Before writing anything, present a concise plan:

```
Topic cluster: <cluster name>
Concepts covered: [[concept-a]], [[concept-b]], [[concept-c]] (+ N via thesaurus)
Syntheses to write: N
  1. "<proposed title>" — covers X, Y, Z; links to synthesis 2
  2. "<proposed title>" — covers A, B; links to synthesis 1
Angle: <1-sentence framing of how the explanation will be structured>
Gaps identified: [[missing-concept]] not yet in wiki

Proceed? (yes / adjust)
```

Wait for confirmation. If the user says adjust, incorporate their direction before writing.

### Step 3: Write synthesis article(s)

For each article in the confirmed plan, write `wiki/syntheses/<slug>.md`.

**Frontmatter:**

```yaml
---
title: <article title>
tags: [synthesis, <domain-tag>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
concepts: ["[[concept-a]]", "[[concept-b]]", "[[concept-c]]"]
related_syntheses: ["[[other-synthesis]]"]
---
```

**Body structure:** agent-determined — choose the structure that best serves the topic. Some topics call for a historical arc, others for a first-principles build-up, others for a contrast between competing ideas. The only hard requirements:

- **Opening hook** — make the reader care about the topic before explaining it
- **First-principles explanation** — build understanding from the ground up, no assumed familiarity
- **Wikilinks woven into prose** — `[[concept notes]]`, `[[thesaurus terms]]`, and `[[other syntheses]]` appear naturally in the text, not as a reference list
- **Key Insights section** — 3–5 most important things the wiki knows about this topic
- **Open Questions section** — knowledge gaps; concepts mentioned but not in the wiki, each flagged as an ingest candidate

### Step 4: Report

```
Wrote 2 synthesis articles:
- [[transformer-architecture-explained]] (new)
- [[attention-mechanisms-deep-dive]] (new)
Gaps flagged: [[mixture-of-experts]] not yet in wiki — consider /wiki-ingest
```

---

## Staleness detection

The `updated` frontmatter field enables staleness detection. When `wiki-index` runs after new concepts are ingested, it can compare concept note creation dates against synthesis `updated` dates to flag articles that may need revisiting. This is advisory — `wiki-synth` does not auto-update existing articles, but the user can call `/wiki-synth <topic>` to refresh one.

---

## Rename: wiki-synth → wiki-index

The existing `wiki-synth` skill (thesaurus updates + MOC creation) is renamed to `wiki-index` to reflect its structural indexing role and free the `wiki-synth` name for this skill.

### Changes required

| File | Change |
|---|---|
| `skills/wiki-synth/` | Rename directory to `skills/wiki-index/` |
| `skills/wiki-index/SKILL.md` | Update skill name in header |
| `skills/wiki-ingest/SKILL.md` | Update internal call from `wiki-synth` to `wiki-index` |
| `CLAUDE.md` | Update any references |
| `docs/superpowers/specs/2026-05-06-llm-wiki-design.md` | Update skill table and references |

---

## What wiki-synth does NOT do

- Does not update the thesaurus — that is `wiki-index`'s responsibility
- Does not auto-update existing synthesis articles — call `/wiki-synth <topic>` explicitly to refresh
- Does not fabricate knowledge — the article reflects only what concept notes and thesaurus entries contain; gaps are flagged, not filled
