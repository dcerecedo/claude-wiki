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
