---
name: triangle-overview
description: "Triangle architecture overview and skill family index. Triggers: triangle, polkadot desktop, polkadot app, host"
---

# Triangle Skills Overview

## When to Activate

- Starting any Triangle/Host development (load this FIRST)
- Need to understand sandboxed product architecture
- Looking for which Triangle sub-skill to load next

## What is the Polkadot Triangle?

The Polkadot Triangle is a decentralized product ecosystem consisting of three hosts that run sandboxed Products:

| Host | Platform | Role |
|------|----------|------|
| **Polkadot App** | Mobile (iOS/Android) | Identity holder, transaction signing |
| **Polkadot Desktop** | Desktop app | Development, full features |
| **Polkadot.com** | Web browser | Web access |

**Key Insight:** Products are sandboxed iframes with no direct HTTP/HTTPS access. All external interactions go through the Host API.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Host (Desktop/Web/Mobile)                                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Your Product (iframe)                                       │ │
│  │  - No direct network access                                  │ │
│  │  - Uses @novasamatech/product-sdk                           │ │
│  │  - Accounts injected via window.injectedWeb3.spektr         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Host Container (@novasamatech/host-container)              │ │
│  │  - Manages embedded products                                 │ │
│  │  - Provides account injection & signing                      │ │
│  │  - JSON-RPC proxy to chains                                  │ │
│  │  - Scoped localStorage per product                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Light Client / RPC Provider                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Skill Index

| Skill | Purpose | When to Load |
|-------|---------|--------------|
| `spektr-manager.md` | Container orchestration for embedded products | Building a host that embeds products |
| `authentication.md` | Unified wallet auth (Papp + Extensions) | Implementing wallet connection |
| `dotns-resolution.md` | Resolving .dot domains to IPFS content | Loading products from DotNS |
| `service-worker.md` | Caching and serving IPFS content | Building production hosts |
| `product-sdk.md` | Building products that run in Triangle | Building an embedded product |
| `static-export.md` | Static hosting requirements | Deploying to Bulletin/IPFS |

## SDK Packages

```bash
# Host-side packages (for building hosts)
pnpm add @novasamatech/host-container@0.6.6-1
pnpm add @novasamatech/host-api@0.6.6-1
pnpm add @novasamatech/host-papp@0.6.6-1
pnpm add @novasamatech/host-papp-react-ui@0.6.6-1

# Product-side packages (for building embedded products)
pnpm add @novasamatech/product-sdk@0.6.6-1
pnpm add @novasamatech/host-api@0.6.6-1
```

**Version matching is critical:** SDK and Host versions must match (e.g., 0.6.x SDK ↔ 0.6.x Desktop).

## Working Starter Template

**`templates/minimal-host-app/`** - Complete working example with:
- `src/main.js` - All SDK patterns in ~460 lines
- `src/index.html` - Minimal UI with inline styles
- `build.mjs` - Single-file bundler (32 lines)
- `deploy.sh` - Full deployment workflow

```bash
cd templates/minimal-host-app
npm install && npm run dev  # → http://localhost:8000
npm run build               # → dist/index.html
./deploy.sh my-app          # → https://my-app.dot.li
```

## Additional References

For more complex patterns, see:
- **triangle-web-host-demo** repository (local: `~/Documents/dev/triangle-web-host-demo`)
- **CLAUDE.md** in that repo (500+ lines of implementation details)

## Development Workflow

```
1. Start from template  →  cp -r templates/minimal-host-app my-app
2. Develop locally      →  npm run dev (localhost:8000)
3. Build                →  npm run build (single dist/index.html)
4. Deploy               →  ./deploy.sh my-app (→ my-app.dot.li)
5. Test in Host         →  Open in Polkadot Desktop or dot.li
```

**See:** `deploy-frontend/` skill for detailed deployment workflow.

## What's Working Now

| Feature | Status |
|---------|--------|
| Product deployment via Bulletin + DotNS | ✅ Working |
| Account injection & signing | ✅ Working |
| Scoped localStorage per product | ✅ Working |
| Localhost development | ✅ Working |
| Chain queries via Host API | ✅ Working |
| Multi-chain support | ✅ Working |

## What's Not Ready Yet

| Feature | Status |
|---------|--------|
| Auto-signing (per-extrinsic approval) | 🚧 Planned |
| Chat integration | 🚧 Stubs only |
| Push notifications | 🚧 Planned |
| Fine-grained permissions | 🚧 Planned |

## Anti-Patterns (Apply to All Triangle Skills)

| Pattern | Status | Reason |
|---------|--------|--------|
| Direct HTTP/fetch from product | FORBIDDEN | Sandboxed, will fail |
| Bundling light client in product | FORBIDDEN | Host provides chain access |
| Assuming stable API | RISKY | v0.6 - APIs changing rapidly |
| Building for all 3 hosts at once | RISKY | Focus on Desktop first |
| Using `ssr: true` for embedding code | FORBIDDEN | Browser-only APIs |
