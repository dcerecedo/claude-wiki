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
