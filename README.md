# wiki

A Claude Code plugin for building LLM-powered personal learning wikis.

Each wiki is a git-managed, Obsidian-compatible workspace. The LLM acts as researcher
and curator — ingesting sources, atomizing knowledge into concept notes, maintaining a
thesaurus, and synthesizing connections across concepts.

## Install

**Latest** (always tracks `main`):

    /plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/heads/main.zip
    /plugin install wiki@claude-wiki

**Pinned to a specific version** (replace `v1.0.0` with the desired tag):

    /plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/tags/v1.0.0.zip
    /plugin install wiki@claude-wiki

## Usage

Initialize a new wiki workspace:

    /wiki-init <topic> [research question]

Skills available after init:
- `/wiki-open` — start a session (git pull + session review)
- `/wiki-close` — end a session (commit + git push)
- `/wiki-ingest <source>` — ingest a URL, file, or pasted text
- `/wiki-synth` — cross-source synthesis and thesaurus update
- `/wiki-query <question>` — query the knowledge base

## Design

See `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`.
