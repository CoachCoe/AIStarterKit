---
name: locker-structure
description: "Recommended p1p locker organization for Polkadot projects. Triggers: locker, secrets organization, team setup"
---

# Recommended Locker Structure

Organize your p1p locker for Polkadot dApp development and deployment.

## When to Activate

- Setting up secrets for a new project
- Organizing deployment credentials
- Setting up team access to shared secrets
- Managing multi-environment configurations

## Single Developer Setup

For individual developers working on one project:

```
<project-name>/
├── dotns
│   └── mnemonic           → Deployment wallet mnemonic
├── contracts
│   ├── private_key        → Contract deployer private key (0x...)
│   └── deployer_address   → Deployer wallet address (0x...)
├── walletconnect
│   └── project_id         → WalletConnect project ID (optional)
└── config
    ├── paseo_rpc_url      → Paseo RPC endpoint
    └── mainnet_rpc_url    → Mainnet RPC endpoint
```

### Setup Commands

```bash
# Sign in
p1p signin --mnemonic

# Create locker
p1p locker create -n "my-project"

# Add DotNS mnemonic
p1p item create -l "my-project" -t "dotns" \
  --category custom \
  --field mnemonic="your 12 word mnemonic here"

# Add contract deployment credentials
p1p item create -l "my-project" -t "contracts" \
  --category custom \
  --field private_key="0x..." \
  --field deployer_address="0x..."

# Add optional config
p1p item create -l "my-project" -t "config" \
  --category custom \
  --field paseo_rpc_url="https://eth-rpc-testnet.polkadot.io" \
  --field mainnet_rpc_url="https://polkadot-asset-hub-eth-rpc.polkadot.io"
```

---

## Multi-Project Setup

For developers working on multiple projects:

```
deployment/                    # Shared deployment wallet
├── dotns
│   └── mnemonic
└── contracts
    ├── private_key
    └── deployer_address

project-a/                     # Project-specific config
├── paseo
│   ├── contract_address
│   └── token_address
└── mainnet
    ├── contract_address
    └── token_address

project-b/
├── paseo
│   └── contract_address
└── mainnet
    └── contract_address
```

### Advantages

- **Shared credentials** — Same deployment wallet across projects
- **Project isolation** — Each project tracks its own contract addresses
- **Environment separation** — Clear distinction between testnet and mainnet

---

## Team Setup

For teams sharing deployment credentials:

### Option 1: Shared Locker (Same Wallet)

All team members sign in with the same deployment wallet mnemonic.

```bash
# Each team member signs in with the shared mnemonic
p1p signin --mnemonic
# Enter the team's deployment wallet mnemonic
```

**Pros:** Simple, everyone has same access
**Cons:** Shared mnemonic is a security risk

### Option 2: Individual Lockers + p1p Sharing (Recommended)

Each team member has their own locker, secrets are shared via p1p's X25519 encryption.

```bash
# Team lead creates and shares
p1p share create -l "team-deployment" -t "dotns" --to <teammate-address>

# Teammate accepts
p1p share accept <share-id>
```

**Pros:** Individual accountability, revocable access
**Cons:** More setup required

---

## CI/CD Setup

For automated deployments in GitHub Actions:

### Store Seed in GitHub Secrets

```yaml
# In GitHub repository settings, add:
# MNEMONIC = your deployment wallet mnemonic
```

### Workflow Usage

```yaml
- name: Sign in to p1p
  run: p1p signin --seed "${{ secrets.MNEMONIC }}"

- name: Deploy with secrets
  run: |
    export DOTNS_MNEMONIC=$(p1p read "p1p://my-project/dotns/customFields.mnemonic" -n)
    # Use $DOTNS_MNEMONIC in deployment commands
```

### Alternative: Direct p1p run

```yaml
- name: Deploy contracts
  run: p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol --broadcast
```

---

## .env.p1p Template

Create this file in your project root (safe to commit):

```env
# .env.p1p - Secret references (resolved at runtime)

# Contract deployment
PRIVATE_KEY=p1p://my-project/contracts/customFields.private_key
DEPLOYER_ADDRESS=p1p://my-project/contracts/customFields.deployer_address

# DotNS deployment (read separately, not via p1p run)
# DOTNS_MNEMONIC=p1p://my-project/dotns/customFields.mnemonic

# Network config (can also be static values)
PASEO_RPC_URL=https://eth-rpc-testnet.polkadot.io
MAINNET_RPC_URL=https://polkadot-asset-hub-eth-rpc.polkadot.io
```

---

## Reading Secrets

### For Contract Deployment (via p1p run)

```bash
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol --broadcast
```

### For DotNS CLI (via export)

```bash
export DOTNS_MNEMONIC=$(p1p read "p1p://my-project/dotns/customFields.mnemonic" -n)
bun run src/cli/index.ts bulletin upload ./dist -m "$DOTNS_MNEMONIC"
```

### For Single Values

```bash
# Read to stdout
p1p read "p1p://my-project/contracts/customFields.deployer_address"

# Copy to clipboard (auto-clears in 30s)
p1p read "p1p://my-project/contracts/customFields.private_key" --clipboard
```

---

## URI Reference

**Format:** `p1p://[locker]/[item]/[field]`

| Field Type | URI Pattern | Example |
|------------|-------------|---------|
| Standard field | `p1p://locker/item/password` | Built-in field |
| Custom field | `p1p://locker/item/customFields.key` | User-defined field |

### Common URIs

```bash
# DotNS mnemonic
p1p://my-project/dotns/customFields.mnemonic

# Contract private key
p1p://my-project/contracts/customFields.private_key

# Deployer address
p1p://my-project/contracts/customFields.deployer_address

# WalletConnect project ID
p1p://my-project/walletconnect/customFields.project_id
```

---

## Security Best Practices

| Practice | Status |
|----------|--------|
| Never commit plaintext secrets | REQUIRED |
| Use `.env.p1p` templates (safe to commit) | REQUIRED |
| Sign out when done (`p1p signout`) | RECOMMENDED |
| Use separate wallets for testnet vs mainnet | RECOMMENDED |
| Rotate keys periodically | RECOMMENDED |
| Use p1p sharing instead of sharing mnemonics | RECOMMENDED |

## Related Skills

- `cli-setup.md` — Install p1p CLI
- `p1p-secrets/SKILL.md` — Full secret management workflow
- `end-to-end-deployment.md` — Complete deployment guide
