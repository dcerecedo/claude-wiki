# wiki

A Claude Code plugin for building LLM-powered personal learning wikis.

Each wiki is a git-managed, Obsidian-compatible workspace. The LLM acts as researcher
and curator — scouting authoritative sources, ingesting them into the wiki, atomizing
knowledge into concept notes, maintaining a thesaurus, and synthesizing connections
across concepts.

## Install

**Latest** (always tracks `main`):

    /plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/heads/main.zip
    /plugin install wiki@claude-wiki

**Pinned to a specific version** (replace `v1.3.1` with the desired tag):

    /plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/tags/v1.3.1.zip
    /plugin install wiki@claude-wiki

## Workflow

```
/wiki-init <topic>          create the workspace
/wiki-open                  start a session
  /wiki-sources <topic>     (optional) scout and catalogue sources before ingesting
  /wiki-ingest <source>     ingest a source → concept notes → thesaurus
  /wiki-index               rebuild thesaurus and MOCs across all concepts
  /wiki-synth <topic>       write narrative synthesis articles
  /wiki-query <question>    query the knowledge base
/wiki-close                 commit and push
```

`wiki-sources` is an optional first step — use it when you want to discover and
evaluate what's worth reading before committing to ingestion. It stores a catalogue
at `raw/catalogue-<topic>.md` with fetched abstracts and quality rationale for each
source. From there, pick any entry and run `/wiki-ingest <url>`.

## Skills

| Skill | Purpose |
|---|---|
| `/wiki-init <topic>` | Create a new wiki workspace |
| `/wiki-open` | Start a session: git pull + session review |
| `/wiki-close` | End a session: commit + git push |
| `/wiki-sources <topic>` | Scout authoritative sources and catalogue them in `raw/` |
| `/wiki-ingest <source>` | Ingest a URL, file, or pasted text into concept notes |
| `/wiki-index` | Rebuild thesaurus terms and Maps of Content |
| `/wiki-synth <topic>` | Write narrative synthesis articles from concept clusters |
| `/wiki-query <question>` | Query the knowledge base with source references and gap flagging |

## Design

See `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`.
