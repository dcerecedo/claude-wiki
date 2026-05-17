# Changelog

## v1.3.1 — 2026-05-17

### Changes
- Updated `CLAUDE.md.template` to reflect the expanded workflow: agent identity now mentions source scouting, and Obsidian Conventions notes that `raw/` holds both ingested records and `catalogue-*.md` files.

## v1.3.0 — 2026-05-17

### New Skills
- `wiki-sources` — scout and catalogue authoritative sources for a topic before ingestion. Stores results in `raw/catalogue-<topic>.md` with fetched abstracts and quality rationale for each source. Feeds into `/wiki-ingest`.

## v1.2.1 — 2026-05-07

### Changes
- All skill SKILL.md files now include `name`, `description`, and `when_to_use` frontmatter.
  Skills that accept arguments also include `argument-hint` and `arguments`.

## v1.2.0 — 2026-05-07

### Changes
- `wiki-session-review` — conversational fix flow. After reporting problems the skill
  asks which one to address, then proposes 2–3 options with pros, cons, and a
  recommendation. The user picks or refines before anything is applied. Replaces the
  previous numbered-list "fix N" shortcut.

## v1.1.0 — 2026-05-07

### New Skills
- `wiki-index` — cross-source synthesis and thesaurus update (renamed from `wiki-synth`)
- `wiki-synth` — generate narrative synthesis articles from indexed sources

### Changes
- Renamed original `wiki-synth` skill to `wiki-index` to better reflect its purpose
- Updated `synthesis.md.template` for the new wiki-synth article format
- Clarified `DOMAIN_TAG` sourcing in wiki-synth skill
- Removed global hook infrastructure and discriminator detection
- Improved hook output validation in tests

## v1.0.0 — 2026-05-07

Initial release.

### Skills
- `wiki-init` — initialize a new wiki workspace
- `wiki-open` — start a session (git pull + session review)
- `wiki-close` — end a session (commit + git push)
- `wiki-ingest` — ingest a URL, file, or pasted text
- `wiki-synth` — cross-source synthesis and thesaurus update
- `wiki-query` — query the knowledge base
