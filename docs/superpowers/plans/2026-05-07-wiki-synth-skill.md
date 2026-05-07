# wiki-synth Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the existing `wiki-synth` skill to `wiki-index`, then create a new `wiki-synth` skill that writes Feynman-style narrative synthesis articles from concept clusters into `wiki/syntheses/`.

**Architecture:** All changes are to Markdown skill files and templates — no code. Part 1 renames and rewires `wiki-synth` → `wiki-index` across the repo. Part 2 creates the new `wiki-synth` skill and updates the synthesis template to match the new article format.

**Tech Stack:** Markdown, YAML frontmatter, bash (for test runner)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `skills/wiki-synth/` | Rename → `skills/wiki-index/` | Structural index skill (thesaurus + MOCs) |
| `skills/wiki-index/SKILL.md` | Modify | Update skill name in header |
| `skills/wiki-ingest/SKILL.md` | Modify | Update "Call wiki-synth" → "Call wiki-index" |
| `docs/superpowers/specs/2026-05-06-llm-wiki-design.md` | Modify | Update all wiki-synth references |
| `skills/wiki-init/templates/synthesis.md.template` | Modify | New article frontmatter format |
| `skills/wiki-synth/SKILL.md` | Create | New narrative synthesis skill |

---

### Task 1: Rename skills/wiki-synth to skills/wiki-index

**Files:**
- Rename: `skills/wiki-synth/` → `skills/wiki-index/`
- Modify: `skills/wiki-index/SKILL.md`

- [ ] **Step 1: Rename the directory with git mv**

```bash
git mv skills/wiki-synth skills/wiki-index
```

- [ ] **Step 2: Update the skill name in the header**

Open `skills/wiki-index/SKILL.md`. Replace the first line:

Old:
```markdown
# wiki-synth
```

New:
```markdown
# wiki-index
```

Also update the description line immediately below it:

Old:
```markdown
Cross-source synthesis: identifies term relationships across concept notes, builds and
updates the thesaurus, creates or updates Maps of Content (MOCs).

Invoked automatically by wiki-ingest, or called standalone for a full rebuild.
```

New:
```markdown
Index the wiki: identifies term relationships across concept notes, builds and
updates the thesaurus, creates or updates Maps of Content (MOCs).

Invoked automatically by wiki-ingest, or called standalone for a full rebuild.
```

- [ ] **Step 3: Commit**

```bash
git add skills/wiki-index/
git commit -m "refactor: rename wiki-synth skill to wiki-index"
```

---

### Task 2: Update all wiki-synth → wiki-index references

**Files:**
- Modify: `skills/wiki-ingest/SKILL.md`
- Modify: `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`

- [ ] **Step 1: Update wiki-ingest/SKILL.md**

In `skills/wiki-ingest/SKILL.md`, make these replacements:

Replace the description line at the top:

Old:
```markdown
Ingest a source into the wiki. Stores the raw record, atomizes into concept notes,
then calls wiki-synth to update the thesaurus.
```

New:
```markdown
Ingest a source into the wiki. Stores the raw record, atomizes into concept notes,
then calls wiki-index to update the thesaurus.
```

Replace Step 5 heading and body:

Old:
```markdown
### 5. Call wiki-synth

Invoke the `wiki-synth` skill to update thesaurus terms and MOCs based on the new
and updated concept notes.
```

New:
```markdown
### 5. Call wiki-index

Invoke the `wiki-index` skill to update thesaurus terms and MOCs based on the new
and updated concept notes.
```

Replace the report example:

Old:
```markdown
- That thesaurus was updated (wiki-synth will report details)
```

New:
```markdown
- That thesaurus was updated (wiki-index will report details)
```

- [ ] **Step 2: Update the main design spec**

In `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`, make these replacements:

Replace the plugin layout entry (around line 42):

Old:
```
    wiki-synth/
```

New:
```
    wiki-index/
```

Replace the skills table rows (around line 140–141):

Old:
```markdown
| `wiki-ingest` | User | Stores raw source, atomizes into concept notes, calls wiki-synth |
| `wiki-synth` | User or ingest | Cross-source synthesis, builds/updates thesaurus terms and MOCs |
```

New:
```markdown
| `wiki-ingest` | User | Stores raw source, atomizes into concept notes, calls wiki-index |
| `wiki-index` | User or ingest | Index the wiki: builds/updates thesaurus terms and MOCs |
| `wiki-synth` | User | Write narrative synthesis articles from concept clusters |
```

Replace the content workflow section (around line 245–250):

Old:
```markdown
4. Call `wiki-synth` internally to update thesaurus terms touched by this ingest

### Synthesize (`wiki-synth`)
Can be called standalone or triggered by ingest.
```

New:
```markdown
4. Call `wiki-index` internally to update thesaurus terms touched by this ingest

### Index (`wiki-index`)
Can be called standalone or triggered by ingest.
```

- [ ] **Step 3: Commit**

```bash
git add skills/wiki-ingest/SKILL.md docs/superpowers/specs/2026-05-06-llm-wiki-design.md
git commit -m "refactor: update all wiki-synth references to wiki-index"
```

---

### Task 3: Update synthesis.md.template

**Files:**
- Modify: `skills/wiki-init/templates/synthesis.md.template`

- [ ] **Step 1: Replace the template content**

Overwrite `skills/wiki-init/templates/synthesis.md.template` with:

```markdown
---
title: {{TITLE}}
tags: [synthesis, {{DOMAIN_TAG}}]
created: {{DATE}}
updated: {{DATE}}
concepts: {{CONCEPTS}}
related_syntheses: {{RELATED_SYNTHESES}}
---

{{CONTENT}}
```

- [ ] **Step 2: Run the integration test to confirm nothing broke**

```bash
bash tests/test-integration.sh
```

Expected: `Results: 15 passed, 0 failed`

- [ ] **Step 3: Commit**

```bash
git add skills/wiki-init/templates/synthesis.md.template
git commit -m "refactor: update synthesis.md.template for wiki-synth article format"
```

---

### Task 4: Create skills/wiki-synth/SKILL.md

**Files:**
- Create: `skills/wiki-synth/SKILL.md`

- [ ] **Step 1: Create the skill directory and file**

Create `skills/wiki-synth/SKILL.md` with the following content:

````markdown
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

Read `skills/wiki-init/templates/synthesis.md.template` and fill in:

| Placeholder | Value |
|---|---|
| `{{TITLE}}` | Article title |
| `{{DOMAIN_TAG}}` | Short domain tag from the wiki topic (e.g. `ml`, `physics`) |
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
````

- [ ] **Step 2: Run the integration test**

```bash
bash tests/test-integration.sh
```

Expected: `Results: 15 passed, 0 failed`

- [ ] **Step 3: Commit**

```bash
git add skills/wiki-synth/SKILL.md
git commit -m "feat: add wiki-synth skill for narrative synthesis articles"
```
