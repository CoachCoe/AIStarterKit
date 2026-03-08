# Quick Start

Get building on Polkadot in 5 minutes.

---

## For Developers

### One-Command Setup

```bash
# Clone the repo
git clone <repo-url> && cd AIStarterKit

# Create a Triangle host app
./scripts/init.sh my-app
cd my-app
npm run dev    # → http://localhost:8000

# Or create a smart contracts project
./scripts/init.sh my-contracts --contracts
cd my-contracts
forge test
```

### Option 1: Build a Triangle Host App

```bash
./scripts/init.sh my-app
cd my-app
npm run dev    # → http://localhost:8000
```

**What you get:**
- Working Host API integration
- Account detection & signing
- Host storage (read/write/clear)
- Chain queries
- Ready to deploy

**Deploy:**
```bash
npm run build
export DOTNS_MNEMONIC="your mnemonic..."
./deploy.sh my-app   # → https://my-app.dot.li
```

### Option 2: Build Smart Contracts

```bash
./scripts/init.sh my-contracts --contracts
cd my-contracts
```

**What you get:**
- UUPS upgradeable Counter contract
- OpenZeppelin contracts installed
- Foundry configured for Asset Hub
- Deploy script ready

**Test:**
```bash
forge test -vvv
```

**Deploy:**
```bash
cp .env.example .env   # Add your private key
source .env
forge script script/Deploy.s.sol --rpc-url paseo --broadcast
```

---

## For AI Agents

### Read Order

1. **`.claude/AGENTS.md`** - Safety boundaries and constraints (READ FIRST)
2. **`CLAUDE.md`** - Architecture and coding standards
3. **`.claude/skills/INDEX.md`** - Find the right skill for your task
4. **Load relevant skill** - Then start implementation

### Skill Loading Protocol

Before ANY implementation work:

| Task | Load These Skills |
|------|-------------------|
| Smart contracts | `upgradeable-contracts.md` + `foundry-testing/` |
| Contract deployment | `deploy-contracts/` + `asset-hub-evm.md` |
| Triangle/Host app | `triangle/OVERVIEW.md` first |
| Frontend deployment | `deploy-frontend/` |
| Secrets management | `p1p-secrets/` |

### Verification Before Completing

**Contracts:**
```bash
forge build && forge test && forge fmt --check
```

**Frontend:**
```bash
npm run build && npm run lint && npm test
```

---

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Architecture, standards |
| `.claude/AGENTS.md` | Agent constraints |
| `.claude/skills/INDEX.md` | Skill discovery |
| `.claude/skills/*.md` | Domain knowledge |
| `templates/` | Working starter code |

---

## Network Progression

```
Local Anvil → Previewnet → Paseo → Mainnet
   (fast)    (no faucet)  (public)  (prod)
```

| Network | RPC | Use Case |
|---------|-----|----------|
| Previewnet | `https://previewnet.substrate.dev/eth-rpc` | Development (pre-funded) |
| Paseo | `https://paseo-asset-hub-eth-rpc.polkadot.io` | Integration testing |
| Polkadot | `https://polkadot-asset-hub-eth-rpc.polkadot.io` | Production |

---

## Next Steps

- **Building a dApp?** → Read `triangle/OVERVIEW.md`
- **Writing contracts?** → Read `upgradeable-contracts.md`
- **Deploying?** → Read `deploy-contracts/` or `deploy-frontend/`
- **Managing secrets?** → Read `p1p-secrets/`
