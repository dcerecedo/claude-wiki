# Remove Discriminator — Project-Scoped Hooks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the discriminator tag and all global hook infrastructure from the wiki plugin, leaving hooks only in per-project `.claude/settings.json` files created by `/wiki-init`.

**Architecture:** Delete the `hooks/` directory and `tests/test-session-start.sh` entirely. Update `tests/test-integration.sh` to remove discriminator assertions and add hook output validation. Strip the discriminator tag from `CLAUDE.md.template`. Update contributor docs.

**Tech Stack:** Bash, jq, python3 (all already used in existing tests)

---

### Task 1: Update tests/test-integration.sh

**Files:**
- Modify: `tests/test-integration.sh`

- [ ] **Step 1: Replace test-integration.sh with the updated version**

Write the following to `tests/test-integration.sh` (complete file):

```bash
#!/usr/bin/env bash
# Smoke test: simulates wiki-init template rendering, verifies output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0
WORKSPACE=""

cleanup() { rm -rf "$WORKSPACE" 2>/dev/null || true; }
trap cleanup EXIT

check() {
    local name="$1"
    local result
    eval "$2" && result=0 || result=$?
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

# Hook output validation (jq extracts command from template, eval runs it, python3 validates output)
ss_cmd=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$PLUGIN_ROOT/skills/wiki-init/templates/settings.json.template")
ss_output=$(eval "$ss_cmd")
check "SessionStart hook output is valid JSON" \
    "echo '$ss_output' | python3 -c 'import sys,json; json.load(sys.stdin)'"
check "SessionStart hook output has systemMessage key" \
    "echo '$ss_output' | python3 -c 'import sys,json; d=json.load(sys.stdin); assert \"systemMessage\" in d'"

stop_cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$PLUGIN_ROOT/skills/wiki-init/templates/settings.json.template")
stop_output=$(eval "$stop_cmd")
check "Stop hook output is valid JSON" \
    "echo '$stop_output' | python3 -c 'import sys,json; json.load(sys.stdin)'"
check "Stop hook output has stopReason key" \
    "echo '$stop_output' | python3 -c 'import sys,json; d=json.load(sys.stdin); assert \"stopReason\" in d'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
bash tests/test-integration.sh
```

Expected output:
```
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
PASS: SessionStart hook output is valid JSON
PASS: SessionStart hook output has systemMessage key
PASS: Stop hook output is valid JSON
PASS: Stop hook output has stopReason key

Results: 15 passed, 0 failed
```

- [ ] **Step 3: Commit**

```bash
git add tests/test-integration.sh
git commit -m "test: remove discriminator assertion, add hook output validation"
```

---

### Task 2: Remove discriminator tag from CLAUDE.md.template

**Files:**
- Modify: `skills/wiki-init/templates/CLAUDE.md.template`

- [ ] **Step 1: Remove the discriminator tag line**

The current first two lines of `skills/wiki-init/templates/CLAUDE.md.template` are:
```
[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)

```

Delete them. The file should now start with:
```markdown
# Wiki: {{TOPIC}}
```

- [ ] **Step 2: Run tests to verify they still pass**

```bash
bash tests/test-integration.sh
```

Expected: `Results: 15 passed, 0 failed`

- [ ] **Step 3: Commit**

```bash
git add skills/wiki-init/templates/CLAUDE.md.template
git commit -m "chore: remove discriminator tag from CLAUDE.md template"
```

---

### Task 3: Delete hooks/ directory and test-session-start.sh

**Files:**
- Delete: `hooks/hooks.json`
- Delete: `hooks/session-start`
- Delete: `hooks/run-hook.cmd`
- Delete: `hooks/` directory
- Delete: `tests/test-session-start.sh`

- [ ] **Step 1: Delete the hooks directory and session-start test**

```bash
rm -rf hooks/
rm tests/test-session-start.sh
```

- [ ] **Step 2: Run tests to verify nothing broke**

```bash
bash tests/test-integration.sh
```

Expected: `Results: 15 passed, 0 failed`

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove global hook infrastructure and discriminator detection"
```

---

### Task 4: Update CLAUDE.md contributor docs

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Remove the Workspace Discriminator section**

Find and remove the following section from `CLAUDE.md`:

```markdown
## Workspace Discriminator

Every wiki workspace CLAUDE.md begins with:
`[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)`

This is the detection tag used by `hooks/session-start`. Never change it without
updating the grep in that script.
```

- [ ] **Step 2: Update the Testing Hooks section**

Find:
```markdown
## Testing Hooks

Run `bash tests/test-session-start.sh` after any changes to `hooks/session-start`.
Run `bash tests/test-integration.sh` after any changes to templates.
```

Replace with:
```markdown
## Testing Hooks

Run `bash tests/test-integration.sh` after any changes to templates or `skills/wiki-init/templates/settings.json.template`. This validates directory structure, template rendering, and hook output JSON format.
```

- [ ] **Step 3: Update the Structure section**

Find the `hooks/` line in the Structure section:
```markdown
- `hooks/` — plugin-level SessionStart hook for wiki workspace detection
```

Remove that line entirely (the `hooks/` directory no longer exists).

- [ ] **Step 4: Update the "If You Are an AI Agent" section**

Find:
```markdown
4. Hooks live in `hooks/` — these ARE code (bash). Run tests before committing.
```

Remove that line entirely.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update contributor guide — remove discriminator and hooks/ references"
```
