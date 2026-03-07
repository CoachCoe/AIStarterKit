---
name: end-to-end-deployment
description: "Complete dApp deployment from zero to mainnet. Triggers: full deploy, end to end, complete workflow"
---

# End-to-End Deployment Guide

Deploy a complete Polkadot dApp: smart contracts + frontend + .dot domain.

## Prerequisites

Before starting, ensure you have:

- [ ] **CLI tools installed** — See `cli-setup.md`
- [ ] **Wallet funded** — PAS tokens on Asset Hub Paseo
- [ ] **p1p locker setup** — See `locker-structure.md`
- [ ] **PoP verified** — Personhood Lite set for your wallet
- [ ] **Bulletin authorized** — Your address authorized for uploads

## Deployment Pipeline

```
Local Dev (Anvil)
      ↓
Previewnet (no tokens needed)
      ↓
Paseo Testnet (integration)
      ↓
Mainnet (production)
```

---

## Phase 1: Local Development

### 1.1 Start Local Chain

```bash
# Terminal 1: Start Anvil
anvil --chain-id 420420421
```

### 1.2 Deploy Contracts Locally

```bash
# Terminal 2: Deploy
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

### 1.3 Run Frontend Locally

```bash
pnpm dev
```

### 1.4 Test Everything

```bash
# Run contract tests
forge test -vvv

# Run frontend tests
pnpm test
```

---

## Phase 2: Previewnet (No Tokens Needed)

Previewnet has pre-funded accounts — no faucet required.

### 2.1 Deploy Contracts

```bash
forge script script/Deploy.s.sol \
  --rpc-url https://previewnet.substrate.dev/eth-rpc \
  --broadcast \
  --slow \
  -vvvv
```

### 2.2 Update Frontend Config

```bash
# Update contract address in your .env or config
VITE_CONTRACT_ADDRESS=0x...  # From deployment output
```

### 2.3 Test Frontend Against Previewnet

```bash
pnpm dev
# Connect wallet and test all flows
```

---

## Phase 3: Paseo Testnet (Integration)

### 3.1 Setup Secrets with p1p

```bash
# Sign in to p1p
p1p signin --mnemonic

# Verify your locker has the required secrets
p1p item list -l "my-project"
```

### 3.2 Deploy Contracts

```bash
# Option A: Using p1p (recommended)
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol \
  --rpc-url paseo \
  --broadcast \
  --slow \
  -vvvv

# Option B: Using .env
source .env
forge script script/Deploy.s.sol \
  --rpc-url paseo \
  --broadcast \
  --slow \
  -vvvv
```

### 3.3 Record Deployed Addresses

Save the deployed contract addresses:

```bash
# Update your p1p locker with deployed addresses
p1p item create -l "my-project" -t "paseo-contracts" \
  --category custom \
  --field main_contract="0x..." \
  --field token_contract="0x..."
```

### 3.4 Build Frontend

```bash
# Ensure vite.config.ts has base: './'
pnpm build
```

### 3.5 Deploy Frontend to Bulletin

```bash
# Export mnemonic from p1p
export DOTNS_MNEMONIC=$(p1p read "p1p://my-project/dotns/customFields.mnemonic" -n)

# Upload to Bulletin
cd /path/to/dotns-sdk/packages/cli
bun run src/cli/index.ts bulletin upload /path/to/your/dist \
  --parallel --concurrency 5 --print-contenthash \
  -m "$DOTNS_MNEMONIC"
```

Save the CID from output.

### 3.6 Register Domain (First Time Only)

```bash
# Check if domain is available
bun run src/cli/index.ts lookup name my-app

# Register (if not already registered)
bun run src/cli/index.ts register domain --name my-app -m "$DOTNS_MNEMONIC"
```

### 3.7 Set Content Hash

```bash
bun run src/cli/index.ts content set my-app <CID> -m "$DOTNS_MNEMONIC"
```

### 3.8 Verify Deployment

- **Check domain**: `https://my-app.dot.li/`
- **Check content hash**: `bun run src/cli/index.ts content view my-app`

---

## Phase 4: Mainnet (Production)

### 4.1 Pre-Mainnet Checklist

- [ ] All tests passing on Paseo
- [ ] Security review completed
- [ ] Contract verified on Subscan (if applicable)
- [ ] Gas estimates reviewed
- [ ] Upgrade path tested (if upgradeable)
- [ ] Domain name finalized (cannot change after registration)

### 4.2 Deploy Contracts to Mainnet

```bash
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol \
  --rpc-url https://polkadot-asset-hub-eth-rpc.polkadot.io \
  --broadcast \
  --slow \
  -vvvv
```

### 4.3 Update Frontend for Mainnet

Update your frontend config:
- Contract addresses
- RPC endpoints
- Chain ID

### 4.4 Deploy Frontend to Mainnet Bulletin

```bash
# Build with mainnet config
VITE_NETWORK=mainnet pnpm build

# Upload
bun run src/cli/index.ts bulletin upload ./dist \
  --parallel --print-contenthash \
  -m "$DOTNS_MNEMONIC"

# Update content hash
bun run src/cli/index.ts content set my-app <CID> -m "$DOTNS_MNEMONIC"
```

---

## Environment Management

### Recommended Locker Structure

```
my-project/
├── dotns           → mnemonic (deployment wallet)
├── contracts       → private_key, deployer_address
├── paseo-config    → rpc_url, chain_id, contract addresses
└── mainnet-config  → rpc_url, chain_id, contract addresses
```

### .env.p1p Template

```env
# Secrets (from p1p locker)
PRIVATE_KEY=p1p://my-project/contracts/customFields.private_key
DEPLOYER_ADDRESS=p1p://my-project/contracts/customFields.deployer_address

# Network config
PASEO_RPC_URL=https://eth-rpc-testnet.polkadot.io
MAINNET_RPC_URL=https://polkadot-asset-hub-eth-rpc.polkadot.io
```

---

## Quick Reference Commands

### Contract Deployment

```bash
# Local
forge script script/Deploy.s.sol --rpc-url local --broadcast

# Previewnet
forge script script/Deploy.s.sol --rpc-url previewnet --broadcast --slow

# Paseo
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol --rpc-url paseo --broadcast --slow

# Mainnet
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol --rpc-url polkadot --broadcast --slow
```

### Frontend Deployment

```bash
# Build
pnpm build

# Upload to Bulletin
export DOTNS_MNEMONIC=$(p1p read "p1p://my-project/dotns/customFields.mnemonic" -n)
bun run src/cli/index.ts bulletin upload ./dist --parallel --print-contenthash -m "$DOTNS_MNEMONIC"

# Set content hash
bun run src/cli/index.ts content set <domain> <cid> -m "$DOTNS_MNEMONIC"

# Verify
bun run src/cli/index.ts content view <domain>
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Contract deployment fails | Use `--slow` flag, check gas |
| Frontend 404 on IPFS | Add `base: './'` to vite.config.ts |
| Domain registration fails | Verify PoP is set: `pop status` |
| Bulletin upload fails | Verify authorization: `bulletin authorize` |
| Content hash not updating | Wait 1-2 minutes for propagation |

## Related Skills

- `cli-setup.md` — Install p1p and dotns CLIs
- `deploy-contracts/SKILL.md` — Detailed contract deployment
- `deploy-frontend/SKILL.md` — Detailed frontend deployment
- `p1p-secrets/SKILL.md` — Secret management
- `locker-structure.md` — Recommended p1p locker organization
