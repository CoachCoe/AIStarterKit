---
name: triangle-api-migration
description: "Migrate dApps from browser APIs to Triangle Host API. Triggers: migrate, host api, sandbox fix, remediation"
---

# Host API Migration Guide

## When to Activate

- Migrating an existing dApp to run in Triangle hosts
- Fixing sandbox violations found by the checker
- Converting direct browser API calls to Host API equivalents

## Prerequisites

Install the Product SDK:

```bash
pnpm add @novasamatech/product-sdk@0.6.6-1 @novasamatech/host-api@0.6.6-1
```

## Migration Patterns

### Network: WebSocket → Host Chain Provider

**Before (Violation):**
```typescript
import { createClient } from "polkadot-api";
import { getWsProvider } from "polkadot-api/ws-provider";

const client = createClient(getWsProvider("wss://rpc.polkadot.io"));
```

**After (Host API):**
```typescript
import { createClient } from "polkadot-api";
import { createPapiProvider } from "@novasamatech/product-sdk";

// Use chain genesis hash instead of URL
const POLKADOT_GENESIS = "0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3";
const provider = createPapiProvider(POLKADOT_GENESIS);
const client = createClient(provider);
```

**Common Genesis Hashes:**
```typescript
const CHAINS = {
  polkadot: "0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
  kusama: "0xb0a8d493285c2df73290dfb7e61f870f17b41801197a149ca93654499ea3dafe",
  assetHubPolkadot: "0x68d56f15f85d3136970ec16946040bc1752654e906147f7e43e9d539d7c3de2f",
  assetHubPaseo: "0x862c83e9cf4a9fbd49c2f131de89a9e2e8c6bd2b21a469071ebe8ad028a21573",
};
```

---

### Network: fetch() → Host API

**Before (Violation):**
```typescript
const response = await fetch("https://api.example.com/data");
const data = await response.json();
```

**After (Host API):**

For chain data, use the chain provider (see above). For external APIs, this is currently **not supported** in the sandbox. Options:

1. **Move logic to a backend** and access via chain (if applicable)
2. **Request Host API support** for the specific endpoint
3. **Cache data at build time** if it's static

---

### Storage: localStorage → hostLocalStorage

**Before (Violation):**
```typescript
// Write
localStorage.setItem("settings", JSON.stringify({ theme: "dark" }));

// Read
const settings = JSON.parse(localStorage.getItem("settings") || "{}");

// Delete
localStorage.removeItem("settings");
```

**After (Host API):**
```typescript
import { hostLocalStorage } from "@novasamatech/product-sdk";

// Write (async!)
await hostLocalStorage.writeJSON("settings", { theme: "dark" });

// Read (async!)
const settings = await hostLocalStorage.readJSON("settings");

// Delete (async!)
await hostLocalStorage.clear("settings");
```

**Note:** Host storage is async. Update your code to handle promises.

---

### Storage: IndexedDB → hostLocalStorage

**Before (Violation):**
```typescript
const request = indexedDB.open("myDatabase", 1);
request.onsuccess = (event) => {
  const db = event.target.result;
  // Complex IndexedDB operations...
};
```

**After (Host API):**
```typescript
import { hostLocalStorage } from "@novasamatech/product-sdk";

// For simple key-value storage
await hostLocalStorage.writeJSON("myData", complexObject);
const data = await hostLocalStorage.readJSON("myData");

// For binary data
await hostLocalStorage.writeBytes("binaryKey", uint8Array);
const bytes = await hostLocalStorage.readBytes("binaryKey");
```

**Note:** If you need complex queries, consider restructuring your data or filing a feature request.

---

### Wallet: window.ethereum → Host Accounts

**Before (Violation):**
```typescript
const accounts = await window.ethereum.request({ method: "eth_accounts" });
const signer = new ethers.BrowserProvider(window.ethereum).getSigner();
```

**After (Host API):**
```typescript
import { createAccountsProvider } from "@novasamatech/product-sdk";

const accountsProvider = createAccountsProvider();

// Get accounts
const result = await accountsProvider.getNonProductAccounts();
result.match(
  (accounts) => {
    // accounts[0].publicKey: Uint8Array
    // accounts[0].name: string | undefined
  },
  (error) => console.error("No accounts:", error)
);

// Get signer for transactions
const signer = accountsProvider.getNonProductAccountSigner({
  dotNsIdentifier: "",
  derivationIndex: 0,
  publicKey: accounts[0].publicKey,
});
```

---

### Wallet: Polkadot Extension → Host Accounts

**Before (Violation):**
```typescript
import { web3Enable, web3Accounts } from "@polkadot/extension-dapp";

await web3Enable("My App");
const accounts = await web3Accounts();
```

**After (Host API):**
```typescript
import { createAccountsProvider } from "@novasamatech/product-sdk";

const accountsProvider = createAccountsProvider();
const result = await accountsProvider.getNonProductAccounts();
```

---

### Workers: Remove Bundled Light Clients

**Before (Violation):**
```typescript
import { startSmoldot } from "./smoldot-worker";
const client = await startSmoldot(chainSpec);
```

**After (Host API):**
```typescript
// Remove smoldot entirely - Host provides chain access
import { createPapiProvider } from "@novasamatech/product-sdk";

const provider = createPapiProvider(CHAIN_GENESIS);
const client = createClient(provider);
```

---

### Workers: Remove Service Worker

**Before (Violation):**
```typescript
navigator.serviceWorker.register("/sw.js");
```

**After (Host API):**
```typescript
// Remove entirely - Host manages caching
// Delete your sw.js file
```

---

## Environment Detection

Support both hosted and standalone modes:

```typescript
import { sandboxProvider } from "@novasamatech/product-sdk";

export function isHosted(): boolean {
  if (typeof window === "undefined") return false;
  return sandboxProvider.isCorrectEnvironment();
}

// Usage throughout your app
async function getAccounts() {
  if (isHosted()) {
    // Use Host API
    const accountsProvider = createAccountsProvider();
    return accountsProvider.getNonProductAccounts();
  } else {
    // Fallback for standalone development
    const { web3Enable, web3Accounts } = await import("@polkadot/extension-dapp");
    await web3Enable("My App");
    return web3Accounts();
  }
}
```

---

## Libraries to Remove

These libraries are **incompatible** with the Triangle sandbox and must be removed entirely:

| Library | Why | Alternative |
|---------|-----|-------------|
| **Web3Modal** | Host manages wallets | `createAccountsProvider()` |
| **RainbowKit** | Host manages wallets | `createAccountsProvider()` |
| **@walletconnect/*** | Host manages wallets | `createAccountsProvider()` |
| **LaunchDarkly** | No external network | Build-time flags or none |
| **Cloudflare Analytics** | No external network | None |
| **Google Analytics** | No external network | None |
| **Sentry** | No external network | Console logging |
| **PostHog** | No external network | None |

```bash
# Remove from your project
pnpm remove web3modal @web3modal/wagmi @walletconnect/web3wallet
pnpm remove @launchdarkly/js-client-sdk
pnpm remove @sentry/browser @sentry/react
pnpm remove @cloudflare/next-on-pages
```

---

## Migration Checklist

Before deployment, verify:

- [ ] Removed prohibited libraries (Web3Modal, LaunchDarkly, Sentry, etc.)
- [ ] Installed `@novasamatech/product-sdk@0.6.6-1`
- [ ] Replaced all direct `fetch()` to external APIs
- [ ] Replaced all `WebSocket` connections with `createPapiProvider()`
- [ ] Replaced `localStorage` with `hostLocalStorage`
- [ ] Replaced wallet extension access with `createAccountsProvider()`
- [ ] Removed Service Worker registration
- [ ] Removed bundled light client (smoldot)
- [ ] Added `isHosted()` checks for graceful degradation
- [ ] Ran sandbox checker: 0 violations
- [ ] Tested in Polkadot Desktop

---

## Common Migration Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Sync localStorage calls | `hostLocalStorage` is async | Add `await` |
| Missing `isHosted()` check | Breaks standalone dev | Add environment detection |
| Hardcoded RPC URLs | Won't work in sandbox | Use genesis hash + `createPapiProvider()` |
| Keeping smoldot | Bloats bundle, duplicates host | Remove entirely |
| Direct `Buffer.from()` | Not available in sandbox | Use `Uint8Array` or `@polkadot-api/utils` |

---

## Testing Your Migration

1. **Standalone mode**: `npm run dev` and test with browser extensions
2. **Hosted mode**: Deploy to dot.li and test, or use Polkadot Desktop
3. **Sandbox checker**: Run `npx tsx scripts/sandbox-check.ts` before each deploy

---

## Related Skills

- `triangle/sandbox-check.md` — Run the compliance checker
- `triangle/product-sdk.md` — Full SDK reference
- `triangle/static-export.md` — Build configuration
