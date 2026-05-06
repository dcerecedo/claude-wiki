# wiki-ingest

Ingest a source into the wiki. Stores the raw record, atomizes into concept notes,
then calls wiki-synth to update the thesaurus.

## Usage

```
/wiki-ingest <source>
```

`<source>` is a URL, a file path, or pasted text.

## Steps

### 1. Fetch the source

- URL: use the WebFetch tool to retrieve the content
- File path: read the file with the Read tool
- Pasted text: use as-is

### 2. Generate slug

Create a slug from the source title:
- Lowercase the title
- Replace spaces and special characters with hyphens
- Remove consecutive hyphens
- Truncate to 60 characters

Example: "Attention Is All You Need (2017)" → `attention-is-all-you-need-2017`

### 3. Store raw record

Read `skills/wiki-init/templates/source.md.template`. Fill in every placeholder:

| Placeholder | Value |
|---|---|
| `{{TITLE}}` | Title of the source |
| `{{TYPE}}` | One of: `paper`, `article`, `book`, `video`, `note` |
| `{{URL}}` | Original URL or file path |
| `{{DATE}}` | Today's date in YYYY-MM-DD format |
| `{{AGENT_SUMMARY}}` | 2–3 sentence summary of the source's main contribution |
| `{{EXCERPTS}}` | 3–5 key quotes or passages, verbatim, each as a blockquote |
| `{{CONCEPT_LIST}}` | Bullet list of 3–10 concept names identified in the source |

Write the filled template to `raw/<slug>.md`.

### 4. Atomize into concept notes

For each concept identified in step 3:

**Determine the concept slug:** lowercase name, hyphens for spaces, e.g. `self-attention`

**If `wiki/concepts/<concept-slug>.md` already exists:**
- Read the existing file
- Add any new information from this source to the body
- Add `raw/<slug>.md` to the `sources:` frontmatter list (no duplicates)
- Add `[[wikilinks]]` to any new related concepts from this same ingest

**If `wiki/concepts/<concept-slug>.md` does not exist:**
Read `skills/wiki-init/templates/note.md.template`. Fill in:

| Placeholder | Value |
|---|---|
| `{{TITLE}}` | Concept name (title case) |
| `{{DOMAIN_TAG}}` | Short domain tag derived from the wiki topic (e.g. `ml`, `physics`) |
| `{{DATE}}` | Today's date in YYYY-MM-DD format |
| `{{SOURCE_PATH}}` | `raw/<slug>.md` |
| `{{CONTENT}}` | 2–4 sentences explaining the concept clearly, from first principles |
| `{{RELATED_LINKS}}` | `[[wikilinks]]` to other concepts identified in this same source |

Write to `wiki/concepts/<concept-slug>.md`.

### 5. Call wiki-synth

Invoke the `wiki-synth` skill to update thesaurus terms and MOCs based on the new
and updated concept notes.

### 6. Report

Tell the user:
- Raw source stored at `raw/<slug>.md`
- How many concept notes were created vs updated, with their `[[wikilinks]]`
- That thesaurus was updated (wiki-synth will report details)

Example:
"Ingested 'Attention Is All You Need'. Stored `raw/attention-is-all-you-need-2017.md`.
Created: [[self-attention]], [[multi-head-attention]], [[positional-encoding]].
Updated: [[transformer-architecture]]. Thesaurus updated."
