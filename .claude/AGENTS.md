# AGENTS.md — Polkadot AI Starter Kit

> IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for project-specific tasks.

This file provides persistent context for AI coding agents. Read this FIRST before any work.

---

## Critical Instructions

### 1. Skills First

Before implementation work, check `.claude/skills/` for relevant domain knowledge:

| Task Domain | Skill to Load |
|-------------|---------------|
| Local development | `previewnet.md` |
| Deploying to Asset Hub | `asset-hub-evm.md` |
| Upgradeable contracts | `upgradeable-contracts.md` |
| Contract deployment | `deploy-contracts/` |
| Frontend deployment | `deploy-frontend/` |
| Host API / Triangle | `host-api.md` (early-stage) |
| Solidity testing | `foundry-testing/` |
| TypeScript testing | `testing.md` |
| Code quality | `code-quality.md` |
| Security review | `security.md` |
| Creating skills | `skill-creator/` |

### 2. Polkadot Specifics

| Concept | Polkadot | Ethereum Equivalent |
|---------|----------|---------------------|
| Native token | DOT | ETH |
| Dev network | Previewnet | Anvil/Hardhat |
| Testnet | Paseo | Sepolia/Goerli |
| Chain ID (testnet) | 420420421 | 11155111 |
| Chain ID (mainnet) | 420420420 | 1 |
| Block explorer | Subscan | Etherscan |
| Block time | ~6 seconds | ~12 seconds |

### 3. Development Workflow

```
Local Anvil → Previewnet → Paseo → Mainnet
   (fast)    (no faucet)  (public)  (prod)
```

### 4. Deployment Protocol

Always use `--slow` flag when deploying to prevent nonce issues:

```bash
forge script script/Deploy.s.sol --rpc-url paseo --broadcast --slow -vvvv
```

---

## Safety Boundaries

### Safe to Execute

```bash
# Foundry
forge build
forge test
forge test -vvv
forge coverage
forge fmt
anvil

# Package managers
pnpm install
pnpm dev
pnpm build
pnpm lint
pnpm typecheck
pnpm test

# Git (read-only)
git status
git diff
git log
git branch
```

### Ask First

```bash
# Deployment
forge script ... --broadcast
forge create

# Git (write)
git add
git commit
git push
git checkout
git merge

# Destructive
rm -rf
forge clean
```

### Never Without Explicit User Request

```bash
git push --force
git reset --hard
forge script ... --broadcast  # to mainnet
Expose private keys
```

---

## Directory Map

```
project/
├── .claude/                    # AI agent configuration (YOU ARE HERE)
│   ├── AGENTS.md               # This file
│   ├── settings.local.json     # Permissions
│   └── skills/                 # Domain knowledge
├── CLAUDE.md                   # Project architecture
├── contracts/                  # Solidity source
├── script/                     # Deployment scripts
├── test/                       # Foundry tests
├── lib/                        # Dependencies (git submodules)
├── apps/                       # Frontend (optional)
├── foundry.toml                # Foundry config
└── .env                        # Secrets (NEVER COMMIT)
```

---

## Invariants (Non-Negotiable)

### Code Philosophy

| Rule | Enforcement | Status |
|------|-------------|--------|
| Least code wins | Every feature with minimum code | MANDATORY |
| Exceptional organization | Clear structure, logical grouping | MANDATORY |
| No code bloat | Delete unused code immediately | MANDATORY |
| No over-engineering | Build exactly what's requested | MANDATORY |
| No premature abstraction | Wait for rule of 3 | MANDATORY |
| No speculative features | YAGNI | MANDATORY |

### Target Chain

| Rule | Enforcement | Status |
|------|-------------|--------|
| Primary chain: Paseo Asset Hub | Development target | MANDATORY |
| Production chain: Polkadot Asset Hub | Mainnet target | MANDATORY |
| No Moonbeam | Use Asset Hub EVM instead | FORBIDDEN |

### Monorepo Structure

| Rule | Enforcement | Status |
|------|-------------|--------|
| Use pnpm workspaces | `pnpm-workspace.yaml` | MANDATORY |
| Packages in `packages/` | contracts, web, etc. | MANDATORY |
| Shared configs at root | tsconfig, eslint | MANDATORY |

### Smart Contracts

| Rule | Enforcement | Status |
|------|-------------|--------|
| Use UUPS for upgradeable | OpenZeppelin pattern | MANDATORY |
| `_disableInitializers()` in constructor | Security | MANDATORY |
| Storage gaps for upgrades | `uint256[50] __gap` | MANDATORY |
| Test all access control | Revert tests | MANDATORY |
| Use `--slow` flag for deployment | Prevent nonce issues | MANDATORY |

### Code Quality

| Rule | Enforcement | Status |
|------|-------------|--------|
| Solidity 0.8.20+ | `pragma solidity ^0.8.20` | MANDATORY |
| SPDX license identifier | Every file | MANDATORY |
| No hardcoded addresses | Use environment/config | MANDATORY |
| No `console.log` in production | Remove before deploy | MANDATORY |

### TypeScript (if frontend)

| Rule | Enforcement | Status |
|------|-------------|--------|
| Strict mode | `"strict": true` | MANDATORY |
| No `any` type | Use `unknown` + guards | MANDATORY |
| Explicit return types | On exports | MANDATORY |
| Minimal dependencies | Justify every addition | MANDATORY |

---

## Verification Matrix

Before considering any task complete:

### For Contracts

```bash
forge build            # Must compile
forge test             # Must pass all tests
forge fmt --check      # Must be formatted
```

### For Frontend

```bash
pnpm typecheck         # Must pass
pnpm lint              # Zero warnings
pnpm test              # Must pass
```

---

## Operational Strategy

### For Simple Tasks

1. Read the relevant file
2. Make the change
3. Run verification
4. Done

### For Contract Work

1. **Load skills** — `asset-hub-evm.md`, `upgradeable-contracts.md`
2. **Understand existing** — Read current contract
3. **Implement** — Follow patterns from skills
4. **Test** — Write tests, run `forge test -vvv`
5. **Verify** — Full verification matrix

### For Deployment

1. **Load skill** — `deploy-contracts/`, `previewnet.md`
2. **Test locally** — `anvil` + deploy script
3. **Deploy Previewnet** — No tokens needed, fast iteration
4. **Deploy Paseo** — `source .env`, public testnet
5. **Deploy Mainnet** — Production (careful!)
6. **Verify** — Check on Subscan

---

## Anti-Patterns (FORBIDDEN)

| Pattern | Why Forbidden | Instead |
|---------|---------------|---------|
| Use Moonbeam | Not our target chain | Use Asset Hub EVM |
| Code bloat | Maintenance burden | Minimal code always |
| Over-engineering | Wasted effort | Build what's requested |
| Premature abstraction | Unclear patterns | Wait for rule of 3 |
| Deploy without `--slow` | Nonce issues | Always use `--slow` |
| Hardcode addresses | Not portable | Use `.env` |
| Skip proxy for upgradeable | Breaks upgrades | Use UUPS pattern |
| Initialize in constructor | Proxy incompatible | Use `initializer` |
| Deploy to mainnet first | Costly mistakes | Paseo testnet first |
| Commit `.env` | Secret exposure | Use `.gitignore` |
| `console.log` in contracts | Gas waste | Remove before deploy |
| `Co-Authored-By` in commits | Triggers CLA bot failures on PRs | Omit co-author lines entirely |

---

## Cross-References

- **Architecture**: See `CLAUDE.md` in project root
- **Domain Knowledge**: See `.claude/skills/`
- **Network Config**: See `asset-hub-evm.md` skill

---

## Learnings

> Append corrections and discoveries here as they occur. Format: `[YYYY-MM-DD] Category: Learning`

| Date | Category | Learning |
|------|----------|----------|
| 2025-03-06 | Git | Never include `Co-Authored-By` lines - triggers CLA bot on GitHub PRs |
| 2025-03-06 | Skills | All skills must have Anti-Patterns section for consistency |
| 2025-03-06 | Documentation | SOURCES.md must map ALL skills to upstream references |
| — | — | Add new learnings above this line |
