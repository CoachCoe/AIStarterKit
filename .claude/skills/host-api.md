# Host API & Polkadot Triangle

## Context

Use when building Products for the Polkadot Triangle ecosystem (Desktop, Web, Mobile hosts).

**Status: Early Stage (v0.6) - APIs are evolving rapidly. Expect breaking changes.**

## Reference Implementation

**For working code and detailed patterns, see the `triangle-web-host-demo` repository.**

The CLAUDE.md in that repo (500+ lines) covers:
- SpektrManager API for container orchestration
- DotNS resolution with dual-chain racing
- Wallet authentication (Papp QR + browser extensions)
- Service Worker IPFS caching
- @novasamatech/* package usage

This skill provides a conceptual overview. For implementation details, use triangle-web-host-demo.

---

## What is the Triangle?

The Polkadot Triangle consists of three hosts that run sandboxed Products:

| Host | Platform | Role |
|------|----------|------|
| Polkadot App | Mobile (iOS/Android) | Identity holder, transaction signing |
| Polkadot Desktop | Desktop app | Development, full features |
| Polkadot.com | Web browser | Web access |

**Key Insight:** Products are sandboxed - no direct HTTP/HTTPS access. All external interactions go through Host API.

## Core Packages

```bash
# Install the SDK packages (use matching versions)
pnpm add @novasamatech/host-api@0.6.6-1
pnpm add @novasamatech/product-sdk@0.6.6-1
```

| Package | Purpose |
|---------|---------|
| `@novasamatech/host-api` | Protocol, types, error definitions, `toHex` utility |
| `@novasamatech/product-sdk` | Embedded-side SDK with providers and account management |

### Key SDK Exports

```typescript
import {
  sandboxProvider,      // Environment detection
  metaProvider,         // Host connection status
  createAccountsProvider, // Account management
  hostApi,              // Host API instance
} from "@novasamatech/product-sdk";

import { toHex } from "@novasamatech/host-api";
```

## Architecture Overview

```
┌─────────────────────────────────────────┐
│  Host (Desktop/Web/Mobile)              │
│  ┌───────────────────────────────────┐  │
│  │  Product (Your dApp in iframe)    │  │
│  │  - No direct network access       │  │
│  │  - Uses Host API for everything   │  │
│  │  - @novasamatech/product-sdk      │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  Host Container                   │  │
│  │  - @novasamatech/host-container   │  │
│  │  - Accounts, Signing, Storage     │  │
│  │  - JSON-RPC proxy to chains       │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  Light Client / RPC               │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Implementation Patterns

### Environment Detection

```typescript
// lib/host/detect.ts
import { sandboxProvider, metaProvider } from "@novasamatech/product-sdk";

let connectionStatus: "disconnected" | "connecting" | "connected" = "disconnected";

// Subscribe to connection status (run once at module load)
if (typeof window !== "undefined" && sandboxProvider.isCorrectEnvironment()) {
  metaProvider.subscribeConnectionStatus((status) => {
    connectionStatus = status;
  });
}

export function isHosted(): boolean {
  if (typeof window === "undefined") return false;
  return sandboxProvider.isCorrectEnvironment();
}

export function isHostConnected(): boolean {
  return connectionStatus === "connected";
}
```

### Account Management

```typescript
import { createAccountsProvider, metaProvider } from "@novasamatech/product-sdk";

const accountsProvider = createAccountsProvider();

// Method 1: Get non-product accounts (works without product registration)
const result = await accountsProvider.getNonProductAccounts();
result.match(
  (accounts) => {
    if (accounts.length > 0) {
      const { publicKey, name } = accounts[0];
      // Use account...
    }
  },
  (error) => console.error(error)
);

// Method 2: Get product-specific account (requires user sign-in)
const result = await accountsProvider.getProductAccount("my-domain", 0);
result.match(
  (acc) => {
    // acc.publicKey: Uint8Array
    // acc.name: string | undefined
  },
  (error) => {
    // User may need to sign in to Triangle Host
  }
);
```

### Connection Status Flow

1. **Meta connection** (`metaProvider.subscribeConnectionStatus`) - Host <-> Product communication
2. **Account connection** (`accountsProvider.subscribeAccountConnectionStatus`) - Account availability

**Important:** User must **sign in to Triangle Host** for accounts to be available. If `getNonProductAccounts()` returns 0 accounts, the user needs to sign in first.

### Known Issues

| Issue | Cause | Workaround |
|-------|-------|------------|
| `getProductAccount` hangs | User not signed in | Check `getNonProductAccounts()` first |
| 0 accounts returned | User not signed in to Host | Show "Sign in to Triangle" message |
| People Chain WebSocket fails | Previewnet infrastructure | Wait/retry, report to Triangle team |

## Key Concepts

### Sandboxed Products

Products run in iframes with no direct network access. The host provides:
- Account injection via `window.injectedWeb3.spektr`
- Signing delegation to Polkadot App or browser extensions
- JSON-RPC proxy for chain access
- Scoped localStorage per product

### Derived Accounts (Privacy Model)

Each Product gets its own derived account from the user's root identity:
- Accounts are **unlinkable by default** - no cross-product tracking
- User can optionally link accounts for public reputation

### DotNS Resolution

Products are loaded from IPFS via `.dot` domain resolution:
1. Query dotNS resolver for contenthash
2. Fetch from IPFS gateway
3. Cache in Service Worker
4. Serve in sandboxed iframe

## What's Available Now

| Feature | Status | Notes |
|---------|--------|-------|
| Product deployment | ✅ Working | Via Bulletin + dotNS |
| Account/signing | ✅ Working | Papp (QR) or browser extensions |
| Local storage | ✅ Working | Key-value, scoped per product |
| Localhost dev | ✅ Working | Search `localhost:3000` in Desktop |
| Chain queries | ✅ Working | Via Host API proxy |

## What's Not Ready Yet

| Feature | Status | Notes |
|---------|--------|-------|
| Auto-signing | 🚧 Planned | Currently need approval for every tx |
| Chat integration | 🚧 Stubs only | API defined but not implemented |
| Notifications | 🚧 Planned | Push notifications to products |
| Fine-grained permissions | 🚧 Planned | Per-extrinsic approval |

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Direct HTTP/fetch calls | FORBIDDEN | Sandboxed, will fail |
| Bundling light client | FORBIDDEN | Host provides chain access |
| Assuming stable API | RISKY | APIs changing rapidly |
| Building for all 3 hosts | RISKY | Focus on Desktop first |

## Development Workflow

1. **Build your Product** - Standard web app with `@novasamatech/product-sdk`
2. **Deploy to Bulletin** - See `deploy-frontend/` skill for dotNS setup
3. **Test in Desktop** - Search for your `.dot` domain or `localhost:3000`

## Resources

- **triangle-web-host-demo** - Complete reference implementation
- [Triangle SDK Sandbox](https://spektr-sdk-sandbox-dev.novaspektr.io/) - Live demo

## Versioning

SDK and Host versions must match:
```
@novasamatech/* 0.6.1 <-> Desktop build 0.6.x
```
