---
name: wiki-session-review
description: Analyze previous sessions to identify patterns of failure, repetitive work, and optimization opportunities. Reports findings and guides the user through fix options conversationally. Called automatically by wiki-open.
when_to_use: Use to review past session patterns, identify workflow inefficiencies, or when the user says "review sessions", "what went wrong", or "how can I improve my wiki workflow".
---

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

Patterns found:
- <problem>
- <problem>
...

Would you like to address any of these? If so, which one?
```

If there are no problems: write `No patterns identified — clean session history.` and stop.

### 7. Wait for the user to pick a problem

Do not proceed until the user selects a problem or says they are done.
If the user says they are done or not interested, end the skill gracefully.

### 8. Propose options for the chosen problem

Generate 2–3 concrete fix options for the selected problem. For each option:

```
Option A — <short name>
<One-paragraph description of what this fix does and how it works.>
Pro: <main advantage>
Con: <main drawback or trade-off>

Option B — <short name>
...

Option C — <short name>  (omit if only two good options exist)
...

Recommended: Option <X> — <one sentence on why>
```

Ground each option in real files and steps, not generalities. If an option involves editing
a SKILL.md, name the file and describe which step would change. If it involves adding
frontmatter, name the specific files. If it involves creating a new skill, name the skill.

### 9. Wait for the user to choose or refine

Do not apply anything yet. The user may:
- Pick an option by letter or name
- Ask to modify an option (e.g., "Option A but without X")
- Ask a follow-up question about trade-offs

Respond to refinements by adjusting the option description and confirming the revised plan
before applying. Keep iterating until the user gives explicit approval to proceed.

### 10. Apply the chosen fix

Once the user approves, apply the fix:

**Frontmatter change:** Read the file(s), then Edit to insert the field. Confirm each file changed.

**SKILL.md edit:** Locate the skill file — check `.claude/skills/<name>/SKILL.md` first
(installed location), then `skills/<name>/SKILL.md` (plugin source). Read it, then Edit to
insert or modify the relevant step. Show a brief description of what changed and where.

**New skill:** Determine the right location (same lookup as above, create if missing). Write a
real SKILL.md with a one-sentence purpose, numbered steps derived from the agreed plan, and a
constraints section if relevant. No placeholder stubs — the skill must be immediately usable.

After applying, confirm what was done in one or two sentences, then ask:
```
Anything else to address from the list?
```

If the user wants to address another problem, return to step 8 with the new selection.

### 11. Constraints

- Do not invent patterns not supported by actual file or conversation evidence
- Never apply a fix before the user explicitly approves it
- When writing a new skill, write real numbered steps — never a placeholder
- Do not auto-commit after applying fixes — let wiki-close handle that
