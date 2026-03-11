---
name: triangle-product-sdk
description: "Build products that run inside Triangle hosts. Triggers: product sdk, embedded product, sandbox, host api"
---

# Product SDK - Building Embedded Products

## When to Activate

- Building a dApp that runs inside Triangle hosts
- Using @novasamatech/product-sdk
- Implementing Host API communication from a product

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

```javascript
import {
  // Inject Spektr extension shim for account access
  injectSpektrExtension,

  // Create enable factory for { accounts, signer } interface
  createNonProductExtensionEnableFactory,

  // Account provider with subscribeAccountConnectionStatus, getNonProductAccounts
  createAccountsProvider,

  // Transport connection status (connecting/connected/disconnected)
  metaProvider,

  // PostMessage transport connecting iframe to Host
  sandboxTransport,

  // Low-level Host API (signRaw, etc.)
  hostApi,

  // Host-scoped storage (readJSON/writeJSON/clear)
  hostLocalStorage,

  // JSON-RPC provider routed through Host's chain connection
  createPapiProvider,
} from "@novasamatech/product-sdk";

import { Binary, createClient } from "polkadot-api";
import { toHex } from "polkadot-api/utils";
import { getWsProvider } from "polkadot-api/ws-provider";
```

## Environment Detection

**IMPORTANT:** Do NOT use `sandboxProvider.isCorrectEnvironment()` - it's unreliable. Use `injectSpektrExtension()` which performs the actual host handshake.

```typescript
// lib/host/detect.ts
import {
  injectSpektrExtension,
  createAccountsProvider,
  metaProvider,
} from '@novasamatech/product-sdk';

type ConnectionStatus = 'disconnected' | 'connecting' | 'connected';

let hostDetectionResult: boolean | null = null;
let hostDetectionPromise: Promise<boolean> | null = null;

// Create accounts provider at module level (singleton)
export const accountsProvider = createAccountsProvider();

/**
 * Initialize host detection - call early in app lifecycle.
 * Uses injectSpektrExtension() which does the actual host handshake.
 */
export async function initHostDetection(): Promise<boolean> {
  if (typeof window === 'undefined') {
    hostDetectionResult = false;
    return false;
  }

  if (hostDetectionResult !== null) return hostDetectionResult;
  if (hostDetectionPromise) return hostDetectionPromise;

  hostDetectionPromise = (async () => {
    const isInHost = await injectSpektrExtension();
    hostDetectionResult = isInHost;

    if (isInHost) {
      // Subscribe to meta connection status
      metaProvider.subscribeConnectionStatus((status: ConnectionStatus) => {
        console.log('[Host] Meta connection status:', status);
      });
    }

    return isInHost;
  })();

  return hostDetectionPromise;
}

export function isHosted(): boolean {
  return hostDetectionResult ?? false;
}

// Re-export metaProvider for status subscriptions
export { metaProvider };
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

**Key patterns:**
1. Call `initHostDetection()` first (uses `injectSpektrExtension()`)
2. Call `getNonProductAccounts()` immediately after detection (don't wait for status)
3. Subscribe to BOTH `accountsProvider.subscribeAccountConnectionStatus` AND `metaProvider.subscribeConnectionStatus`

```typescript
// hooks/use-triangle-account.ts
import { useState, useEffect } from 'react';
import { ss58Encode } from '@polkadot-labs/hdkd-helpers';
import {
  accountsProvider,
  initHostDetection,
  metaProvider,
} from '../lib/host/detect';

type ConnectionStatus = 'disconnected' | 'connecting' | 'connected';

interface Account {
  publicKey: Uint8Array;
  name?: string;
}

export function useTriangleAccount() {
  const [account, setAccount] = useState<Account | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');

  useEffect(() => {
    let cancelled = false;
    let accountSub: { unsubscribe: () => void } | null = null;
    let metaUnsub: (() => void) | null = null;

    // Fetch accounts - call immediately after detection AND on reconnect
    const autoConnect = async () => {
      const result = await accountsProvider.getNonProductAccounts();
      if (cancelled) return;

      result.match(
        (accounts: Account[]) => {
          if (accounts.length > 0) {
            setAccount(accounts[0]);
            setConnectionStatus('connected');
          } else {
            // No accounts = user not signed in to Triangle
            setConnectionStatus('disconnected');
          }
        },
        (error: Error) => {
          console.error('[Wallet] getNonProductAccounts failed:', error);
          setConnectionStatus('disconnected');
        },
      );
    };

    const setup = async () => {
      const inHost = await initHostDetection();
      if (cancelled) return;

      if (!inHost) {
        setConnectionStatus('disconnected');
        return;
      }

      // IMPORTANT: Call immediately after detection (don't wait for status)
      await autoConnect();

      // Subscribe to account connection status
      accountSub = accountsProvider.subscribeAccountConnectionStatus(
        (status: ConnectionStatus) => {
          if (status === 'connected') {
            void autoConnect();
          } else if (status === 'disconnected') {
            setAccount(null);
            setConnectionStatus('disconnected');
          }
        },
      );

      // Also subscribe to meta connection status
      metaUnsub = metaProvider.subscribeConnectionStatus((status: ConnectionStatus) => {
        if (status === 'connected') {
          void autoConnect();
        }
      });
    };

    void setup();

    return () => {
      cancelled = true;
      accountSub?.unsubscribe();
      metaUnsub?.();
    };
  }, []);

  // Convert public key to SS58 address
  const address = account ? ss58Encode(account.publicKey, 42) : null;

  return { account, address, connectionStatus, isConnected: connectionStatus === 'connected' };
}
```

**IMPORTANT:** Use `ss58Encode` from `@polkadot-labs/hdkd-helpers` to convert public keys to addresses. Do NOT use Node.js `Buffer` - it's not available in browsers.

## Host Storage API

Use `hostLocalStorage` for persistent key-value storage scoped to your app:

```javascript
import { hostLocalStorage } from "@novasamatech/product-sdk";

// Write JSON data
await hostLocalStorage.writeJSON("user-settings", { theme: "dark", fontSize: 14 });

// Read JSON data
const settings = await hostLocalStorage.readJSON("user-settings");
// → { theme: "dark", fontSize: 14 }

// Clear a key
await hostLocalStorage.clear("user-settings");

// Also available: readBytes/writeBytes, readString/writeString
```

## Transaction Signing (signSubmitAndWatch)

Sign and submit transactions with full lifecycle tracking:

```javascript
// Build signer from accountsProvider
const signer = accountsProvider.getNonProductAccountSigner({
  dotNsIdentifier: "",
  derivationIndex: 0,
  publicKey: providerAccounts[0].publicKey,
});

// Connect to chain
const client = createClient(getWsProvider(CHAIN.wsUrl));
const api = client.getUnsafeApi();

// Build and submit transaction
const tx = api.tx.System.remark({
  remark: Binary.fromBytes(new TextEncoder().encode("Hello")),
});

// Subscribe to lifecycle events
tx.signSubmitAndWatch(signer).subscribe({
  next(ev) {
    if (ev.type === "txBestBlocksState" && ev.found) {
      console.log("Included in best block...");
    } else if (ev.type === "finalized") {
      console.log(`Finalized in block ${ev.block.hash}`);
    }
  },
  error(e) {
    console.error("Transaction failed:", e.message);
  },
});
```

## Sign Raw Message

Sign arbitrary data without on-chain submission:

```javascript
import { hostApi } from "@novasamatech/product-sdk";
import { toHex } from "polkadot-api/utils";

const result = await hostApi.signRaw({
  tag: "v1",
  value: {
    address: toHex(publicKey),
    data: { tag: "Bytes", value: new TextEncoder().encode("Message to sign") },
  },
});

// Result is a neverthrow Result type
result.match(
  (ok) => console.log(`Signature: ${ok.value.signature}`),
  (err) => console.error(`Sign failed: ${err.value.name}`),
);
```

## Chain Reads via Host Provider

Query on-chain state through Host-managed connection (no direct WebSocket):

```javascript
import { createPapiProvider } from "@novasamatech/product-sdk";
import { createClient } from "polkadot-api";

const CHAIN_GENESIS = "0xd6eec26135305a8ad257a20d003357284c8aa03d0bdb2b357ab0a22371e11ef2";

// Create client using Host's connection (not direct WebSocket)
const provider = createPapiProvider(CHAIN_GENESIS);
const client = createClient(provider);

// Query finalized block
const block = await client.getFinalizedBlock();
console.log(`Block #${block.number}: ${block.hash}`);

// Query storage (untyped API)
const api = client.getUnsafeApi();
const timestamp = await api.query.Timestamp.Now.getValue();
console.log(`On-chain time: ${new Date(Number(timestamp)).toISOString()}`);

// Clean up
client.destroy();
```

## Legacy: Scoped localStorage

The host also scopes `window.localStorage` per product:

```javascript
// Automatically scoped to your product
localStorage.setItem('user-preference', 'dark');
const pref = localStorage.getItem('user-preference');
// Host prefixes keys: product:{productId}:{key}
```

**Prefer `hostLocalStorage`** for explicit Host storage API.

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
| Using `sandboxProvider.isCorrectEnvironment()` | UNRELIABLE | Use `injectSpektrExtension()` instead |
| Using Node.js `Buffer` | FORBIDDEN | Not available in browsers - use `ss58Encode` |
| Waiting for status before fetching accounts | WRONG | Call `getNonProductAccounts()` immediately after detection |

## Working Example

For a complete working implementation of all these patterns, see:
- **`templates/minimal-host-app/`** - Vanilla JS starter with all SDK features
- **`templates/minimal-host-app/src/main.js`** - All patterns in one file (~460 lines)
