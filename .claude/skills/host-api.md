# Host API & Polkadot Triangle

## Context

Use when building Products for the Polkadot Triangle ecosystem (Desktop, Web, Mobile hosts).

**Status: Early Stage (v0.5) - APIs are evolving rapidly. Expect breaking changes.**

## What is the Triangle?

The Polkadot Triangle consists of three hosts that run sandboxed Products:

| Host | Platform | Role |
|------|----------|------|
| Polkadot App | Mobile (iOS/Android) | Identity holder, transaction signing |
| Polkadot Desktop | Desktop app | Development, full features |
| Polkadot.com | Web browser | Web access |

**Key Insight:** Products are sandboxed - no direct HTTP/HTTPS access. All external interactions go through Host API.

## Core Concepts

### Sandboxed Products

```
┌─────────────────────────────────────────┐
│  Host (Desktop/Web/Mobile)              │
│  ┌───────────────────────────────────┐  │
│  │  Product (Your dApp)              │  │
│  │  - No direct network access       │  │
│  │  - Uses Host API for everything   │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  Host API Layer                   │  │
│  │  - Accounts, Signing, Storage     │  │
│  │  - Chain access, Chat, Statements │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  Light Client / Polkadot Infra    │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Derived Accounts (Privacy Model)

Each Product gets its own derived account from the user's root identity:

- User has ONE root identity (from Polkadot App)
- Each Product gets a unique derived account: `/product/{productId}/{index}`
- Accounts are **unlinkable by default** - no cross-product tracking
- User can optionally link accounts if they want public reputation

```
Root Identity (never exposed)
    │
    ├── //wallet (registered on-chain)
    │
    ├── /hackm3 (HackM3 app account)
    ├── /mark3t (Market app account)
    └── /tick3t (Ticketing app account)
```

### Session Keys (Current Workaround)

Until auto-signing is implemented, Products use session keys to avoid requiring phone approval for every transaction:

1. User approves session key creation (one-time, on phone)
2. Product uses session key for subsequent transactions
3. Session key has limited permissions/lifetime

## Development Workflow

### 1. Deploy Product to Bulletin

Use dotNS CLI to deploy your built frontend:

```bash
# Build with base: './' for IPFS compatibility
pnpm build

# Upload to Bulletin (requires PoP setup first!)
bun run src/cli/index.ts bulletin upload ./dist --parallel -m "$DOTNS_MNEMONIC"

# Set content hash on domain
bun run src/cli/index.ts content set <domain> <cid> -m "$DOTNS_MNEMONIC"
```

### 2. Test in Polkadot Desktop

```bash
# Download Polkadot Desktop from releases
# https://github.com/nickreynolds/nickreynolds.github.io/releases (TBD: official URL)

# For local development, search for:
localhost:3000
```

### 3. Install Product SDK

```bash
pnpm add @polkadot-triangle/product-sdk
```

### 4. Basic Integration

```typescript
import { ProductSdk } from '@polkadot-triangle/product-sdk';

// Check if running inside host
const isInHost = await ProductSdk.isConnected();

// Get user account (derived for your product)
const account = await ProductSdk.getAccount();

// Sign transaction (prompts user on Polkadot App)
const signature = await ProductSdk.signTransaction(payload);

// Local storage (scoped to your product)
await ProductSdk.localStorage.write('key', value);
const data = await ProductSdk.localStorage.read('key');
```

## What's Available Now

| Feature | Status | Notes |
|---------|--------|-------|
| Product deployment | ✅ Working | Via Bulletin + dotNS |
| Account/signing | ✅ Working | Requires phone approval each time |
| Local storage | ✅ Working | Key-value, scoped per product |
| Localhost dev | ✅ Working | Search `localhost:3000` in Desktop |
| Chain queries | ✅ Working | Via Host API, not direct RPC |

## What's Not Ready Yet

| Feature | Status | Notes |
|---------|--------|-------|
| Auto-signing | 🚧 Planned | Currently need phone for every tx |
| Chat integration | 🚧 Stubs only | API defined but not implemented |
| Notifications | 🚧 Planned | Push notifications to products |
| Fine-grained permissions | 🚧 Planned | Per-extrinsic approval |
| Background sync | 🚧 Planned | Cross-device data sync |
| P2P networking | 🚧 Planned | Direct product-to-product |

## Product Onboarding Pattern

From HackM3's experience - check these on app load:

```typescript
async function checkOnboarding() {
  // 1. Is user connected via Polkadot App?
  const connected = await ProductSdk.isConnected();

  // 2. Does signer have balance for fees?
  const balance = await getSignerBalance();

  // 3. Is address mapped (Substrate <-> Ethereum)?
  const mapped = await checkAddressMapping();

  // 4. Session key created and funded?
  const sessionKey = await checkSessionKey();

  // 5. Statement store allowance?
  const allowance = await checkStatementStoreAllowance();

  // Redirect to onboarding if any step incomplete
  if (!connected || !balance || !mapped || !sessionKey || !allowance) {
    redirectToOnboarding();
  }
}
```

## Reference Repositories

| Repo | Purpose |
|------|---------|
| [triangle-js-sdks](https://github.com/nickreynolds/nickreynolds.github.io) | Product SDK, Host SDK |
| [polkadot-browser](https://github.com/nickreynolds/nickreynolds.github.io) | Desktop app source |
| Product SDK test app | Search `test-product-sdk-33.dot` in Desktop |

## Key Differences from Traditional dApps

| Traditional | Triangle Product |
|-------------|------------------|
| Direct RPC to nodes | All chain access via Host API |
| Browser extension wallets | Polkadot App only |
| User selects account | Derived account per product |
| Direct HTTP requests | All external requests blocked |
| IndexedDB, localStorage | Host-managed storage |

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Direct HTTP/fetch calls | FORBIDDEN | Sandboxed, will fail |
| Using browser extensions | FORBIDDEN | Only Polkadot App works |
| Bundling light client | FORBIDDEN | Host provides chain access |
| Assuming stable API | RISKY | APIs changing rapidly |
| Building for all 3 hosts | RISKY | Focus on Desktop first |

## Resources

- [Host API PRD](https://docs.google.com/document/d/...) - Product requirements
- [Host API Design Doc](https://hackmd.io/@example/...) - Technical spec
- [Triangle SDK Sandbox](https://spektr-sdk-sandbox-dev.novaspektr.io/) - Live demo
- Desktop channel (internal) - Daily build updates

## Versioning Note

Product SDK and Host versions must match. Check Desktop channel for latest compatible versions.

```
Product SDK 0.54 <-> Desktop build 0.54
```

When Desktop updates, expect to update Product SDK dependency.
