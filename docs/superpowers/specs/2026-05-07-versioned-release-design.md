# Versioned GitHub Release Design

**Date:** 2026-05-07
**Status:** Approved

## Goal

Publish the wiki plugin as a versioned GitHub artifact with stable URLs that can be shared and referenced from the internet. Target audience: small circle of trusted users.

## Versioning Scheme

Semver: `v1.0.0`, `v1.1.0`, `v2.0.0`.

| Change type | Increment |
|---|---|
| Skill content fixes, typos | patch |
| New skills, behavior changes | minor |
| Breaking changes to init template or workspace format | major |

The git tag is the single source of truth. `package.json` version stays in sync but is secondary.

## Repo Changes

- **`README.md`** — replace `wiki@<source>` placeholder with real install commands
- **`CHANGELOG.md`** (new) — starts with `## v1.0.0` entry; updated with each release
- **`CLAUDE.md`** — add a "Releasing" section documenting the versioning scheme and workflow
- **`package.json`** — version bumped as part of the release commit

## Release Workflow

1. Bump version in `package.json`
2. Update `CHANGELOG.md` with the new version entry
3. `git commit -m "chore: release vX.Y.Z"`
4. `git tag vX.Y.Z && git push origin vX.Y.Z`
5. `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <(sed -n '/## vX.Y.Z/,/## v/p' CHANGELOG.md | head -n -1)`

Step 5 creates a GitHub Release whose zip artifact is available at:
```
https://github.com/dcerecedo/claude-wiki/archive/refs/tags/vX.Y.Z.zip
```

## Install Commands

```bash
# Latest (always tracks main)
/plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/heads/main.zip
/plugin install wiki@claude-wiki

# Pinned to a specific version
/plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/tags/v1.0.0.zip
/plugin install wiki@claude-wiki
```

The marketplace name `claude-wiki` is derived from the repo name and is consistent across both variants.
