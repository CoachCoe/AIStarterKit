---
name: dotli
description: "dot.li universal resolver - the fourth host. Triggers: dot.li, smoldot, helia, link sharing, client-side resolution"
---

# dot.li - Decentralized Universal Resolver

## When to Activate

- Building dApps that need universal browser access
- Implementing client-side chain resolution
- Understanding the "fourth host" concept
- Deploying content accessible via `.dot.li` domains

---

## What is dot.li?

dot.li is a decentralized universal resolver for Polkadot that enables:

1. **Human-readable URLs** - `myapp.dot.li` instead of IPFS hashes
2. **Client-side resolution** - No proxy, no server-side processing
3. **Easy onboarding** - Share a link → users get nudged to install Polkadot app
4. **True decentralization** - Light clients validate chain state in-browser

**Status:** Live on Paseo testnet. Demo: https://mytestapp.dot.li/

---

## The Four Hosts

| Host | Platform | Access |
|------|----------|--------|
| Polkadot App | Mobile | Installed app |
| Polkadot Desktop | Desktop | Installed app |
| Polkadot.com | Web | Logged in users |
| **dot.li** | **Any browser** | **Link sharing, no install** |

---

## How Resolution Works

```
User enters: myapp.dot.li
        ↓
[1] DNS wildcard → static host
[2] Browser loads Universal Viewer (static JS)
[3] Smoldot light client syncs in browser
[4] Query dotNS contracts via Revive EVM
[5] Helia P2P fetches content from Bulletin
[6] Render in sandboxed iframe
```

**Key:** Everything runs client-side. No servers needed.

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Light Client | smoldot | Browser-based chain validation |
| Chain Queries | polkadot-api | Access Revive EVM pallet |
| ABI Encoding | viem | Contract call encoding |
| P2P Fetching | Helia + @helia/unixfs | In-browser IPFS client |
| Content Hash | @ensdomains/content-hash | Decode ENS-style CIDs |

**For implementation details:** See [Smoldot Patterns](./references/smoldot-patterns.md)

---

## dotNS Contracts (Asset Hub Paseo)

```typescript
DOTNS_REGISTRY: "0x4Da0d37aBe96C06ab19963F31ca2DC0412057a6f"
DOTNS_CONTENT_RESOLVER: "0x7756DF72CBc7f062e7403cD59e45fBc78bed1cD7"
```

### Resolution Flow

```typescript
// 1. Compute namehash
const node = namehash("myapp.dot");

// 2. Check domain exists
const exists = await reviveCall(REGISTRY, "recordExists", [node]);

// 3. Get content hash
const contentHash = await reviveCall(CONTENT_RESOLVER, "contenthash", [node]);

// 4. Decode to IPFS CID
const cid = decodeContentHash(contentHash);
```

---

## Bulletin Chain P2P

```typescript
const BULLETIN_PEERS = [
  "/dns4/paseo-bulletin-collator-node-0.parity-testnet.parity.io/tcp/443/wss/p2p/12D3KooW...",
  "/dns4/paseo-bulletin-collator-node-1.parity-testnet.parity.io/tcp/443/wss/p2p/12D3KooW...",
];

const IPFS_GATEWAY = "https://paseo-ipfs.polkadot.io"; // Fallback
```

---

## Making Your App dot.li Compatible

### Requirements

1. Deploy to Bulletin Chain (see `deploy-frontend/`)
2. Register .dot domain via dotns CLI
3. Set content hash linking domain to CID
4. Use `base: './'` in Vite config

### Vite Config

```typescript
export default defineConfig({
  base: './',  // REQUIRED for IPFS/dot.li
});
```

### Deployment

```bash
# 1. Build
pnpm build

# 2. Upload to Bulletin
bun run src/cli/index.ts bulletin upload ./dist \
  --parallel --print-contenthash -m "$DOTNS_MNEMONIC"

# 3. Set content hash
bun run src/cli/index.ts content set myapp bafybeig... \
  -m "$DOTNS_MNEMONIC"

# 4. Access: https://myapp.dot.li/
```

---

## Onboarding Funnel

```
Developer shares: myapp.dot.li
        ↓
User clicks link (any browser)
        ↓
App loads via client-side resolution
        ↓
User sees decentralized app
        ↓
CTA: "Install Polkadot App"
        ↓
User joins ecosystem
```

**No wallet required** to view content.

---

## Sandbox Checker (Development Tool)

dot.li includes a **sandbox API checker** that detects when dApps make prohibited API calls. Enable with `VITE_SANDBOX_CHECKER=true` at build time.

**What it detects:**
- Direct network: `fetch`, `XMLHttpRequest`, `WebSocket`, `RTCPeerConnection`
- Direct storage: `localStorage`, `sessionStorage`, `IndexedDB`, cookies
- Direct wallet: `window.ethereum`, `window.injectedWeb3`, `window.polkadot`
- Workers: `Worker`, `SharedWorker`, `ServiceWorker.register()`

**Behavior:** Violations are logged to a collapsible panel at viewport bottom. Calls still proceed (log-and-forward) so you can see what breaks.

**Use case:** Run your dApp through dot.li with the checker enabled before deploying to identify Host API compliance issues.

---

## Nested dApp Support

dot.li supports **nested dApps** — when a product embeds another product via iframe, the container dynamically creates bridges for each descendant that sends protocol messages to `window.top`.

This enables composable products where one Triangle product can embed and interact with others.

---

## Limitations

| Limitation | Status | Notes |
|------------|--------|-------|
| First load ~3s | Expected | Light client sync |
| Manifest routing | Not implemented | Single CID per domain |
| SEO/crawlers | Limited | Client-only |

---

## Networks

| Network | URL | Status |
|---------|-----|--------|
| Paseo | `*.dot.li` | ✅ Live |
| Polkadot | TBD | 🚧 Planned |

---

## Resources

- **Live Demo:** https://mytestapp.dot.li/
- **Repository:** github.com/paritytech/dotli
- **Light Client Patterns:** [./references/smoldot-patterns.md](./references/smoldot-patterns.md)
- **Related:** `deploy-frontend/`, `host-api.md`

---

## Iframe Sandbox Permissions

dApps run in a sandboxed iframe with these permissions:

| Permission | Status | Notes |
|------------|--------|-------|
| `allow-scripts` | ✅ Enabled | Required for JS execution |
| `allow-same-origin` | ✅ Enabled | Required for module loading |
| `allow-forms` | ✅ Enabled | Form submissions allowed |
| `allow-modals` | ✅ Enabled | `alert()`, `confirm()`, `prompt()` |
| `allow-pointer-lock` | ✅ Enabled | For games/immersive UIs |
| Clipboard API | ✅ Enabled | Read/write clipboard |
| `allow-popups` | ❌ Disabled | No `window.open()` |
| `allow-top-navigation` | ❌ Disabled | Cannot navigate parent |

---

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Absolute asset paths | FORBIDDEN | Breaks on IPFS |
| Bundling backend | FORBIDDEN | Static-only |
| Server-side auth | FORBIDDEN | No server |
| Assuming fast first load | RISKY | Light client sync ~3s |
| Bundling Smoldot in Triangle Product | FORBIDDEN | Host provides chain access |
