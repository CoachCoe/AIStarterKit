---
description: Sync skills from reference repositories to check for updates
---

# Skill Sync Command

Check reference repositories for skill updates and improvements.

## Reference Documentation

See `.claude/SOURCES.md` for:
- Full list of reference repositories with GitHub URLs
- Skill-to-source mapping
- Update process

## Quick Sync (GitHub)

```bash
# Clone reference repos (first time)
mkdir -p ~/polkadot-refs && cd ~/polkadot-refs
git clone https://github.com/paritytech/product-infrastructure.git
git clone https://github.com/paritytech/dotns-sdk.git
git clone https://github.com/paritytech/dotli.git
git clone https://github.com/paritytech/dotli-starter.git
git clone https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering.git

# Update all (subsequent times)
cd ~/polkadot-refs
for repo in */; do git -C "$repo" pull; done
```

## Check for Updates

```bash
# See what's changed in each repo
cd ~/polkadot-refs
for repo in */; do
  echo "=== $repo ==="
  git -C "$repo" log --oneline -5
done
```

## What to Check

| Repo | Look For |
|------|----------|
| product-infrastructure | Previewnet changes, new endpoints |
| dotns-sdk | CLI command changes, new features |
| dotli | Config updates, peer changes, new resolution patterns |
| dotli-starter | SDK version updates, new Host API patterns |
| Agent-Skills-for-Context-Engineering | New skill patterns, improvements |

## Update Workflow

1. Pull latest from reference repos
2. Check `.claude/SOURCES.md` for skill-to-source mapping
3. Compare reference files with local skills
4. Update skills with new information
5. Test that commands still work
6. Commit with source reference

## When to Sync

- Weekly during active development
- Before major releases
- When endpoints or commands stop working
