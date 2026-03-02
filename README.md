# Polkadot AI Starter Kit

A production-ready Claude Code configuration for building on Polkadot Asset Hub EVM. Optimized for minimal code, pnpm monorepos, and AI-assisted development.

**Target Chain:** Paseo Asset Hub (testnet) → Polkadot Asset Hub (mainnet)

**Philosophy:** Least code wins. Exceptional organization. No bloat.

---

## New Developer? Start Here

### What You Can Build

- **Smart Contracts** on Polkadot Asset Hub (Solidity, EVM-compatible)
- **Upgradeable Contracts** using OpenZeppelin UUPS pattern
- **Decentralized Frontends** hosted on Bulletin Chain with `.dot` domains
- **Full-Stack dApps** with pnpm monorepo structure

### Prerequisites

| Tool | Install | Purpose |
|------|---------|---------|
| [Claude Code](https://claude.ai/code) | CLI tool | AI-assisted development |
| [Foundry](https://book.getfoundry.sh) | `curl -L https://foundry.paradigm.xyz \| bash` | Solidity development |
| [pnpm](https://pnpm.io) | `npm install -g pnpm` | Package management |
| [Bun](https://bun.sh) | `curl -fsSL https://bun.sh/install \| bash` | For dotNS CLI |

### Your Journey (Zero to Deployed)

```
1. Copy this kit to your project
       ↓
2. Write your smart contract
       ↓
3. Test locally with Anvil
       ↓
4. Deploy to Previewnet (no tokens needed!)
       ↓
5. Deploy to Paseo testnet
       ↓
6. Build frontend, deploy to Bulletin
       ↓
7. Register .dot domain
       ↓
8. Deploy to Polkadot mainnet
```

### 5-Minute Quick Start

```bash
# 1. Create your project
mkdir my-polkadot-app && cd my-polkadot-app
git clone https://github.com/anthropics/polkadot-ai-starter-kit.git temp
cp -r temp/.claude temp/CLAUDE.md temp/.env.example temp/.gitignore .
rm -rf temp

# 2. Initialize Foundry
forge init --no-git
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

# 3. Start Claude Code
claude

# 4. Ask Claude to help you build!
# "Create a simple token contract and deploy to Previewnet"
```

---

## Quick Start (Detailed)

### 1. Copy to Your Project

```bash
# Clone this repo
git clone https://github.com/your-org/polkadot-ai-starter-kit.git

# Copy to your project
cp -r polkadot-ai-starter-kit/.claude /path/to/your/project/
cp polkadot-ai-starter-kit/CLAUDE.md /path/to/your/project/

# Customize CLAUDE.md for your project
```

### 2. Initialize Foundry (for Smart Contracts)

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Initialize in your project
forge init --no-git

# Install OpenZeppelin
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
```

### 3. Configure Environment

```bash
# Create .env (never commit this!)
cat > .env << 'EOF'
PRIVATE_KEY=0x...
ADMIN_ADDRESS=0x...
PASEO_RPC_URL=https://paseo-asset-hub-eth-rpc.polkadot.io
POLKADOT_RPC_URL=https://polkadot-asset-hub-eth-rpc.polkadot.io
EOF
```

## What's Included

```
.claude/
├── AGENTS.md                      # Agent constraints (READ FIRST)
├── SOURCES.md                     # Reference repos for skill updates
├── settings.local.json            # Permissions
├── skills/
│   ├── code-quality.md            # Minimal code philosophy
│   ├── testing.md                 # Test patterns (TypeScript)
│   ├── security.md                # Security baseline
│   ├── previewnet.md              # Ephemeral dev network
│   ├── asset-hub-evm.md           # Polkadot Asset Hub config
│   ├── upgradeable-contracts.md   # OpenZeppelin UUPS patterns
│   ├── deploy-contracts/          # Contract deployment
│   ├── deploy-frontend/           # Bulletin + DotNS deployment
│   ├── foundry-testing/           # Solidity test patterns
│   ├── mutation-testing/          # Stryker mutation testing
│   └── skill-creator/             # Create new skills
└── commands/
    └── sync-skills.md             # Skill sync workflow

CLAUDE.md                          # Project architecture template
```

## Polkadot Network Configuration

### Development Workflow

```
Local Anvil → Previewnet → Paseo → Mainnet
   (fast)    (no faucet)  (public)  (prod)
```

### Network Endpoints

| Network | RPC | Use Case |
|---------|-----|----------|
| Previewnet | `https://previewnet.substrate.dev/eth-rpc` | Development (pre-funded) |
| Paseo | `https://paseo-asset-hub-eth-rpc.polkadot.io` | Integration testing |
| Polkadot | `https://polkadot-asset-hub-eth-rpc.polkadot.io` | Production |

### Previewnet (Recommended for Development)

- **No faucet needed** - accounts are pre-funded
- **Ephemeral** - reset anytime
- **Full stack** - Asset Hub, People Chain, Bulletin, IPFS
- **Web UI**: https://previewnet.substrate.dev

### Get Paseo Testnet Tokens (for integration testing)

1. Get PAS from [Polkadot Faucet](https://faucet.polkadot.io)
2. Bridge to Asset Hub Paseo

## Skills Reference

### Polkadot-Specific

| Skill | Use When |
|-------|----------|
| `previewnet.md` | Local development, no faucet needed |
| `asset-hub-evm.md` | Deploying to Asset Hub, network config |
| `upgradeable-contracts.md` | UUPS proxy patterns, storage layout |
| `deploy-contracts/` | Contract deployment workflow |
| `deploy-frontend/` | Bulletin Chain + DotNS (requires PoP setup) |
| `host-api.md` | Triangle/Host API (early-stage, evolving) |
| `foundry-testing/` | Writing Solidity tests |

### General Development

| Skill | Use When |
|-------|----------|
| `code-quality.md` | Writing any code, refactoring |
| `testing.md` | TypeScript testing, coverage |
| `security.md` | Input validation, security review |
| `mutation-testing/` | Evaluating test effectiveness |

## Customization

### 1. Update CLAUDE.md

Edit for your project:
- Project name and description
- Directory structure
- Technology stack
- Domain-specific terminology

### 2. Add Domain Skills

Create new skills for your project domains:

```bash
mkdir .claude/skills/my-skill
```

Use the `skill-creator/` skill for guidance on structure.

### 3. Configure Permissions

Edit `.claude/settings.local.json` to auto-approve commands for your workflow.

## Deployment Workflow

### 1. Local Development (Anvil)

```bash
# Start local chain
anvil --chain-id 420420421

# Deploy (new terminal)
forge script script/Deploy.s.sol --rpc-url local --broadcast
```

### 2. Previewnet (No Tokens Needed)

```bash
# Pre-funded accounts - no .env required
forge script script/Deploy.s.sol \
  --rpc-url https://previewnet.substrate.dev/eth-rpc \
  --broadcast \
  --slow \
  -vvvv
```

### 3. Paseo Testnet (Integration Testing)

```bash
source .env
forge script script/Deploy.s.sol \
  --rpc-url paseo \
  --broadcast \
  --slow \
  -vvvv
```

### 4. Mainnet (Production)

```bash
source .env
forge script script/Deploy.s.sol \
  --rpc-url polkadot \
  --broadcast \
  --slow \
  -vvvv
```

## Frontend Deployment (Bulletin + DotNS)

Deploy your frontend to Polkadot's decentralized infrastructure with a `.dot` domain.

### First-Time Setup (Required)

```bash
cd /path/to/dotns-sdk/packages/cli

# 1. Set Personhood (REQUIRED - cannot skip)
bun run src/cli/index.ts pop set lite -m "$DOTNS_MNEMONIC"

# 2. Authorize for Bulletin storage
bun run src/cli/index.ts bulletin authorize <your-address> -m "$DOTNS_MNEMONIC"
```

### Deploy Frontend

```bash
# Build (ensure vite.config.ts has base: './')
pnpm build

# Upload to Bulletin
bun run src/cli/index.ts bulletin upload ./dist --parallel --print-contenthash -m "$DOTNS_MNEMONIC"

# Set content hash on domain
bun run src/cli/index.ts content set <domain-name> <cid> -m "$DOTNS_MNEMONIC"
```

See `deploy-frontend/` skill for full details.

## Example Project Structure (pnpm Monorepo)

```
my-polkadot-project/
├── .claude/                  # AI configuration (from this kit)
├── packages/
│   ├── contracts/            # Foundry project
│   │   ├── contracts/        # Solidity source
│   │   ├── script/           # Deployment scripts
│   │   ├── test/             # Foundry tests
│   │   ├── lib/              # Dependencies
│   │   └── foundry.toml
│   └── web/                  # Frontend (optional)
│       ├── src/
│       ├── vite.config.ts    # Must have base: './'
│       └── package.json
├── pnpm-workspace.yaml       # Workspace config
├── package.json              # Root scripts
├── CLAUDE.md
└── .env                      # Never commit!
```

### pnpm-workspace.yaml

```yaml
packages:
  - 'packages/*'
```

## Key Differences from Ethereum

1. **Native Token**: DOT (not ETH) - accessed via `msg.value`
2. **Gas Prices**: Generally lower than Ethereum mainnet
3. **Block Time**: ~6 seconds (faster than Ethereum)
4. **Block Explorer**: Use [Subscan](https://assethub-polkadot.subscan.io), not Etherscan
5. **Contract Verification**: Manual (no Etherscan API)

## Keeping Skills Updated

Skills are based on patterns from reference repositories. See `.claude/SOURCES.md` for:
- GitHub URLs for all reference repos
- Which skills come from which repos
- How to check for updates

```bash
# Quick update check
cd ~/polkadot-refs
for repo in */; do git -C "$repo" pull; done
```

## Resources

- [Previewnet](https://previewnet.substrate.dev) - Ephemeral dev network (no faucet needed)
- [Asset Hub Documentation](https://wiki.polkadot.network/docs/learn-guides-assets-create)
- [Polkadot Faucet](https://faucet.polkadot.io)
- [Paseo Subscan](https://paseo.subscan.io)
- [Foundry Book](https://book.getfoundry.sh)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)

### Reference Repositories

- [paritytech/product-infrastructure](https://github.com/paritytech/product-infrastructure) - Previewnet, deployment
- [paritytech/dotns-sdk](https://github.com/paritytech/dotns-sdk) - DotNS CLI, Bulletin
- [Agent-Skills-for-Context-Engineering](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering) - Skill patterns

## License

MIT
