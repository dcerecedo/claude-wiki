# Wiki Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that provides wiki lifecycle management skills for git-managed, Obsidian-compatible personal learning workspaces.

**Architecture:** A pure-markdown skill plugin with a bash hook for wiki workspace detection. Skills are invoked by the user or triggered by project-level Claude Code hooks generated at workspace init time. No runtime dependencies — the plugin is a collection of `SKILL.md` instruction files, a bash detection hook, and Markdown templates.

**Tech Stack:** Bash (hooks + tests), Markdown (skills + templates), JSON (manifests)

---

## File Map

| File | Purpose |
|---|---|
| `package.json` | Plugin manifest |
| `CLAUDE.md` | Contributor guidelines for agents working on this repo |
| `README.md` | User-facing install and usage docs |
| `hooks/hooks.json` | Declares SessionStart hook for the plugin |
| `hooks/run-hook.cmd` | Cross-platform polyglot bash/cmd hook runner |
| `hooks/session-start` | Bash: detects wiki workspaces, injects session context |
| `skills/wiki-init/SKILL.md` | Init skill: creates workspace, CLAUDE.md, settings.json, git init |
| `skills/wiki-init/templates/CLAUDE.md.template` | Template for per-project CLAUDE.md |
| `skills/wiki-init/templates/settings.json.template` | Template for per-project .claude/settings.json |
| `skills/wiki-init/templates/note.md.template` | Template for concept notes |
| `skills/wiki-init/templates/source.md.template` | Template for raw source records |
| `skills/wiki-init/templates/synthesis.md.template` | Template for synthesis notes |
| `skills/wiki-session-review/SKILL.md` | Meta-learning: reads conversation history + git log |
| `skills/wiki-open/SKILL.md` | Session open: git pull + session review |
| `skills/wiki-close/SKILL.md` | Session close: commit + git push |
| `skills/wiki-ingest/SKILL.md` | Ingest source: raw record + concept atomization + synth |
| `skills/wiki-synth/SKILL.md` | Cross-source synthesis: thesaurus + MOCs |
| `skills/wiki-query/SKILL.md` | Query wiki: search + structured answer + gap flagging |
| `tests/test-session-start.sh` | Bash tests for hook detection logic |
| `tests/test-integration.sh` | Smoke test for workspace init output |

---

## Task 1: Plugin scaffolding

**Files:**
- Create: `package.json`
- Create: `CLAUDE.md`
- Create: `README.md`

- [ ] **Step 1: Create package.json**

```json
{
  "name": "wiki",
  "version": "1.0.0",
  "type": "module"
}
```

- [ ] **Step 2: Create CLAUDE.md**

```markdown
# Wiki Plugin — Contributor Guidelines

## If You Are an AI Agent

This repo is the source for the `wiki` Claude Code plugin. Before making changes:

1. Read the spec at `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`
2. Skills live in `skills/<name>/SKILL.md` — these are instruction files, not code
3. Templates live in `skills/wiki-init/templates/`
4. Hooks live in `hooks/` — these ARE code (bash). Run tests before committing.

## Structure

- `skills/` — one directory per skill, each containing `SKILL.md` and optional assets
- `hooks/` — plugin-level SessionStart hook for wiki workspace detection
- `docs/` — design specs and implementation plans (not part of installable surface)
- `tests/` — bash tests for hook scripts

## Testing Skills

Skills are tested by invocation. After writing or modifying a skill, create a test wiki
workspace with `/wiki-init` and run the skill against it. Verify output matches the spec.

## Testing Hooks

Run `bash tests/test-session-start.sh` after any changes to `hooks/session-start`.
Run `bash tests/test-integration.sh` after any changes to templates.

## Workspace Discriminator

Every wiki workspace CLAUDE.md begins with:
`[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)`

This is the detection tag used by `hooks/session-start`. Never change it without
updating the grep in that script.
```

- [ ] **Step 3: Create README.md**

```markdown
# wiki

A Claude Code plugin for building LLM-powered personal learning wikis.

Each wiki is a git-managed, Obsidian-compatible workspace. The LLM acts as researcher
and curator — ingesting sources, atomizing knowledge into concept notes, maintaining a
thesaurus, and synthesizing connections across concepts.

## Install

```bash
claude plugin install wiki@<source>
```

## Usage

Initialize a new wiki workspace:
```
/wiki-init <topic> [research question]
```

Skills available after init:
- `/wiki-open` — start a session (git pull + session review)
- `/wiki-close` — end a session (commit + git push)
- `/wiki-ingest <source>` — ingest a URL, file, or pasted text
- `/wiki-synth` — cross-source synthesis and thesaurus update
- `/wiki-query <question>` — query the knowledge base

## Design

See `docs/superpowers/specs/2026-05-06-llm-wiki-design.md`.
```

- [ ] **Step 4: Commit**

```bash
git add package.json CLAUDE.md README.md
git commit -m "feat: plugin scaffolding — package.json, CLAUDE.md, README"
```

---

## Task 2: Hook infrastructure

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/run-hook.cmd`
- Create: `hooks/session-start`
- Create: `tests/test-session-start.sh`

- [ ] **Step 1: Create hooks/hooks.json**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "async": false
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Create hooks/run-hook.cmd**

Cross-platform polyglot bash/cmd wrapper. On Windows cmd.exe runs the batch block; on Unix the shell runs the bash block.

```
: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for hook scripts.

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)

set "HOOK_DIR=%~dp0"

if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

exit /b 0
CMDBLOCK

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

- [ ] **Step 3: Create hooks/session-start**

```bash
#!/usr/bin/env bash
# SessionStart hook for wiki plugin
# Detects wiki workspaces via discriminator tag and injects context to trigger wiki-open

set -euo pipefail

# Detect wiki workspace — fast single-line grep on first match
if ! grep -qm1 'claude-wiki:Y2xhdWRlLXdpa2k=' "${PWD}/CLAUDE.md" 2>/dev/null; then
  exit 0
fi

# Escape string for JSON embedding
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

context="This is a wiki workspace managed by the wiki plugin. Please invoke the wiki-open skill now to start the session: run git pull if a remote is configured, then run wiki-session-review and report the session context."
context_escaped=$(escape_for_json "$context")

if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
  printf '{\n  "additional_context": "%s"\n}\n' "$context_escaped"
elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -z "${COPILOT_CLI:-}" ]; then
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$context_escaped"
else
  printf '{\n  "additionalContext": "%s"\n}\n' "$context_escaped"
fi

exit 0
```

- [ ] **Step 4: Make session-start executable**

```bash
chmod +x hooks/session-start
```

- [ ] **Step 5: Write failing tests first**

Create `tests/test-session-start.sh`:

```bash
#!/usr/bin/env bash
# Tests for hooks/session-start detection logic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/session-start"
PASS=0
FAIL=0

check() {
    local name="$1"
    local result="$2"
    if [ "$result" = "0" ]; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

# Test 1: wiki workspace (has discriminator) → exits 0 and produces JSON
tmpdir=$(mktemp -d)
printf '[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)\n\n# Wiki: Test\n' > "$tmpdir/CLAUDE.md"
cd "$tmpdir"
export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/.."
output=$(bash "$HOOK" 2>/dev/null)
exit_code=$?
check "wiki workspace exits 0" "$exit_code"
echo "$output" | grep -q 'additionalContext\|additional_context'
check "wiki workspace produces context JSON" "$?"
cd "$SCRIPT_DIR"
rm -rf "$tmpdir"

# Test 2: non-wiki CLAUDE.md (no discriminator) → exits 0, no output
tmpdir=$(mktemp -d)
printf '# Some Project\n\nNot a wiki.\n' > "$tmpdir/CLAUDE.md"
cd "$tmpdir"
export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/.."
output=$(bash "$HOOK" 2>/dev/null)
exit_code=$?
check "non-wiki exits 0" "$exit_code"
[ -z "$output" ]
check "non-wiki produces no output" "$?"
cd "$SCRIPT_DIR"
rm -rf "$tmpdir"

# Test 3: no CLAUDE.md → exits 0, no output
tmpdir=$(mktemp -d)
cd "$tmpdir"
export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/.."
output=$(bash "$HOOK" 2>/dev/null)
exit_code=$?
check "missing CLAUDE.md exits 0" "$exit_code"
[ -z "$output" ]
check "missing CLAUDE.md produces no output" "$?"
cd "$SCRIPT_DIR"
rm -rf "$tmpdir"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 6: Run tests — expect failure (hook not yet executable or wrong output format)**

```bash
chmod +x tests/test-session-start.sh
bash tests/test-session-start.sh
```

Expected: all 6 tests pass (hook was already written in step 3).

```
PASS: wiki workspace exits 0
PASS: wiki workspace produces context JSON
PASS: non-wiki exits 0
PASS: non-wiki produces no output
PASS: missing CLAUDE.md exits 0
PASS: missing CLAUDE.md produces no output

Results: 6 passed, 0 failed
```

If any test fails, fix `hooks/session-start` before committing.

- [ ] **Step 7: Commit**

```bash
git add hooks/ tests/test-session-start.sh
git commit -m "feat: hook infrastructure — SessionStart detection + tests"
```

---

## Task 3: Templates

**Files:**
- Create: `skills/wiki-init/templates/CLAUDE.md.template`
- Create: `skills/wiki-init/templates/settings.json.template`
- Create: `skills/wiki-init/templates/note.md.template`
- Create: `skills/wiki-init/templates/source.md.template`
- Create: `skills/wiki-init/templates/synthesis.md.template`

Placeholders use `{{UPPER_SNAKE}}` syntax throughout — easy to sed-replace and visually distinct from content.

- [ ] **Step 1: Create skills/wiki-init/templates/CLAUDE.md.template**

```
[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)

# Wiki: {{TOPIC}}

## Research Question
{{RESEARCH_QUESTION}}

## Agent Identity
You are a research agent building a personal knowledge wiki on {{TOPIC}}.
Your job is to ingest sources, atomize knowledge into concept notes,
maintain a thesaurus of domain terms, and synthesize connections across concepts.

## Obsidian Conventions
- All internal links use [[wikilink]] syntax
- Every note has YAML frontmatter: title, tags, aliases, created, sources
- Concept notes live in wiki/concepts/, thesaurus terms in wiki/thesaurus/,
  syntheses in wiki/syntheses/, MOCs in wiki/mocs/
- Raw source records live in raw/

## Session Behavior
- On open: git pull (if remote), run wiki-session-review, report context
- On close: commit all changes with a descriptive message, push (if remote)

## Content Principles
- One concept per note — if a note covers two ideas, split it
- Thesaurus terms link to concept notes, not the other way
- MOCs are navigation aids, not summaries — keep them lean
- Prefer [[links]] over repetition — if a concept exists, reference it
```

- [ ] **Step 2: Create skills/wiki-init/templates/settings.json.template**

Project-level hooks that trigger wiki-open and wiki-close. No placeholders — identical for every workspace.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"This is a wiki workspace. Please invoke the wiki-open skill now: run git pull if a remote is configured, then run wiki-session-review and report session context.\"}}'",
            "async": false
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"Stop\",\"additionalContext\":\"This wiki session is ending. Please invoke the wiki-close skill now: check git status, commit if there are changes, and push if a remote is configured.\"}}'",
            "async": false
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Create skills/wiki-init/templates/note.md.template**

```
---
title: {{TITLE}}
tags: [concept, {{DOMAIN_TAG}}]
aliases: []
created: {{DATE}}
sources: [{{SOURCE_PATH}}]
---

{{CONTENT}}

## Related
{{RELATED_LINKS}}
```

- [ ] **Step 4: Create skills/wiki-init/templates/source.md.template**

```
---
title: {{TITLE}}
type: {{TYPE}}
url: {{URL}}
date: {{DATE}}
---

## Summary
{{AGENT_SUMMARY}}

## Key Excerpts
{{EXCERPTS}}

## Concepts Identified
{{CONCEPT_LIST}}
```

- [ ] **Step 5: Create skills/wiki-init/templates/synthesis.md.template**

```
---
title: {{TITLE}}
tags: [synthesis]
created: {{DATE}}
sources: [{{SOURCE_LIST}}]
---

## Synthesis
{{CONTENT}}

## Concepts
{{CONCEPT_LINKS}}

## Open Questions
{{QUESTIONS}}
```

- [ ] **Step 6: Commit**

```bash
git add skills/wiki-init/templates/
git commit -m "feat: wiki-init templates — CLAUDE.md, settings.json, note, source, synthesis"
```

---

## Task 4: Integration smoke test for templates

Write and run a test that validates template rendering before building the skills that depend on them.

**Files:**
- Create: `tests/test-integration.sh`

- [ ] **Step 1: Create tests/test-integration.sh**

```bash
#!/usr/bin/env bash
# Smoke test: simulates wiki-init template rendering, verifies output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0

check() {
    local name="$1"
    local result
    if eval "$2"; then result=0; else result=1; fi
    if [ "$result" -eq 0 ]; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

WORKSPACE=$(mktemp -d)
mkdir -p "$WORKSPACE"/{wiki/{concepts,thesaurus,syntheses,mocs},raw,.claude}

# Simulate wiki-init: render CLAUDE.md from template
sed -e 's/{{TOPIC}}/Transformer Architecture/g' \
    -e 's/{{RESEARCH_QUESTION}}/How does self-attention scale?/g' \
    "$PLUGIN_ROOT/skills/wiki-init/templates/CLAUDE.md.template" \
    > "$WORKSPACE/CLAUDE.md"

# Simulate wiki-init: copy settings.json from template
cp "$PLUGIN_ROOT/skills/wiki-init/templates/settings.json.template" \
   "$WORKSPACE/.claude/settings.json"

# CLAUDE.md checks
check "CLAUDE.md has discriminator tag" \
    "grep -qm1 'claude-wiki:Y2xhdWRlLXdpa2k=' '$WORKSPACE/CLAUDE.md'"
check "CLAUDE.md contains topic" \
    "grep -q 'Transformer Architecture' '$WORKSPACE/CLAUDE.md'"
check "CLAUDE.md contains research question" \
    "grep -q 'How does self-attention scale' '$WORKSPACE/CLAUDE.md'"
check "CLAUDE.md has no unreplaced placeholders" \
    "! grep -q '{{' '$WORKSPACE/CLAUDE.md'"

# settings.json checks
check "settings.json is valid JSON" \
    "python3 -c \"import json; json.load(open('$WORKSPACE/.claude/settings.json'))\" 2>/dev/null"
check "settings.json has SessionStart hook" \
    "python3 -c \"import json; d=json.load(open('$WORKSPACE/.claude/settings.json')); assert 'SessionStart' in d['hooks']\" 2>/dev/null"
check "settings.json has Stop hook" \
    "python3 -c \"import json; d=json.load(open('$WORKSPACE/.claude/settings.json')); assert 'Stop' in d['hooks']\" 2>/dev/null"

# Directory structure checks
check "wiki/concepts exists" "[ -d '$WORKSPACE/wiki/concepts' ]"
check "wiki/thesaurus exists" "[ -d '$WORKSPACE/wiki/thesaurus' ]"
check "wiki/syntheses exists" "[ -d '$WORKSPACE/wiki/syntheses' ]"
check "wiki/mocs exists" "[ -d '$WORKSPACE/wiki/mocs' ]"
check "raw exists" "[ -d '$WORKSPACE/raw' ]"

# Hook detection of rendered workspace
cd "$WORKSPACE"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
hook_output=$(bash "$PLUGIN_ROOT/hooks/session-start" 2>/dev/null)
check "session-start detects rendered workspace" \
    "echo '$hook_output' | grep -q 'additionalContext\|additional_context'"
cd "$SCRIPT_DIR"

rm -rf "$WORKSPACE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run tests**

```bash
chmod +x tests/test-integration.sh
bash tests/test-integration.sh
```

Expected:
```
PASS: CLAUDE.md has discriminator tag
PASS: CLAUDE.md contains topic
PASS: CLAUDE.md contains research question
PASS: CLAUDE.md has no unreplaced placeholders
PASS: settings.json is valid JSON
PASS: settings.json has SessionStart hook
PASS: settings.json has Stop hook
PASS: wiki/concepts exists
PASS: wiki/thesaurus exists
PASS: wiki/syntheses exists
PASS: wiki/mocs exists
PASS: raw exists
PASS: session-start detects rendered workspace

Results: 13 passed, 0 failed
```

- [ ] **Step 3: Commit**

```bash
git add tests/test-integration.sh
git commit -m "test: integration smoke test for template rendering and hook detection"
```

---

## Task 5: wiki-session-review skill

**Files:**
- Create: `skills/wiki-session-review/SKILL.md`

- [ ] **Step 1: Create skills/wiki-session-review/SKILL.md**

```markdown
# wiki-session-review

Analyze previous sessions to identify patterns of failure, repetitive work, and
optimization opportunities. Run automatically inside wiki-open at session start.

## Steps

### 1. Identify conversation history path

The conversation history for the current project lives under `~/.claude/projects/`.
Each project has a subdirectory whose name is derived from the project path.

Run:
```bash
ls -t ~/.claude/projects/
```

Find the entry that corresponds to the current working directory (the name is a hash
or encoded path — look for the most recently modified one if there is only one wiki
project, or compare modification times against the current project's last git commit).

Read the 5 most recently modified files in that directory.

### 2. Analyze conversation history

Look for:
- Any topic or question that appears in more than one session without a corresponding
  file in `wiki/concepts/` — this means knowledge is being re-derived instead of stored
- Tool or skill invocations that appear multiple times with errors before succeeding
- Exchanges of 6 or more turns that resolve a single question — these are candidates
  for a dedicated skill or command
- A sequence of manual steps repeated across two or more sessions — candidate for
  automation

### 3. Analyze git log

```bash
git log --oneline -20
```

Look for:
- The same type of commit message appearing in 3+ sessions (e.g. "add concept X" for
  the same concept slug — signal that synthesis is fragmenting the same idea)
- Sessions with no commit (open + close with no content change)
- Raw sources committed but no corresponding concept notes committed in the same or
  next session

### 4. Check for orphaned raw sources

For each file in `raw/`:
```bash
slug=$(basename "$file" .md)
grep -rl "$slug" wiki/concepts/ 2>/dev/null
```
If a raw source slug does not appear in any concept note's `sources:` frontmatter,
flag it as orphaned.

### 5. Count wiki state

```bash
echo "Concepts: $(find wiki/concepts -name '*.md' 2>/dev/null | wc -l)"
echo "Thesaurus: $(find wiki/thesaurus -name '*.md' 2>/dev/null | wc -l)"
echo "Raw sources: $(find raw -name '*.md' 2>/dev/null | wc -l)"
echo "Last commit: $(git log -1 --format='%ar: %s' 2>/dev/null || echo 'no commits yet')"
```

### 6. Report

Use exactly this format:

```
Wiki: <topic from CLAUDE.md first H1> | <N> concepts | <N> thesaurus | <N> raw sources
Last session: <relative time> — "<last commit message>"

Suggestions:
- <suggestion>
- <suggestion>
```

If there are no suggestions: write `No patterns identified — clean session history.`

### 7. Constraints

- Suggestions are advisory only — never auto-apply them
- Do not invent patterns that are not supported by actual file or conversation evidence
- If a suggestion involves creating a new skill, name the skill and describe in one
  sentence what it would do (it would live in `skills/wiki-<name>/SKILL.md`)
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-session-review/SKILL.md
git commit -m "feat: wiki-session-review skill"
```

---

## Task 6: wiki-open skill

**Files:**
- Create: `skills/wiki-open/SKILL.md`

- [ ] **Step 1: Create skills/wiki-open/SKILL.md**

```markdown
# wiki-open

Start a wiki session. Pull latest changes from remote if configured, then run
wiki-session-review and display the report.

Can be invoked manually or triggered by the SessionStart hook.

## Steps

### 1. Check for remote

```bash
git remote get-url origin 2>/dev/null
```

- If a URL is returned: run `git pull`
- If the command fails or returns nothing: skip silently — this workspace has no remote

### 2. Run wiki-session-review

Invoke the `wiki-session-review` skill. Display its full output.

### 3. Done

No additional confirmation message. The session-review report is the session opening.
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-open/SKILL.md
git commit -m "feat: wiki-open skill"
```

---

## Task 7: wiki-close skill

**Files:**
- Create: `skills/wiki-close/SKILL.md`

- [ ] **Step 1: Create skills/wiki-close/SKILL.md**

```markdown
# wiki-close

End a wiki session. Commit all changes with a descriptive message, then push to
remote if configured.

Can be invoked manually or triggered by the Stop hook.

## Steps

### 1. Check for changes

```bash
git status --porcelain
```

- If output is empty: nothing to commit. Jump to step 4 to check for push.
- If output is non-empty: continue to step 2.

### 2. Generate commit message

Run:
```bash
git diff --stat HEAD
```

Write a commit message that summarizes the session work. Format:

```
wiki: <one-line summary of the session>

- <N> concept(s) added/updated: <comma-separated names>
- <N> source(s) ingested: <comma-separated slugs>
- <N> thesaurus term(s) updated: <comma-separated names>
```

Keep the first line under 72 characters. Omit any bullet whose count is 0.

### 3. Commit

```bash
git add -A
git commit -m "<generated message>"
```

### 4. Push if remote configured

```bash
git remote get-url origin 2>/dev/null
```

- If a URL is returned: run `git push`
- If not: skip silently

### 5. Report

Tell the user one sentence: what was committed (or that there was nothing to commit)
and whether it was pushed.

Examples:
- "Session closed. Committed 3 concept notes and 1 raw source. Pushed to origin."
- "Session closed. Nothing to commit."
- "Session closed. Committed 2 thesaurus updates. No remote configured."
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-close/SKILL.md
git commit -m "feat: wiki-close skill"
```

---

## Task 8: wiki-ingest skill

**Files:**
- Create: `skills/wiki-ingest/SKILL.md`

- [ ] **Step 1: Create skills/wiki-ingest/SKILL.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-ingest/SKILL.md
git commit -m "feat: wiki-ingest skill"
```

---

## Task 9: wiki-synth skill

**Files:**
- Create: `skills/wiki-synth/SKILL.md`

- [ ] **Step 1: Create skills/wiki-synth/SKILL.md**

```markdown
# wiki-synth

Cross-source synthesis: identifies term relationships across concept notes, builds and
updates the thesaurus, creates or updates Maps of Content (MOCs).

Invoked automatically by wiki-ingest, or called standalone for a full rebuild.

## Steps

### 1. Identify concept notes to process

**When called by wiki-ingest:** process only the concept notes written or modified
during that ingest:
```bash
git diff --name-only HEAD -- wiki/concepts/
```

**When called standalone:** process all concept notes:
```bash
find wiki/concepts/ -name "*.md"
```

### 2. Build term relationships

For each concept note to process, read its full content and identify:

| Relationship | Definition |
|---|---|
| Synonyms | Other terms in the wiki that mean the same thing |
| Broader | A more general concept this falls under |
| Narrower | More specific concepts under this one |
| Contrasting | Concepts frequently opposed or compared to this one |
| Related | Concepts frequently used together with this one |

Cross-check against existing `wiki/concepts/` and `wiki/thesaurus/` files to find
matches by name or alias.

### 3. Update thesaurus

For each term identified in step 2:

**Determine the term slug:** lowercase, hyphens for spaces.

**If `wiki/thesaurus/<term-slug>.md` exists:**
- Update `aliases:` frontmatter with any new synonyms (no duplicates)
- Update `broader:`, `narrower:`, `related:` frontmatter links
- Add any missing `[[wikilinks]]` to concept notes in the body under `## In the Wiki`

**If `wiki/thesaurus/<term-slug>.md` does not exist:**
Create it:

```markdown
---
title: <term name>
tags: [thesaurus]
aliases: [<synonym1>, <synonym2>]
created: <YYYY-MM-DD>
broader: [[<broader-term-slug>]]
narrower: [[<narrower-term-slug>]]
related: [[<related-term-slug>]]
---

<1–2 sentence definition of the term>

## In the Wiki
- [[<concept-slug>]]: <one-line description of how this concept uses the term>
```

Omit frontmatter fields (`broader`, `narrower`, `related`) that have no value rather
than leaving them blank.

### 4. Identify MOC candidates

A new MOC is worth creating when 3 or more concept notes share a common theme or
domain cluster that does not yet have a MOC.

Check `wiki/mocs/` to see if modified concepts already belong to an existing MOC.

**If a new cluster is identified:**
Create `wiki/mocs/<cluster-slug>.md`:

```markdown
---
title: <cluster name>
tags: [moc]
created: <YYYY-MM-DD>
---

## Concepts
- [[<concept-slug>]]
- [[<concept-slug>]]

## Thesaurus
- [[<term-slug>]]
```

**If an existing MOC should include new concepts:** add the `[[links]]`.

MOCs contain only links — no prose summaries.

### 5. Report

Tell the user:
- How many thesaurus terms were created vs updated, with names
- How many MOCs were created vs updated, with names

Example:
"Synthesis complete. Created thesaurus terms: [[attention]], [[encoder]].
Updated: [[decoder]]. Updated MOC: [[transformer-models]]."
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-synth/SKILL.md
git commit -m "feat: wiki-synth skill"
```

---

## Task 10: wiki-query skill

**Files:**
- Create: `skills/wiki-query/SKILL.md`

- [ ] **Step 1: Create skills/wiki-query/SKILL.md**

```markdown
# wiki-query

Query the wiki knowledge base. Returns a structured answer drawn from concept notes,
thesaurus terms, and syntheses, with source references and gap flagging.

## Usage

```
/wiki-query <question>
```

## Steps

### 1. Extract key terms

Identify 2–5 key terms from the question. Generate kebab-case slugs for each
(e.g. "self attention" → `self-attention`).

### 2. Search concept notes

For each key term:
```bash
grep -ril "<term>" wiki/concepts/ 2>/dev/null
```

Collect all matching files. Also check filenames directly: if `wiki/concepts/<term-slug>.md`
exists, include it even if grep missed it.

### 3. Expand via thesaurus

For each key term, check if a thesaurus entry exists:
```bash
grep -ril "<term>" wiki/thesaurus/ 2>/dev/null
```

If a thesaurus entry is found, read its `aliases:`, `broader:`, `narrower:`, and
`related:` fields. Run the concept note search again for each of those terms.
This surfaces related knowledge the user may not have named explicitly.

### 4. Search syntheses

```bash
grep -ril "<term>" wiki/syntheses/ 2>/dev/null
```

### 5. Compose answer

Read all matching files. Write a direct answer to the question using only content
from the wiki. Structure:

```markdown
## Answer
<Direct answer to the question, 2–5 sentences. No fabrication — only what the wiki contains.>

## From the Wiki
- [[concept-slug]]: <one-line summary of the relevant content in that note>
- [[concept-slug]]: <one-line summary>

## Sources
- [[raw/source-slug]]: <source title>
```

### 6. Flag gaps

If the question mentions terms not found in concepts, thesaurus, or syntheses:

```markdown
## Not Yet in Wiki
- "<term>" — consider `/wiki-ingest` to add coverage
```

### 7. Honesty constraint

If the wiki does not contain enough information to answer the question, say so
explicitly:

> "The wiki does not have enough on this topic yet. Consider ingesting: [suggest 1–2
> specific sources that would cover this]."

Never answer from training knowledge when the question is about wiki content.
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-query/SKILL.md
git commit -m "feat: wiki-query skill"
```

---

## Task 11: wiki-init skill

**Files:**
- Create: `skills/wiki-init/SKILL.md`

Built last so it can reference all templates and skills that are now defined.

- [ ] **Step 1: Create skills/wiki-init/SKILL.md**

```markdown
# wiki-init

Initialize a new wiki workspace for personal learning research.

## Usage

```
/wiki-init <topic> [research question]
```

## Steps

### 1. Resolve workspace path

- Base directory: `~/Vaults/`
- Slug: topic lowercased, spaces replaced with hyphens, special chars removed
- Full path: `~/Vaults/<topic-slug>/`

If the directory already exists: stop and tell the user. Do not overwrite.

### 2. Create directory structure

```bash
mkdir -p ~/Vaults/<topic-slug>/{wiki/{concepts,thesaurus,syntheses,mocs},raw,.claude}
```

### 3. Initialize git

```bash
cd ~/Vaults/<topic-slug>
git init
```

### 4. Generate CLAUDE.md

Read the template at `skills/wiki-init/templates/CLAUDE.md.template`.

Replace:
- `{{TOPIC}}` → the topic argument (original case, not slugified)
- `{{RESEARCH_QUESTION}}` → the research question argument, or `Not specified` if omitted

Write the result to `~/Vaults/<topic-slug>/CLAUDE.md`.

### 5. Generate .claude/settings.json

Copy `skills/wiki-init/templates/settings.json.template` to
`~/Vaults/<topic-slug>/.claude/settings.json` unchanged — it has no placeholders.

### 6. Ask about remote

Ask the user:
> "Does this wiki have a git remote? Paste the remote URL, or press Enter to skip."

If a URL is provided:
```bash
git remote add origin <url>
git pull origin main --allow-unrelated-histories 2>/dev/null || true
```

If skipped: continue.

### 7. Initial commit

```bash
cd ~/Vaults/<topic-slug>
git add .
git commit -m "init: wiki workspace for <topic>"
```

### 8. Report success

Tell the user:
- Workspace created at `~/Vaults/<topic-slug>/`
- Session hooks are configured — sessions will open and close automatically
- Next steps:
  - Start a session: `/wiki-open`
  - Ingest a source: `/wiki-ingest <url-or-file>`
  - Query the wiki: `/wiki-query <question>`
```

- [ ] **Step 2: Commit**

```bash
git add skills/wiki-init/SKILL.md
git commit -m "feat: wiki-init skill"
```

---

## Task 12: Final verification

- [ ] **Step 1: Run all tests**

```bash
bash tests/test-session-start.sh && bash tests/test-integration.sh
```

Expected: all tests pass with 0 failures.

- [ ] **Step 2: Verify skill files are complete**

```bash
find skills/ -name "SKILL.md" | sort
```

Expected output:
```
skills/wiki-close/SKILL.md
skills/wiki-ingest/SKILL.md
skills/wiki-init/SKILL.md
skills/wiki-open/SKILL.md
skills/wiki-query/SKILL.md
skills/wiki-session-review/SKILL.md
skills/wiki-synth/SKILL.md
```

- [ ] **Step 3: Verify templates are complete**

```bash
find skills/wiki-init/templates/ -name "*.template" | sort
```

Expected output:
```
skills/wiki-init/templates/CLAUDE.md.template
skills/wiki-init/templates/note.md.template
skills/wiki-init/templates/settings.json.template
skills/wiki-init/templates/source.md.template
skills/wiki-init/templates/synthesis.md.template
```

- [ ] **Step 4: Verify hooks are complete**

```bash
ls hooks/
```

Expected output:
```
hooks.json  run-hook.cmd  session-start
```

- [ ] **Step 5: Final commit**

```bash
git add -A
git status --porcelain
# Should be empty — everything already committed
```

If any files are untracked, commit them:
```bash
git add -A && git commit -m "chore: finalize plugin structure"
```
