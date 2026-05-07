# Versioned GitHub Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the first versioned release of the wiki plugin (v1.0.0) as a stable GitHub artifact with documented install URLs.

**Architecture:** All changes are documentation and configuration — no code. README gets real install commands, CHANGELOG.md is introduced, CLAUDE.md gets a Releasing section, and the release is cut with `gh release create`.

**Tech Stack:** git, GitHub CLI (`gh`), Markdown

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `README.md` | Modify | Replace `wiki@<source>` placeholder with real install commands |
| `CHANGELOG.md` | Create | Version history; starts with v1.0.0 entry |
| `CLAUDE.md` | Modify | Add Releasing section with versioning scheme and workflow |

`package.json` is already at `1.0.0` — no change needed.

---

### Task 1: Update README.md with install commands

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the Install section**

Open `README.md` and replace the entire `## Install` section:

```markdown
## Install

**Latest** (always tracks `main`):

    /plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/heads/main.zip
    /plugin install wiki@claude-wiki

**Pinned to a specific version** (replace `v1.0.0` with the desired tag):

    /plugin marketplace add https://github.com/dcerecedo/claude-wiki/archive/refs/tags/v1.0.0.zip
    /plugin install wiki@claude-wiki
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add versioned install commands to README"
```

---

### Task 2: Create CHANGELOG.md

**Files:**
- Create: `CHANGELOG.md`

- [ ] **Step 1: Write the initial changelog**

Create `CHANGELOG.md` with the following content:

```markdown
# Changelog

## v1.0.0 — 2026-05-07

Initial release.

### Skills
- `wiki-init` — initialize a new wiki workspace
- `wiki-open` — start a session (git pull + session review)
- `wiki-close` — end a session (commit + git push)
- `wiki-ingest` — ingest a URL, file, or pasted text
- `wiki-synth` — cross-source synthesis and thesaurus update
- `wiki-query` — query the knowledge base
```

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG.md with v1.0.0 entry"
```

---

### Task 3: Add Releasing section to CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Append the Releasing section**

Add the following to the end of `CLAUDE.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add Releasing section to CLAUDE.md"
```

---

### Task 4: Push and cut the v1.0.0 release

**Files:** none (git and GitHub operations only)

- [ ] **Step 1: Push all commits to origin**

```bash
git push origin master
```

Expected: commits from Tasks 1–3 land on the remote.

- [ ] **Step 2: Tag v1.0.0 and push the tag**

```bash
git tag v1.0.0 && git push origin v1.0.0
```

Expected: tag appears at `https://github.com/dcerecedo/claude-wiki/releases/tag/v1.0.0`.

- [ ] **Step 3: Create the GitHub Release**

```bash
gh release create v1.0.0 --title "v1.0.0" \
  --notes-file <(awk '/^## v1\.0\.0/{found=1; next} found && /^## v/{exit} found{print}' CHANGELOG.md)
```

Expected output: a URL like `https://github.com/dcerecedo/claude-wiki/releases/tag/v1.0.0`

- [ ] **Step 4: Verify the zip artifact URL is accessible**

```bash
curl -sI https://github.com/dcerecedo/claude-wiki/archive/refs/tags/v1.0.0.zip | head -5
```

Expected: `HTTP/2 302` (GitHub redirects to the CDN artifact — this confirms the URL works).
