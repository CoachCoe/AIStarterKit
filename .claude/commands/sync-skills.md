---
description: Sync skills from reference repositories to check for updates
---

# Skill Sync Command

Check reference repositories for skill updates and improvements.

## Usage

```bash
# Run the sync check script
./scripts/skill-sync.sh
```

## Reference Repositories

Configure your reference repos in `scripts/skill-sync.sh`:

```bash
REFERENCE_REPOS=(
  "/path/to/reference-repo-1"
  "/path/to/reference-repo-2"
)
```

## Sync Workflow

### Step 1: Check for Updates

The script:
1. Fetches from remote for each reference repo
2. Compares local HEAD to origin
3. Reports if updates are available

### Step 2: Review Changes

If updates found:
1. Pull the reference repo
2. Check `.claude/skills/` for changes
3. Compare against your local skills

### Step 3: Update Local Skills

For each changed skill:
1. Read the updated reference
2. Identify what's new/changed
3. Update your local skill
4. Add changelog entry

## Changelog Format

Add to bottom of each skill when updated:

```markdown
---

## Changelog

| Date | Change | Source |
|------|--------|--------|
| 2024-XX-XX | Added pattern X | reference-repo v1.2.0 |
```

## When to Sync

- Before starting major work
- Weekly during active development
- After reference repo announces updates
