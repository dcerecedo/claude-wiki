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

## Releasing

Versioning follows semver (`vMAJOR.MINOR.PATCH`):

| Change type | Increment |
|---|---|
| Skill content fixes, typos | patch |
| New skills, behavior changes | minor |
| Breaking changes to init template or workspace format | major |

The git tag is the single source of truth. `package.json` version stays in sync but is secondary.

### Steps to cut a release

1. Bump version in `package.json`
2. Add a `## vX.Y.Z — YYYY-MM-DD` entry to `CHANGELOG.md`
3. `git commit -m "chore: release vX.Y.Z"`
4. `git tag vX.Y.Z && git push origin vX.Y.Z`
5. Extract release notes and create the GitHub Release:

```bash
gh release create vX.Y.Z --title "vX.Y.Z" \
  --notes-file <(awk '/^## vX\.Y\.Z/{found=1; next} found && /^## v/{exit} found{print}' CHANGELOG.md)
```

Replace `vX.Y.Z` with the actual version tag. The zip artifact will be available at:
`https://github.com/dcerecedo/claude-wiki/archive/refs/tags/vX.Y.Z.zip`

