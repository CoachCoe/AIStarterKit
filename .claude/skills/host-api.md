# Host API & Polkadot Triangle

## Context

Use when building for the Polkadot Triangle ecosystem (Desktop, Web, Mobile hosts).

**Status: v0.6 - APIs are evolving rapidly. Expect breaking changes.**

---

## Skill Family

Triangle development is covered by a comprehensive skill family. Load the relevant skill based on your task:

| Skill | Purpose | When to Load |
|-------|---------|--------------|
| `triangle/OVERVIEW.md` | Architecture, concepts, SDK packages | Starting Triangle development |
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

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Direct HTTP/fetch from product | FORBIDDEN | Sandboxed, will fail |
| Bundling light client in product | FORBIDDEN | Host provides chain access |
| Assuming stable API | RISKY | v0.6 - APIs changing rapidly |
| Building for all 3 hosts at once | RISKY | Focus on Desktop first |
| Using `ssr: true` for embedding code | FORBIDDEN | Browser-only APIs |
