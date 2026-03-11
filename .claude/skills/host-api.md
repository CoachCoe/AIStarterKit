---
name: host-api
description: "Triangle Host API overview and skill family index. Triggers: host api, triangle, polkadot desktop, spektr"
---

# Host API & Polkadot Triangle

## When to Activate

- Starting any Triangle/Host development
- Need to understand the skill family structure
- Looking for the right Triangle sub-skill to load

## Context

Use when building for the Polkadot Triangle ecosystem (Desktop, Web, Mobile hosts).

**Status: v0.6 - APIs are evolving rapidly. Expect breaking changes.**

---

## Skill Family

Triangle development is covered by a comprehensive skill family. Load the relevant skill based on your task:

| Skill | Purpose | When to Load |
|-------|---------|--------------|
| `triangle/OVERVIEW.md` | Architecture, concepts, SDK packages | Starting Triangle development |
| `triangle/sandbox-check.md` | Check for Host API violations | Before deploying, after migration |
| `triangle/api-migration.md` | Migrate browser APIs to Host API | Converting existing dApps |
| `triangle/spektr-manager.md` | Container orchestration for embedded products | Building a host that embeds products |
| `triangle/authentication.md` | Unified wallet auth (Papp + Extensions) | Implementing wallet connection |
| `triangle/dotns-resolution.md` | Resolving .dot domains to IPFS content | Loading products from DotNS |
| `triangle/service-worker.md` | Caching and serving IPFS content | Building production hosts |
| `triangle/product-sdk.md` | Building products that run in Triangle | Building an embedded product |
| `triangle/static-export.md` | Static hosting requirements | Deploying to Bulletin/IPFS |

---

## Quick Reference

### What is the Triangle?

The Polkadot Triangle consists of three hosts that run sandboxed Products:

| Host | Platform | Role |
|------|----------|------|
| Polkadot App | Mobile (iOS/Android) | Identity holder, transaction signing |
| Polkadot Desktop | Desktop app | Development, full features |
| Polkadot.com | Web browser | Web access |

**Key Insight:** Products are sandboxed iframes - no direct HTTP/HTTPS access. All external interactions go through Host API.

### SDK Packages

```bash
# Host-side packages (for building hosts)
pnpm add @novasamatech/host-container@0.6.6-1
pnpm add @novasamatech/host-api@0.6.6-1
pnpm add @novasamatech/host-papp-react-ui@0.6.6-1

# Product-side packages (for building embedded products)
pnpm add @novasamatech/product-sdk@0.6.6-1
pnpm add @novasamatech/host-api@0.6.6-1
```

**Version matching is critical:** SDK and Host versions must match (e.g., 0.6.x SDK ↔ 0.6.x Desktop).

### Development Workflow

```
1. Build Product   →  Standard web app + @novasamatech/product-sdk
2. Deploy          →  Bulletin Chain + DotNS (see deploy-frontend/ skill)
3. Test in Host    →  Desktop app: search for .dot domain or localhost:3000
```

### What's Working Now

| Feature | Status |
|---------|--------|
| Product deployment via Bulletin + DotNS | ✅ Working |
| Account injection & signing (Papp + Extensions) | ✅ Working |
| Scoped localStorage per product | ✅ Working |
| Localhost development | ✅ Working |
| Chain queries via Host API | ✅ Working |
| Multi-chain support | ✅ Working |

### What's Not Ready Yet

| Feature | Status |
|---------|--------|
| Auto-signing (per-extrinsic approval) | 🚧 Planned |
| Chat integration | 🚧 Stubs only |
| Push notifications | 🚧 Planned |

---

## Reference Implementation

For working code and detailed patterns, see:
- **triangle-web-host-demo** repository (local: `~/Documents/dev/triangle-web-host-demo`)
- **CLAUDE.md** in that repo (500+ lines of implementation details)

---

## Getting Started

### Building a Product (dApp that runs in Triangle)

```bash
# 1. Start from template
cp -r templates/minimal-host-app my-product
cd my-product && npm install

# 2. Develop locally
npm run dev  # localhost:8000

# 3. Build and deploy
npm run build
./deploy.sh my-product  # → https://my-product.dot.li
```

**Load:** `triangle/product-sdk.md` for SDK patterns.

### Building a Host (app that embeds products)

This is advanced. Start by studying the reference implementation:
- **triangle-web-host-demo** repository

**Load:** `triangle/spektr-manager.md` for container orchestration.

---

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Direct HTTP/fetch from product | FORBIDDEN | Sandboxed iframe, will fail silently |
| Bundling light client in product | FORBIDDEN | Host provides chain access via API |
| Using `window.ethereum` | FORBIDDEN | Not injected in Triangle |
| Web3Modal / wallet connection libs | FORBIDDEN | Host manages wallets entirely |
| Feature flag services (LaunchDarkly) | FORBIDDEN | No external network access |
| Analytics services (Cloudflare, etc.) | FORBIDDEN | No external network access |
| Hardcoding chain endpoints | FORBIDDEN | Must use host's provider |
| Assuming stable API | RISKY | v0.6 - APIs changing rapidly |
| Building for all 3 hosts at once | RISKY | Focus on Desktop first |
| Using `ssr: true` for embedding code | FORBIDDEN | Browser-only APIs |
| Skipping `triangle/OVERVIEW.md` | RISKY | Miss fundamental architecture |
| Not checking `isHosted()` | RISKY | Code must work both in and out of host |
| Assuming accounts exist on load | RISKY | User may not be signed in |

---

## Verification

Before considering Triangle work complete:

```bash
# Build must succeed
npm run build

# Output must be static (single HTML or static files)
ls dist/

# Test in actual host environment
# - Open in Polkadot Desktop
# - Or deploy to .dot.li and test there
```
