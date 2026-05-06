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
hook_result=0
echo "$hook_output" | grep -q 'additionalContext\|additional_context' || hook_result=$?
check "session-start detects rendered workspace" "[ $hook_result -eq 0 ]"
cd "$SCRIPT_DIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
