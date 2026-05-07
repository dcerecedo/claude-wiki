---
name: wiki-close
description: End a wiki session by committing all changes with a descriptive message and pushing to remote if configured. Run at the end of every wiki work session.
when_to_use: Use when finishing a wiki session, wrapping up research, or when the user says "close wiki", "end session", "done for today", or "commit and push".
---

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
