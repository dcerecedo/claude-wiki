---
name: wiki-open
description: Start a wiki session by pulling latest changes from remote if configured, running wiki-session-review, and reporting the current session context. Run at the start of every wiki work session.
when_to_use: Use at the beginning of a wiki session, when resuming research, or when the user says "open wiki", "start session", or "start wiki".
---

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
