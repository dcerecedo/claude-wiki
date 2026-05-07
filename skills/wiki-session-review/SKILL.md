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

### 6. Classify each finding

For each finding, determine its fix type before reporting:

- `frontmatter` — add or edit a frontmatter field in one or more existing files
- `skill-edit` — insert a step or guard into an existing SKILL.md
- `skill-create` — create a new `skills/wiki-<name>/SKILL.md` encapsulating the procedure
- `behavioral` — no file change possible; guidance only (e.g., session size, workflow habits)

### 7. Report

Use exactly this format:

```
Wiki: <topic from CLAUDE.md first H1> | <N> concepts | <N> thesaurus | <N> raw sources
Last session: <relative time> — "<last commit message>"

Suggestions:
1. <suggestion>
   Fix: <one-line description of what applying the fix would do>

2. <suggestion>
   Fix: behavioral — no automatic fix available

...

To apply a fix, reply: fix <N>  — or fix all to apply all non-behavioral fixes.
```

Number each suggestion. Every suggestion must have a `Fix:` line. Behavioral fixes must say
`behavioral — no automatic fix available` so the user knows upfront that no action is possible.

If there are no suggestions: write `No patterns identified — clean session history.` with no fix prompt.

### 8. Apply fixes on request

When the user replies with `fix <N>` or `fix all`, apply each requested fix according to its type.
Skip behavioral fixes silently (they cannot be applied) and note them in the confirmation.

**frontmatter fix:**
Edit the file(s) named in the suggestion to insert the frontmatter field described. Use the
Read then Edit pattern. Confirm each file changed.

**skill-edit fix:**
Locate the relevant installed skill file. Check in order:
1. `.claude/skills/<name>/SKILL.md` (installed location in the wiki workspace)
2. `skills/<name>/SKILL.md` (plugin source, if currently in the plugin repo)

Insert the described step or guard at the appropriate position. Show a one-line description of
what was added and where.

**skill-create fix:**
Determine whether to write to the installed location or the plugin source (same lookup as above,
but create the directory and file if missing). Write a real skeleton SKILL.md with:
- A one-sentence purpose description
- Numbered steps derived from the suggestion's description
- A constraints section if relevant

Do not write placeholder stubs — the skeleton must be actionable.

After applying all requested fixes, output:
```
Applied: fix <N>[, fix <N>...]
Skipped (behavioral): fix <N>[, fix <N>...]  <- omit line if none
```

Do not commit after applying fixes — let the user review before wiki-close commits them.

### 9. Constraints

- Do not invent patterns not supported by actual file or conversation evidence
- If a suggestion involves creating a new skill, name the skill and state in one sentence what it does
- When applying a skill-create fix, write real numbered steps — never a placeholder
- After applying fixes, do not auto-commit
