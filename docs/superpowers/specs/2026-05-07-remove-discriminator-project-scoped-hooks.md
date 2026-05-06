# Remove Discriminator Tag — Project-Scoped Hooks Only

**Date:** 2026-05-07
**Status:** Approved

## Context

The wiki plugin originally used a discriminator tag (`[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)`) embedded in each wiki workspace's `CLAUDE.md` to identify wiki projects. A plugin-level `SessionStart` hook (`hooks/session-start`) detected this tag on every session start across all projects and injected context only when the tag was found.

This design added complexity (hook runner, bash detection script, base64 tag) to solve a problem that doesn't need solving: the user is trusted to only invoke wiki skills in wiki workspaces. The discriminator machinery can be removed entirely.

Additionally, a project-level `SessionStart` hook in `settings.json.template` duplicated the plugin-level hook, causing double messages on session start.

## Goal

Simplify the plugin by removing all global hook infrastructure. Hooks fire only in wiki workspaces via the `.claude/settings.json` created by `/wiki-init`. The plugin remains globally enabled so its skills (including `/wiki-init`) are always accessible.

## Changes

### Delete

| Path | Reason |
|------|--------|
| `hooks/hooks.json` | No global hook declaration |
| `hooks/session-start` | No discriminator detection script |
| `hooks/run-hook.cmd` | No hook runner |
| `hooks/` directory | Empty after deletions |
| `tests/test-session-start.sh` | Tests for deleted script |

### Update: `skills/wiki-init/templates/CLAUDE.md.template`

Remove the discriminator tag on line 1:
```
[//]: # (claude-wiki:Y2xhdWRlLXdpa2k=)
```
The tag has no reader after this change and becomes dead weight.

### Update: `tests/test-integration.sh`

- Remove the "CLAUDE.md has discriminator tag" assertion
- Remove the "session-start detects rendered workspace" block (lines 67–73)
- Add two new hook output assertions using approach B:
  1. Extract the SessionStart hook command from `settings.json.template` via `jq -r`
  2. `eval` the command and validate output is valid JSON with a `systemMessage` key
  3. Extract the Stop hook command via `jq -r`, `eval`, validate output has a `stopReason` key

### Update: `CLAUDE.md`

Remove the "Workspace Discriminator" section entirely.

### Unchanged

`skills/wiki-init/templates/settings.json.template` — already has the correct format (`systemMessage` for SessionStart, `stopReason` for Stop).

## Hook Output Validation (Approach B)

```bash
# Extract and run SessionStart hook, validate output
ss_cmd=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$PLUGIN_ROOT/skills/wiki-init/templates/settings.json.template")
ss_output=$(eval "$ss_cmd")
check "SessionStart hook output is valid JSON" \
    "echo '$ss_output' | python3 -c 'import sys,json; json.load(sys.stdin)'"
check "SessionStart hook output has systemMessage key" \
    "echo '$ss_output' | python3 -c 'import sys,json; d=json.load(sys.stdin); assert \"systemMessage\" in d'"

# Extract and run Stop hook, validate output
stop_cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$PLUGIN_ROOT/skills/wiki-init/templates/settings.json.template")
stop_output=$(eval "$stop_cmd")
check "Stop hook output is valid JSON" \
    "echo '$stop_output' | python3 -c 'import sys,json; json.load(sys.stdin)'"
check "Stop hook output has stopReason key" \
    "echo '$stop_output' | python3 -c 'import sys,json; d=json.load(sys.stdin); assert \"stopReason\" in d'"
```

## Verification

Run `bash tests/test-integration.sh` — all assertions should pass, including the four new hook output checks. The deleted `tests/test-session-start.sh` no longer needs to pass (it will not exist).
