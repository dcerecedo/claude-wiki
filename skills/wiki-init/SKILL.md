# wiki-init

Initialize a new wiki workspace for personal learning research.

## Usage

```
/wiki-init <topic> [research question]
```

## Steps

### 1. Resolve workspace path

- Base directory: `~/Vaults/`
- Slug: topic lowercased, spaces replaced with hyphens, special chars removed
- Full path: `~/Vaults/<topic-slug>/`

If the directory already exists: stop and tell the user. Do not overwrite.

### 2. Create directory structure

```bash
mkdir -p ~/Vaults/<topic-slug>/{wiki/{concepts,thesaurus,syntheses,mocs},raw,.claude}
```

### 3. Initialize git

```bash
cd ~/Vaults/<topic-slug>
git init
```

### 4. Generate CLAUDE.md

Read the template at `skills/wiki-init/templates/CLAUDE.md.template`.

Replace:
- `{{TOPIC}}` → the topic argument (original case, not slugified)
- `{{RESEARCH_QUESTION}}` → the research question argument, or `Not specified` if omitted

Write the result to `~/Vaults/<topic-slug>/CLAUDE.md`.

### 5. Generate .claude/settings.json

Copy `skills/wiki-init/templates/settings.json.template` to
`~/Vaults/<topic-slug>/.claude/settings.json` unchanged — it has no placeholders.

### 6. Ask about remote

Ask the user:
> "Does this wiki have a git remote? Paste the remote URL, or press Enter to skip."

If a URL is provided:
```bash
git remote add origin <url>
git pull origin main --allow-unrelated-histories 2>/dev/null || true
```

If skipped: continue.

### 7. Initial commit

```bash
cd ~/Vaults/<topic-slug>
git add .
git commit -m "init: wiki workspace for <topic>"
```

### 8. Report success

Tell the user:
- Workspace created at `~/Vaults/<topic-slug>/`
- Session hooks are configured — sessions will open and close automatically
- Next steps:
  - Start a session: `/wiki-open`
  - Ingest a source: `/wiki-ingest <url-or-file>`
  - Query the wiki: `/wiki-query <question>`
