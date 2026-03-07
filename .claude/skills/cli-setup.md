---
name: cli-setup
description: "Install CLI tools for Polkadot deployment. Triggers: install, setup, cli, p1p, dotns"
---

# CLI Setup for Polkadot Deployment

## When to Activate

- Setting up a new development environment
- Installing p1p CLI for secret management
- Installing dotns CLI for frontend deployment
- Troubleshooting CLI tool issues

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 22+ | Required for dotns CLI WebSocket support |
| Bun | Latest | Recommended runtime for dotns CLI |
| pnpm | 10+ | Package management |

## p1p CLI Installation (Secret Management)

The p1p CLI is part of the Polkadot Locker (polkadot-1p) project — a decentralized password manager for storing deployment secrets on-chain.

### Step 1: Clone the Repository

```bash
git clone https://github.com/paritytech/polkadot-1p.git
cd polkadot-1p
```

### Step 2: Install Dependencies

```bash
pnpm install
```

### Step 3: Build the CLI

```bash
pnpm -F @locker/cli build
```

### Step 4: Link Globally

```bash
cd packages/cli
npm link
```

### Step 5: Verify Installation

```bash
p1p --help
```

Expected output:
```
Usage: p1p [options] [command]

Polkadot Locker CLI - Decentralized password manager

Options:
  -V, --version   output the version number
  -h, --help      display help for command

Commands:
  signin          Sign in to your locker
  signout         Sign out and clear session
  ...
```

### First-Time Setup

```bash
# Sign in (creates session in OS keyring)
p1p signin --mnemonic

# Create a locker for your project
p1p locker create -n "my-project"

# Verify
p1p locker list
```

---

## dotns CLI Installation (Frontend Deployment)

The dotns CLI handles uploading to Bulletin Chain and registering `.dot` domains.

### Step 1: Clone the Repository

```bash
git clone https://github.com/paritytech/dotns-sdk.git
cd dotns-sdk
```

### Step 2: Install Dependencies

```bash
pnpm install
```

### Step 3: Build

```bash
pnpm build
```

### Step 4: Verify Installation

```bash
cd packages/cli
bun run src/cli/index.ts --help
```

**Note:** The dotns CLI is run from its source directory using `bun run`. It's not globally installed.

### First-Time Setup (Required Before Deployment)

```bash
cd /path/to/dotns-sdk/packages/cli

# 1. Set Personhood (REQUIRED before domain registration)
bun run src/cli/index.ts pop set lite -m "$DOTNS_MNEMONIC"

# 2. Verify PoP status
bun run src/cli/index.ts pop status -m "$DOTNS_MNEMONIC"

# 3. Authorize for Bulletin storage (REQUIRED before upload)
# First, find your Substrate address from the pop status output
bun run src/cli/index.ts bulletin authorize <your-substrate-address> -m "$DOTNS_MNEMONIC"
```

---

## Using p1p with dotns

Instead of storing mnemonics in environment variables, use p1p:

```bash
# Sign in to p1p
p1p signin --mnemonic

# Export mnemonic for dotns (memory-only, never written to disk)
export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)

# Use with dotns CLI
bun run src/cli/index.ts bulletin upload ./dist -m "$DOTNS_MNEMONIC"
```

See `p1p-secrets/SKILL.md` for full secret management workflow.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `p1p: command not found` | Run `npm link` from `packages/cli` directory |
| `Failed to load cache` | Run `rm -rf ~/.p1p` and sign in again |
| `Missing WebSocket class` | Use Node.js 22+ or Bun for dotns CLI |
| `Session expired` | Run `p1p signin --mnemonic` again (30-min TTL) |
| `PNPM_HOME not set` | Run `pnpm setup` and restart terminal |

## Version Check Commands

```bash
# Check Node.js version (must be 22+)
node --version

# Check Bun version
bun --version

# Check pnpm version
pnpm --version

# Check p1p is working
p1p status

# Check dotns CLI is working
cd /path/to/dotns-sdk/packages/cli
bun run src/cli/index.ts --help
```

## Updating CLIs

```bash
# Update p1p
cd /path/to/polkadot-1p
git pull
pnpm install
pnpm -F @locker/cli build

# Update dotns
cd /path/to/dotns-sdk
git pull
pnpm install
pnpm build
```
