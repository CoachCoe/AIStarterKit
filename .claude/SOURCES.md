# Skill Sources

This file documents the reference repositories that skills in this starter kit are based on. Check these repos periodically for updates and improvements.

## Reference Repositories

| Repository | GitHub URL | What to Check |
|------------|------------|---------------|
| product-infrastructure | https://github.com/paritytech/product-infrastructure | Previewnet config, deployment patterns |
| dotns-sdk | https://github.com/paritytech/dotns-sdk | DotNS CLI usage, Bulletin deployment |
| Agent-Skills-for-Context-Engineering | https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering | Skill structure, best practices |

## Checking for Updates

### For All Users (GitHub)

```bash
# Clone or update reference repos
git clone https://github.com/paritytech/product-infrastructure.git
git clone https://github.com/paritytech/dotns-sdk.git
git clone https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering.git

# Check for updates
cd product-infrastructure && git pull
cd ../dotns-sdk && git pull
cd ../Agent-Skills-for-Context-Engineering && git pull
```

### For Local Development (if you have repos locally)

Update local paths in your environment:

```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
export SKILL_REFS=(
  "$HOME/Documents/dev/product-infrastructure"
  "$HOME/Documents/dev/dotns-sdk"
  "$HOME/Documents/dev/Agent-Skills-for-Context-Engineering"
)

# Quick check script
for repo in "${SKILL_REFS[@]}"; do
  if [ -d "$repo/.git" ]; then
    echo "=== $(basename $repo) ==="
    git -C "$repo" fetch origin
    git -C "$repo" log HEAD..origin/main --oneline 2>/dev/null || \
    git -C "$repo" log HEAD..origin/master --oneline 2>/dev/null
  fi
done
```

## Skill-to-Source Mapping

| Skill | Primary Source | Files to Watch |
|-------|----------------|----------------|
| `previewnet.md` | product-infrastructure | Previewnet docs, endpoints |
| `deploy-frontend/` | dotns-sdk | CLI commands, PoP setup |
| `asset-hub-evm.md` | product-infrastructure | Network config |
| `skill-creator/` | Agent-Skills-for-Context-Engineering | Skill templates |
| `code-quality.md` | Agent-Skills-for-Context-Engineering | Quality patterns |
| `testing.md` | Agent-Skills-for-Context-Engineering | Test patterns |
| `security.md` | Agent-Skills-for-Context-Engineering | Security patterns |

## When to Sync

- **Weekly** during active development
- **Before major releases**
- **When you notice outdated information** (endpoints, commands, etc.)

## Update Process

1. Check reference repos for changes
2. Compare with local skills
3. Update skills with new patterns/endpoints
4. Test that updated commands still work
5. Commit changes with source reference

Example commit message:
```
docs: update previewnet endpoints

Source: paritytech/product-infrastructure@abc1234
```
