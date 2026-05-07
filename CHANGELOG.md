# Changelog

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
