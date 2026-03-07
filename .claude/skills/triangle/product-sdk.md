# Product SDK - Building Embedded Products

## Context

Use when building a **product** (dapp) that runs inside a Triangle host. Products are sandboxed iframes with no direct network access - all interactions go through the Host API.

**Prerequisites:** Read `triangle/OVERVIEW.md` first.

## Core Concept: Sandboxed Execution

```
┌─────────────────────────────────────────────────────────────────┐
│  Your Product (iframe)                                           │
│  ├── NO direct HTTP/fetch calls (will fail)                     │
│  ├── NO bundled light client (host provides chain access)       │
│  ├── Accounts injected via window.injectedWeb3.spektr           │
│  └── Chain access via Host API JSON-RPC proxy                   │
└─────────────────────────────────────────────────────────────────┘
```

## Installation

```bash
pnpm add @novasamatech/product-sdk@0.6.6-1
pnpm add @novasamatech/host-api@0.6.6-1
```

## Key SDK Exports

```typescript
import {
  sandboxProvider,          // Environment detection
  metaProvider,             // Host connection status
  createAccountsProvider,   // Account management
  hostApi,                  // Host API instance
} from '@novasamatech/product-sdk';

import { toHex } from '@novasamatech/host-api';
```

## Environment Detection

```typescript
// lib/host/detect.ts
import { sandboxProvider, metaProvider } from '@novasamatech/product-sdk';

let connectionStatus: 'disconnected' | 'connecting' | 'connected' = 'disconnected';

// Subscribe to connection status (run once at module load)
if (typeof window !== 'undefined' && sandboxProvider.isCorrectEnvironment()) {
  metaProvider.subscribeConnectionStatus((status) => {
    connectionStatus = status;
  });
}

export function isHosted(): boolean {
  if (typeof window === 'undefined') return false;
  return sandboxProvider.isCorrectEnvironment();
}

export function isHostConnected(): boolean {
  return connectionStatus === 'connected';
}
```

## Account Management

```typescript
import { createAccountsProvider } from '@novasamatech/product-sdk';

const accountsProvider = createAccountsProvider();

// Method 1: Get non-product accounts (works without product registration)
const result = await accountsProvider.getNonProductAccounts();
result.match(
  (accounts) => {
    if (accounts.length > 0) {
      const { publicKey, name } = accounts[0];
      // publicKey: Uint8Array
      // name: string | undefined
    }
  },
  (error) => console.error(error)
);

// Method 2: Get product-specific account (requires user sign-in)
const result = await accountsProvider.getProductAccount('my-domain', 0);
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

## Connection Status Flow

1. **Meta connection** (`metaProvider.subscribeConnectionStatus`) - Host ↔ Product communication
2. **Account connection** (`accountsProvider.subscribeAccountConnectionStatus`) - Account availability

**Important:** User must **sign in to Triangle Host** for accounts to be available. If `getNonProductAccounts()` returns 0 accounts, the user needs to sign in first.

## Using the Injected Extension

```typescript
// Products receive accounts via the spektr extension
async function initializeWallet() {
  // Wait for host to inject extension
  if (!window.injectedWeb3?.spektr) {
    console.log('Not running in Triangle host');
    return;
  }

  const extension = await window.injectedWeb3.spektr.enable('My Product Name');

  // Get accounts
  const accounts = await extension.accounts.get();
  console.log('Available accounts:', accounts);

  // Sign a transaction
  const signer = extension.signer;
  const result = await signer.signPayload({
    address: accounts[0].address,
    // ... transaction payload
  });
}
```

## Chain Access via Host

Products don't have direct network access. Use polkadot-api with the host's JSON-RPC proxy:

```typescript
import { createClient } from 'polkadot-api';
import { getSmProvider } from 'polkadot-api/sm-provider';
import { hostApi } from '@novasamatech/product-sdk';

// The host provides a JSON-RPC provider for supported chains
const client = createClient(
  getSmProvider(hostApi.getChainProvider(genesisHash))
);
```

## Derived Accounts (Privacy Model)

Each Product gets its own derived account from the user's root identity:

- Accounts are **unlinkable by default** - no cross-product tracking
- User can optionally link accounts for public reputation
- Use `getProductAccount()` for product-specific derived accounts
- Use `getNonProductAccounts()` for shared wallet accounts

## React Integration Pattern

```typescript
// hooks/use-triangle-account.ts
import { useState, useEffect } from 'react';
import { sandboxProvider, createAccountsProvider, metaProvider } from '@novasamatech/product-sdk';

export function useTriangleAccount() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [isHosted, setIsHosted] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<string>('disconnected');

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const hosted = sandboxProvider.isCorrectEnvironment();
    setIsHosted(hosted);

    if (!hosted) return;

    // Subscribe to connection status
    const unsubMeta = metaProvider.subscribeConnectionStatus(setConnectionStatus);

    // Get accounts when connected
    const accountsProvider = createAccountsProvider();
    const unsubAccounts = accountsProvider.subscribeAccountConnectionStatus(async (status) => {
      if (status === 'connected') {
        const result = await accountsProvider.getNonProductAccounts();
        result.match(setAccounts, console.error);
      }
    });

    return () => {
      unsubMeta();
      unsubAccounts();
    };
  }, []);

  return { accounts, isHosted, connectionStatus };
}
```

## Local Storage (Scoped)

The host scopes localStorage per product. Use it normally:

```typescript
// This is automatically scoped to your product
localStorage.setItem('user-preference', 'dark');
const pref = localStorage.getItem('user-preference');
```

The host prefixes keys: `product:{productId}:{key}`

## Graceful Degradation

Products should work both in Triangle hosts and standalone:

```typescript
function initializeApp() {
  if (isHosted()) {
    // Running in Triangle - use host APIs
    initializeWithHostApi();
  } else {
    // Standalone mode - use direct connections
    initializeStandalone();
  }
}
```

## Known Issues & Workarounds

| Issue | Cause | Workaround |
|-------|-------|------------|
| `getProductAccount` hangs | User not signed in | Check `getNonProductAccounts()` first |
| 0 accounts returned | User not signed in to Host | Show "Sign in to Triangle" message |
| People Chain WebSocket fails | Previewnet infrastructure | Wait/retry, report to Triangle team |
| `fetch` fails | Sandbox restriction | Use host-provided APIs only |

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Direct `fetch()` calls | FORBIDDEN | Sandboxed - will fail |
| Bundling light client | FORBIDDEN | Host provides chain access |
| Assuming accounts exist | RISKY | User may not be signed in |
| Hardcoding chain endpoints | FORBIDDEN | Must use host's provider |
| Using `window.ethereum` | FORBIDDEN | Not injected in Triangle |
| Not checking `isHosted()` | RISKY | Code must work in both modes |
