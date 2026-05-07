---
name: wiki-synth
description: Write narrative synthesis articles for a concept cluster. Produces thorough, logically structured explanations in the style of Feynman, Sagan, or Tyson. Output lives in wiki/syntheses/.
when_to_use: Use when the user wants a narrative explanation of a topic, asks to "synthesize" concepts, or says "write a synthesis", "explain this topic", or "create an article about".
argument-hint: <topic or concept cluster>
---

# wiki-synth

Write narrative synthesis articles for a concept cluster — thorough, rigorous,
logically structured explanations in the style of Feynman, Sagan, or Tyson.
Output lives in `wiki/syntheses/`.

## Usage

```
/wiki-synth <topic>    # write about a named topic
/wiki-synth            # write about concepts added/modified since last synthesis
```

## Steps

### 1. Gather concepts

**With a topic argument:**

Search `wiki/concepts/` by filename and content:
```bash
grep -ril "<topic>" wiki/concepts/ 2>/dev/null
find wiki/concepts/ -iname "*<topic-slug>*" 2>/dev/null
```

Then expand via thesaurus: for each matching concept, check `wiki/thesaurus/` for an
entry with a matching name. Read its `broader:`, `narrower:`, and `related:` frontmatter
links and run the concept search again for each of those terms.

Read all matching concept notes in full.

**Without a topic argument:**

Find the most recently modified synthesis file:
```bash
ls -t wiki/syntheses/*.md 2>/dev/null | head -1
```

Read its `updated:` frontmatter field. Collect all concept notes created or modified
after that file:
```bash
find wiki/concepts/ -name "*.md" -newer wiki/syntheses/<most-recent-file>
```

If `wiki/syntheses/` is empty or does not exist, use all concept notes:
```bash
find wiki/concepts/ -name "*.md"
```

Read all collected concept notes in full.

### 2. Present plan and confirm

Present a concise plan before writing anything:

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

Wait for the user's response. If they say adjust, incorporate their direction and
re-present the revised plan before writing anything.

### 3. Write synthesis article(s)

For each article in the confirmed plan, write `wiki/syntheses/<slug>.md`.

Read `skills/wiki-synth/templates/synthesis.md.template` and fill in:

| Placeholder | Value |
|---|---|
| `{{TITLE}}` | Article title |
| `{{DOMAIN_TAG}}` | Short domain tag: derive from the `tags:` frontmatter of the concept notes being covered, or infer from the topic name if no consistent tag is present (e.g. `ml`, `physics`) |
| `{{DATE}}` | Today's date in YYYY-MM-DD format |
| `{{CONCEPTS}}` | YAML list: `["[[concept-a]]", "[[concept-b]]"]` |
| `{{RELATED_SYNTHESES}}` | YAML list: `["[[other-synthesis]]"]`, or `[]` if none |
| `{{CONTENT}}` | The article body (see requirements below) |

**Body requirements — hard constraints on every article:**

- **Opening hook:** Begin with a question, observation, or analogy that makes the
  reader care before any explanation. Do not open with a definition.
- **First-principles build-up:** Develop the explanation from the ground up, assuming
  no prior familiarity with the topic. Each idea follows logically from the last.
- **Wikilinks in prose:** Weave `[[concept notes]]`, `[[thesaurus terms]]`, and
  `[[other syntheses]]` into the prose naturally — not as a footnote list at the end.
- **Key Insights section:** End with `## Key Insights` — a bullet list of the 3–5
  most important things the wiki currently knows about this topic.
- **Open Questions section:** End with `## Open Questions` — a bullet list of
  knowledge gaps: concepts mentioned in the article but not yet in the wiki, each
  with a suggestion to `/wiki-ingest <topic>`.

Everything else — section count, narrative arc, rhetorical approach, use of analogy —
is chosen by the agent to best serve the topic.

### 4. Report

Tell the user:
- How many synthesis articles were written and their `[[wikilinks]]`
- Any gaps flagged in the Open Questions sections

Example:
```
Wrote 2 synthesis articles:
- [[transformer-architecture-explained]] (new)
- [[attention-mechanisms-deep-dive]] (new)
Gaps flagged: [[mixture-of-experts]] not yet in wiki — consider /wiki-ingest
```
