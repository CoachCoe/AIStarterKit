# Skill Sources

This file documents the reference repositories that skills in this starter kit are based on. Check these repos periodically for updates and improvements.

## Reference Repositories

| Repository | GitHub URL | What to Check |
|------------|------------|---------------|
| product-infrastructure | https://github.com/paritytech/product-infrastructure | Previewnet config, deployment patterns |
| dotns-sdk | https://github.com/paritytech/dotns-sdk | DotNS CLI usage, Bulletin deployment |
| dotli | https://github.com/paritytech/dotli | Client-side resolution, Smoldot+Helia patterns |
| Agent-Skills-for-Context-Engineering | https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering | Skill structure, best practices |
| triangle-web-host-demo | https://github.com/nicosantangelo/triangle-web-host-demo | Host API patterns, Triangle SDK |
| OpenZeppelin Docs | https://docs.openzeppelin.com/contracts | UUPS proxy patterns, upgradeability |
| Foundry Book | https://book.getfoundry.sh | Test patterns, cheatcodes, scripting |
| Stryker Docs | https://stryker-mutator.io/docs | Mutation testing configuration |

## Checking for Updates

### For All Users (GitHub)

```bash
# Clone or update reference repos
git clone https://github.com/paritytech/product-infrastructure.git
git clone https://github.com/paritytech/dotns-sdk.git
git clone https://github.com/paritytech/dotli.git
git clone https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering.git

# Check for updates
cd product-infrastructure && git pull
cd ../dotns-sdk && git pull
cd ../dotli && git pull
cd ../Agent-Skills-for-Context-Engineering && git pull
```

### For Local Development (if you have repos locally)

Update local paths in your environment:

```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
export SKILL_REFS=(
  "$HOME/Documents/dev/product-infrastructure"
  "$HOME/Documents/dev/dotns-sdk"
  "$HOME/Documents/dev/dotli"
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
| `dotli/` | dotli | src/*, config.ts, README |
| `asset-hub-evm.md` | product-infrastructure | Network config |
| `skill-creator/` | Agent-Skills-for-Context-Engineering | Skill templates |
| `code-quality.md` | Agent-Skills-for-Context-Engineering | Quality patterns |
| `testing.md` | Agent-Skills-for-Context-Engineering | Test patterns |
| `security.md` | Agent-Skills-for-Context-Engineering | Security patterns |
| `upgradeable-contracts.md` | OpenZeppelin docs | UUPS patterns, proxy deployment |
| `foundry-testing/` | Foundry Book | Test patterns, cheatcodes |
| `mutation-testing/` | Stryker docs | Mutation testing patterns |
| `host-api.md` | triangle-web-host-demo | Host API overview, skill index |
| `triangle/OVERVIEW.md` | triangle-web-host-demo | Architecture, concepts |
| `triangle/spektr-manager.md` | triangle-web-host-demo | SpektrManager patterns |
| `triangle/authentication.md` | triangle-web-host-demo | Wallet auth (Papp + Extensions) |
| `triangle/dotns-resolution.md` | triangle-web-host-demo | Domain resolution |
| `triangle/service-worker.md` | triangle-web-host-demo | SW caching patterns |
| `triangle/product-sdk.md` | triangle-web-host-demo | Product SDK usage |
| `triangle/static-export.md` | triangle-web-host-demo | Static export requirements |

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
