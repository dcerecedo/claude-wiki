# Wiki Plugin — Contributor Guidelines

## If You Are an AI Agent

This repo is the source for the `wiki` Claude Code plugin. Before making changes:

1. Read the spec at `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`
2. Skills live in `skills/<name>/SKILL.md` — these are instruction files, not code
3. Templates live in `skills/wiki-init/templates/`

## Structure

- `skills/` — one directory per skill, each containing `SKILL.md` and optional assets
- `docs/` — design specs and implementation plans (not part of installable surface)
- `tests/` — bash tests for template rendering and hook output validation

## Testing Skills

Skills are tested by invocation. After writing or modifying a skill, create a test wiki
workspace with `/wiki-init` and run the skill against it. Verify output matches the spec.

## Testing Hooks

Run `bash tests/test-integration.sh` after any changes to templates or `skills/wiki-init/templates/settings.json.template`. This validates directory structure, template rendering, and hook output JSON format.

