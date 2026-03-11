---
name: triangle-sandbox-check
description: "Check Triangle products for Host API sandbox violations. Triggers: sandbox check, violations, compliance, host api audit"
---

# Sandbox Compliance Checker

## When to Activate

- Before deploying a product to Triangle hosts
- When migrating an existing dApp to Triangle
- After the user asks to check for sandbox violations
- When troubleshooting "why doesn't this work in the host?"

## Prerequisites

- Product running locally (e.g., `npm run dev` on port 3000)
- Playwright installed: `npx playwright install chromium`

## Quick Start

```bash
# From the dotli repo
cd /Users/shawncoe/Documents/dev/dotli/dotli

# Run against your app (saves results to your repo)
npx tsx scripts/sandbox-check.ts <port> <your-repo-path>

# Example
npx tsx scripts/sandbox-check.ts 3000 /Users/shawncoe/Documents/dev/my-product
```

## Output Files

The checker creates two files in your repo:

**`sandbox-violations.md`** — What's wrong:
```markdown
# Sandbox Violations Report

| Category | Count |
|----------|-------|
| Network  | 3     |
| Storage  | 17    |
| Wallet   | 2     |

## Violations by Category
### Network
- **WebSocket**: url=`wss://rpc.polkadot.io`
- **fetch**: url=`https://api.example.com` method=`GET`
```

**`sandbox-remediation-prompt.md`** — How to fix it:
- Claude Code prompt with specific fixes for each violation
- Code examples using Host API replacements
- SDK installation commands

## Prohibited Dependencies

These libraries/services are **incompatible** with the Triangle sandbox:

| Library/Service | Why Prohibited | Alternative |
|-----------------|----------------|-------------|
| **Web3Modal** | Host manages wallets entirely | `createAccountsProvider()` |
| **RainbowKit** | Host manages wallets entirely | `createAccountsProvider()` |
| **LaunchDarkly** | No external network access | Build-time feature flags or none |
| **Cloudflare Analytics** | No external network access | None (privacy-preserving) |
| **Google Analytics** | No external network access | None (privacy-preserving) |
| **Sentry** | No external network access | Console logging only |

If your project has any of these dependencies, remove them before deployment.

## What It Detects

| Category | Violations | Host API Replacement |
|----------|------------|---------------------|
| **Network** | `fetch`, `XMLHttpRequest`, `WebSocket`, `RTCPeerConnection` | `createPapiProvider()` |
| **Storage** | `localStorage`, `sessionStorage`, `IndexedDB`, cookies | `hostLocalStorage` |
| **Wallet** | `window.ethereum`, `window.injectedWeb3`, `window.polkadot` | `createAccountsProvider()` |
| **Workers** | `Worker`, `SharedWorker`, `ServiceWorker` | Remove (Host provides) |
| **DOM** | `createElement('iframe')` | Evaluate case-by-case |

## Workflow

```
1. Start your dev server     →  npm run dev
2. Run sandbox checker       →  npx tsx scripts/sandbox-check.ts 3000 ./
3. Review violations         →  cat sandbox-violations.md
4. Fix using remediation     →  Follow sandbox-remediation-prompt.md
5. Re-run checker            →  Verify 0 violations
6. Deploy                    →  ./deploy.sh my-product
```

## No Violations = Success

If the checker reports 0 violations, your product is Host API compliant and ready for:
- Polkadot Desktop
- Polkadot App (mobile)
- Polkadot.com
- dot.li

## Common False Positives

| Violation | Why It's OK |
|-----------|-------------|
| `ws://localhost:*/_next/webpack-hmr` | Next.js HMR, dev only |
| `sessionStorage` + `sentryReplaySession` | Sentry, disable in production sandbox |
| `Worker` with blob URL | May be crypto operations, evaluate |

## Interpreting Results

### Blocking Violations (Must Fix)

These WILL break in the Triangle sandbox:

- **Network**: Any `fetch`, `WebSocket`, `XMLHttpRequest` to external URLs
- **Wallet**: Direct `window.ethereum` or `window.injectedWeb3` access
- **Workers**: `ServiceWorker.register()` (Host manages caching)

### Warning Violations (Should Fix)

These may work but should be migrated:

- **Storage**: Direct `localStorage` (Host scopes it, but prefer `hostLocalStorage`)
- **IndexedDB**: Works but prefer `hostLocalStorage` for portability
- **Workers**: Regular `Worker` for computation (may be allowed)

## Next Steps After Finding Violations

1. **Load the migration skill**: See `triangle/api-migration.md` for detailed fix patterns
2. **Use the remediation prompt**: Copy `sandbox-remediation-prompt.md` into Claude Code
3. **Re-run the checker**: Verify all violations are fixed

## Related Skills

- `triangle/api-migration.md` — Detailed migration patterns
- `triangle/product-sdk.md` — Full SDK documentation
- `triangle/OVERVIEW.md` — Architecture overview
