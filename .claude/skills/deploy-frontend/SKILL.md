---
name: deploy-frontend
description: "Deploy frontend to Bulletin Chain + DotNS. Triggers: deploy frontend, bulletin, dotns, .dot domain, decentralized hosting"
---

# Deploy Frontend to Bulletin Chain + DotNS

## When to Activate

- Deploying frontend to decentralized storage
- Registering a .dot domain
- Updating content on an existing domain
- Setting up personhood verification

## Global Invariants

| Rule | Enforcement |
|------|-------------|
| Set Personhood (PoP) before domain registration | REQUIRED |
| Authorize for Bulletin before upload | REQUIRED |
| Use `base: './'` in Vite config | REQUIRED (IPFS-compatible paths) |
| Never commit mnemonic | FORBIDDEN |

## Prerequisites

1. **Node.js 22+** or **Bun** (for WebSocket support)
2. **dotns CLI** - Install from https://github.com/nickreynolds/dotns-sdk
3. **Wallet with PAS tokens** on Asset Hub Paseo
4. **Vite config** with `base: './'` for IPFS-compatible relative paths

## Chains Involved

| Chain | Purpose | Endpoint |
|-------|---------|----------|
| Asset Hub Paseo | Domain registration, content hash | `wss://asset-hub-paseo-rpc.n.dwellir.com` |
| Bulletin Paseo | Decentralized storage | `wss://bulletin.dotspark.app` |

## First-Time Setup (REQUIRED)

### Step 1: Set Personhood (PoP) Lite

**This is REQUIRED before domain registration. Cannot skip this step.**

```bash
cd /path/to/dotns-sdk/packages/cli

# Set PoP Lite verification
bun run src/cli/index.ts pop set lite -m "$DOTNS_MNEMONIC"
```

Verify PoP status:
```bash
bun run src/cli/index.ts pop status -m "$DOTNS_MNEMONIC"
```

### Step 2: Authorize for Bulletin Storage

**This is REQUIRED before uploading to Bulletin. Self-service authorization.**

```bash
# First, find your Substrate address (run any command to see it)
bun run src/cli/index.ts --help

# Authorize yourself for Bulletin storage
bun run src/cli/index.ts bulletin authorize <your-substrate-address> -m "$DOTNS_MNEMONIC"
```

## Authentication Methods

```bash
# Option 1: p1p (recommended - decentralized secret storage)
# Requires: p1p CLI installed and signed in (p1p signin --mnemonic)
export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)
# Then use: -m "$DOTNS_MNEMONIC"

# Option 2: Mnemonic (direct)
--mnemonic "your 12 word mnemonic here"
# or
-m "$DOTNS_MNEMONIC"

# Option 3: Keystore (for repeated use)
export DOTNS_KEYSTORE_PATH=~/.dotns/keystore
export DOTNS_KEYSTORE_PASSWORD=your-password
dotns auth set --account default --mnemonic "your 12 words..."

# Option 4: Dev key URI (testing only - Previewnet)
--key-uri //Alice
```

**p1p Setup (one-time):**
```bash
# Sign in to p1p
p1p signin --mnemonic

# Store your dotns mnemonic
p1p locker create -n "my-deployment"
p1p item create -l "my-deployment" -t "dotns" \
  --category custom \
  --field mnemonic="your 12 word mnemonic"
```

## Deployment Workflow

### Step 1: Build Frontend

```bash
# Ensure Vite config has base: './'
pnpm run build
# Output: dist/
```

### Step 2: Check Domain Status

```bash
bun run src/cli/index.ts lookup name <domain-name>
```

### Step 3: Register Domain (if not registered)

```bash
bun run src/cli/index.ts register domain \
  --name <domain-label> \
  -m "$DOTNS_MNEMONIC"
```

**Domain naming rules:**
- `myapp` → `myapp.dot`
- `my-app` → `my-app.dot` (hyphens allowed)
- Reserved names (≤5 chars) require `--governance` flag

### Step 4: Upload to Bulletin Chain

```bash
bun run src/cli/index.ts bulletin upload \
  ./dist \
  --parallel \
  --concurrency 5 \
  --print-contenthash \
  -m "$DOTNS_MNEMONIC"
```

**Output:**
```
CID: bafybeig...
ContentHash: 0xe3010170...
```

Save the CID for the next step.

### Step 5: Set Content Hash on Domain

```bash
bun run src/cli/index.ts content set <domain-name> <cid> \
  -m "$DOTNS_MNEMONIC"
```

### Step 6: Verify Deployment

```bash
# Check content hash is set
bun run src/cli/index.ts content view <domain-name>
```

**Access your site:**
- **dot.li (recommended):** `https://<domain-name>.dot.li/` (client-side resolution, no proxy)
- Paseo gateway: `https://<domain-name>.paseo.li/`
- IPFS gateway: `https://ipfs.io/ipfs/<cid>`
- dweb.link: `https://dweb.link/ipfs/<cid>`

**See also:** `dotli.md` skill for understanding client-side resolution architecture.

## Vite Configuration

**REQUIRED** for IPFS-compatible paths:

```typescript
// vite.config.ts
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',  // REQUIRED for IPFS/Bulletin
  // ... rest of config
});
```

## Environment Variables

```bash
# Option A: Use p1p (recommended - no .env file needed)
export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)

# Option B: Add to .env (NEVER COMMIT)
DOTNS_MNEMONIC="your 12 word mnemonic"

# Optional
DOTNS_RPC=wss://asset-hub-paseo-rpc.n.dwellir.com
DOTNS_KEYSTORE_PATH=~/.dotns/keystore
DOTNS_KEYSTORE_PASSWORD=your-password
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| "Requires Personhood Lite verification" | Run `pop set lite` (see First-Time Setup) |
| "Account is not authorized for Bulletin" | Run `bulletin authorize` (see First-Time Setup) |
| Assets return 404 on IPFS | Add `base: './'` to Vite config, rebuild |
| "Missing WebSocket class" | Use Node.js 22+ or Bun |
| "Insufficient balance" | Get PAS from faucet, bridge to Asset Hub |
| Domain already registered | Check owner: `dotns lookup owner-of <domain>` |

## Common Commands Reference

```bash
# View content hash on domain
bun run src/cli/index.ts content view <domain-name>

# View upload history
bun run src/cli/index.ts bulletin history

# Check PoP status
bun run src/cli/index.ts pop status -m "$DOTNS_MNEMONIC"

# Lookup domain info
bun run src/cli/index.ts lookup name <domain-name>
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Register new domain without explicit request | FORBIDDEN | Only register domains when user explicitly asks |
| Skip PoP setup | FORBIDDEN | Domain registration will fail |
| Skip Bulletin authorization | FORBIDDEN | Upload will fail |
| Commit mnemonic to git | FORBIDDEN | Security risk |
| Use absolute paths in build | FORBIDDEN | Breaks on IPFS gateways |
| Deploy to mainnet first | FORBIDDEN | Test on Paseo first |
