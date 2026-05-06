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
