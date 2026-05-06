# LLM Wiki System — Design Spec
_Date: 2026-05-06 | Status: Approved_

## Overview

A global skill layer for building and maintaining personal learning wikis. Each wiki is a git-managed, Obsidian-compatible workspace where an LLM agent acts as researcher and knowledge curator — ingesting sources, atomizing knowledge into concept notes, maintaining a domain thesaurus, and synthesizing connections across concepts.

Inspired by the model of an LLM as active research agent (not passive writing assistant).

---

## Architecture

### Global skill layer (`~/.claude/skills/wiki/`)

All tooling lives globally and is available across every wiki project.

```
~/.claude/skills/wiki/
  wiki-init/
    skill.md
    templates/
      CLAUDE.md.template
      settings.json.template
      note.md.template
      source.md.template
      synthesis.md.template
  wiki-open/
    skill.md
  wiki-close/
    skill.md
  wiki-ingest/
    skill.md
  wiki-synth/
    skill.md
  wiki-query/
    skill.md
  wiki-session-review/
    skill.md
```

### Per-project workspace (`~/Vaults/<topic>/`)

```
~/Vaults/<topic>/
  .claude/
    settings.json        ← hooks: PostSessionStart → wiki-open, PreSessionEnd → wiki-close
  CLAUDE.md              ← generated from template; topic, research question, agent behavior
  wiki/
    concepts/            ← atomic concept notes, one idea per file
    thesaurus/           ← domain term notes with aliases, synonyms, [[links]]
    syntheses/           ← cross-source synthesis notes
    mocs/                ← Maps of Content for navigating concept clusters
  raw/                   ← raw ingested source records
  .git/
```

Git is the log. No `log.md`.

---

## Skills

| Skill | Invoked by | Purpose |
|---|---|---|
| `wiki-init` | User | Creates workspace, generates CLAUDE.md + settings.json, runs git init, optionally sets remote |
| `wiki-open` | Hook or user | git pull (if remote), runs wiki-session-review, reports session context |
| `wiki-close` | Hook or user | Commits all changes with descriptive message, git push (if remote) |
| `wiki-ingest` | User | Stores raw source, atomizes into concept notes, calls wiki-synth |
| `wiki-synth` | User or ingest | Cross-source synthesis, builds/updates thesaurus terms and MOCs |
| `wiki-query` | User | Structured query returning concept notes + thesaurus terms + source refs |
| `wiki-session-review` | wiki-open | Reads project conversation history + git log, identifies patterns, proposes optimizations |

---

## Session Lifecycle

### Open (`wiki-open`)
1. `git pull` if remote configured — skip if no remote
2. Run `wiki-session-review`
3. Report: topic, research question, last commit message, suggestions from review

### Close (`wiki-close`)
1. Check `git status` — if nothing changed, skip commit and push silently
2. Stage all changes
3. Generate commit message summarizing session work (concepts added, sources ingested, thesaurus terms updated) from git diff
4. `git commit`
5. `git push` if remote configured

### Idempotency
Both skills rely on git state, not a flag file. `git pull` when up to date is a no-op. `git commit` with no changes is skipped. Safe to call multiple times or from concurrent sessions.

### Subagents
Subagents spawned within a session perform content work only (ingest, synth, query). They never call `wiki-open` or `wiki-close` — session lifecycle is parent-session responsibility.

---

## CLAUDE.md Template

```markdown
# Wiki: <topic>

## Research Question
<research-question | "Not specified">

## Agent Identity
You are a research agent building a personal knowledge wiki on <topic>.
Your job is to ingest sources, atomize knowledge into concept notes,
maintain a thesaurus of domain terms, and synthesize connections across concepts.

## Obsidian Conventions
- All internal links use [[wikilink]] syntax
- Every note has YAML frontmatter: title, tags, aliases, created, sources
- Concept notes live in wiki/concepts/, thesaurus terms in wiki/thesaurus/,
  syntheses in wiki/syntheses/, MOCs in wiki/mocs/
- Raw source records live in raw/

## Session Behavior
- On open: git pull (if remote), run wiki-session-review, report context
- On close: commit all changes with a descriptive message, push (if remote)

## Content Principles
- One concept per note — if a note covers two ideas, split it
- Thesaurus terms link to concept notes, not the other way
- MOCs are navigation aids, not summaries — keep them lean
- Prefer [[links]] over repetition — if a concept exists, reference it
```

---

## Meta-Learning Loop (`wiki-session-review`)

Reads two sources at session open:

**Conversation history** (`~/.claude/projects/<hash>/`) — looks for:
- Repeated questions across sessions with no corresponding concept note
- Failed or repeated skill/tool invocations
- Long back-and-forth chains that a single command should cover
- Manually repeated workflows that could become a skill

**Git log + diffs** (`git log --oneline -20` + recent diffs) — looks for:
- Notes edited repeatedly (unstable synthesis)
- Commit messages describing the same work pattern every session
- Raw sources with no linked concept notes

**Output format:**
```
Wiki: <topic> | Last session: <date> | <N> concepts | <N> thesaurus terms

Last commit: "<message>"

Suggestions:
- You've queried "X" 4 times without a concept note — consider /wiki-ingest
- raw/paper.md has no linked concept notes yet
- [new skill candidate] You've manually done X three times — a wiki-X skill could automate this
```

Suggestions are advisory only. New skill candidates flagged here go into `~/.claude/skills/wiki/` when acted on — improvements are always global.

---

## Content Workflow

### Ingest (`wiki-ingest <source>`)
Source can be URL, file path, or pasted text.

1. Fetch/read source → store in `raw/<slug>.md` (title, URL, date, type, key excerpts, agent summary)
2. Identify 3–10 concepts in the source
3. For each concept: create or update `wiki/concepts/<concept>.md` — one idea, YAML frontmatter, `[[links]]` to related concepts, back-reference to raw source
4. Call `wiki-synth` internally to update thesaurus terms touched by this ingest

### Synthesize (`wiki-synth`)
Can be called standalone or triggered by ingest.

1. Scan concept notes modified since last synthesis (via git)
2. Identify term relationships: synonyms, broader/narrower, contrasting concepts
3. Create or update `wiki/thesaurus/<term>.md` — definition, aliases frontmatter, `[[links]]` to related terms and concept notes
4. Identify concept clusters worth a MOC → create or update `wiki/mocs/<cluster>.md`

### Query (`wiki-query <question>`)
1. Search concept notes, thesaurus, syntheses for relevant content
2. Return structured answer with source references and `[[links]]` to relevant notes
3. Flag answer gaps — concepts mentioned but not yet in wiki — as ingest candidates

---

## Obsidian Note Structure

### Concept note (`wiki/concepts/<concept>.md`)
```yaml
---
title: <concept name>
tags: [concept, <domain-tag>]
aliases: []
created: <date>
sources: [raw/<slug>.md]
---
```

### Thesaurus term (`wiki/thesaurus/<term>.md`)
```yaml
---
title: <term>
tags: [thesaurus]
aliases: [<synonym1>, <synonym2>]
created: <date>
broader: [[<broader-term>]]
narrower: [[[<narrower-term>]]]
related: [[<related-term>]]
---
```

### MOC (`wiki/mocs/<cluster>.md`)
```yaml
---
title: <cluster name>
tags: [moc]
---
```
Navigation only — links to concept notes and thesaurus terms, no prose summaries.

---

## Init Flow (`wiki-init <topic> [research-question]`)

1. Create `~/Vaults/<topic>/` directory structure
2. `git init`
3. Generate `CLAUDE.md` from template with topic and research question
4. Generate `.claude/settings.json` with session hooks
5. Prompt: does this wiki have a remote? If yes, `git remote add origin <url>` + initial pull
6. First commit: "init: wiki workspace for <topic>"
