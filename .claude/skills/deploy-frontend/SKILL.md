---
name: deploy-frontend
description: "Deploy frontend to Bulletin Chain + DotNS. Triggers: deploy frontend, bulletin, dotns, .dot domain, decentralized hosting"
---

# Deploy Frontend to Bulletin Chain + DotNS

## When to Activate

- Deploying frontend to decentralized storage
- Registering a .dot domain
- Updating content on an existing domain
- Setting up personhood verification

## Global Invariants

| Rule | Enforcement |
|------|-------------|
| Set Personhood (PoP) before domain registration | REQUIRED |
| Authorize for Bulletin before upload | REQUIRED |
| Use `base: './'` in Vite config | REQUIRED (IPFS-compatible paths) |
| Never commit mnemonic | FORBIDDEN |

## Prerequisites

1. **Node.js 22+** or **Bun** (for WebSocket support)
2. **dotns CLI** - Install globally:
   ```bash
   npm install -g https://github.com/paritytech/dotns-sdk/releases/latest/download/dotns-cli.tgz
   ```
3. **Wallet with PAS tokens** on Asset Hub Paseo
4. **Vite config** with `base: './'` for IPFS-compatible relative paths

## Chains Involved

| Chain | Purpose | Endpoint |
|-------|---------|----------|
| Asset Hub Paseo | Domain registration, content hash | `wss://asset-hub-paseo-rpc.n.dwellir.com` |
| Bulletin Paseo | Decentralized storage | `wss://bulletin.dotspark.app` |

## First-Time Setup (REQUIRED)

### Step 1: Set Personhood (PoP) Lite

**This is REQUIRED before domain registration. Cannot skip this step.**

```bash
# Set PoP Lite verification
dotns pop set lite -m "$DOTNS_MNEMONIC"
```

Verify PoP status:
```bash
dotns pop status -m "$DOTNS_MNEMONIC"
```

### Step 2: Authorize for Bulletin Storage

**This is REQUIRED before uploading to Bulletin. Self-service authorization.**

```bash
# Get your Substrate address
dotns account address -m "$DOTNS_MNEMONIC"

# Authorize yourself for Bulletin storage
dotns bulletin authorize <your-substrate-address> -m "$DOTNS_MNEMONIC"
```

**Note:** On Paseo testnet, self-authorization is enabled. On mainnet, you may need Authorizer privileges.

## Authentication Methods

```bash
# Option 1: p1p (recommended - decentralized secret storage)
# Requires: p1p CLI installed and signed in (p1p signin --mnemonic)
export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)
# Then use: -m "$DOTNS_MNEMONIC"

# Option 2: Mnemonic (direct)
--mnemonic "your 12 word mnemonic here"
# or
-m "$DOTNS_MNEMONIC"

# Option 3: Keystore (for repeated use)
export DOTNS_KEYSTORE_PATH=~/.dotns/keystore
export DOTNS_KEYSTORE_PASSWORD=your-password
dotns auth set --account default --mnemonic "your 12 words..."

# Option 4: Dev key URI (testing only - Previewnet)
--key-uri //Alice
```

**p1p Setup (one-time):**
```bash
# Sign in to p1p
p1p signin --mnemonic

# Store your dotns mnemonic
p1p locker create -n "my-deployment"
p1p item create -l "my-deployment" -t "dotns" \
  --category custom \
  --field mnemonic="your 12 word mnemonic"
```

## Deployment Workflow

### Step 1: Build Frontend

```bash
# Ensure Vite config has base: './'
pnpm run build
# Output: dist/
```

### Step 2: Check Domain Status

```bash
dotns lookup name <domain-name>
```

### Step 3: Register Domain (if not registered)

```bash
dotns register domain --name <domain-label> -m "$DOTNS_MNEMONIC"
```

**Domain naming rules:**
- `myapp` → `myapp.dot`
- `my-app` → `my-app.dot` (hyphens allowed)
- Reserved names (≤5 chars) require `--governance` flag

### Step 4: Upload to Bulletin Chain

```bash
dotns bulletin upload ./dist --parallel --print-contenthash -m "$DOTNS_MNEMONIC"
```

**Output:**
```
CID: bafybeig...
ContentHash: 0xe3010170...
```

Save the CID for the next step.

#### CI/CD: CAR File Upload

For GitHub Actions or other CI environments, use CAR file upload for better reliability:

```yaml
# .github/workflows/deploy.yml
- name: Upload to Bulletin
  run: |
    dotns bulletin upload ./dist --use-car --parallel -m "$DOTNS_MNEMONIC"
```

The `--use-car` option packages files into a single CAR archive before upload, which is more reliable in CI environments with network constraints.

### Step 5: Set Content Hash on Domain

```bash
dotns content set <domain-name> <cid> -m "$DOTNS_MNEMONIC"
```

### Step 6: Verify Deployment

```bash
# Check content hash is set
dotns content view <domain-name>
```

**Access your site:**
- **dot.li (recommended):** `https://<domain-name>.dot.li/` (client-side resolution, no proxy)
- Paseo gateway: `https://<domain-name>.paseo.li/`
- IPFS gateway: `https://ipfs.io/ipfs/<cid>`
- dweb.link: `https://dweb.link/ipfs/<cid>`

**See also:** `dotli.md` skill for understanding client-side resolution architecture.

## Automated Deploy Script

For automated deployments, use the deploy script from `templates/minimal-host-app/deploy.sh`:

```bash
#!/usr/bin/env bash
# Usage: ./deploy.sh <name>
# Examples:
#   ./deploy.sh my-app           # → my-app.dot.li
#   ./deploy.sh test.my-app      # → test.my-app.dot.li (subdomain)

set -euo pipefail
NAME="${1:?Usage: ./deploy.sh <name>}"
BUILD_DIR="./dist"

# Validate mnemonic
if [ -z "${DOTNS_MNEMONIC:-}" ]; then
  echo "Error: DOTNS_MNEMONIC required"
  echo "  export DOTNS_MNEMONIC=\$(p1p read \"p1p://<locker>/dotns/customFields.mnemonic\" -n)"
  exit 1
fi
AUTH=(--mnemonic "$DOTNS_MNEMONIC")

# 1. Authorize for Bulletin
ADDRESS=$(dotns account address "${AUTH[@]}")
dotns bulletin authorize "$ADDRESS" "${AUTH[@]}" || echo "(already authorized)"

# 2. Upload to Bulletin
RESULT=$(dotns bulletin upload "$BUILD_DIR" --json --parallel "${AUTH[@]}")
CID=$(echo "$RESULT" | jq -r '.cid')

# 3. Register domain (handles subdomains automatically)
if [[ "$NAME" == *.* ]]; then
  SUB="${NAME%%.*}"; PARENT="${NAME#*.}"
  dotns register domain --name "$PARENT" --status full "${AUTH[@]}" 2>/dev/null || true
  dotns register subname --name "$SUB" --parent "$PARENT" "${AUTH[@]}"
else
  dotns register domain --name "$NAME" --status full "${AUTH[@]}" 2>/dev/null || true
fi

# 4. Set contenthash
dotns content set "$NAME" "$CID" "${AUTH[@]}"

echo "Live at: https://${NAME}.dot.li"
```

**Full script:** See `templates/minimal-host-app/deploy.sh` for complete version with error handling.

## Build Options

### Option 1: Vite (Full Framework)

**REQUIRED** `base: './'` for IPFS-compatible paths:

```typescript
// vite.config.ts
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',  // REQUIRED for IPFS/Bulletin
  // ... rest of config
});
```

### Option 2: Minimal esbuild (Single HTML File)

For simple apps, bundle everything into one HTML file:

```javascript
// build.mjs
import { build } from "esbuild";
import { readFileSync, writeFileSync, mkdirSync } from "fs";

// Bundle JS with all dependencies inlined
const result = await build({
  entryPoints: ["src/main.js"],
  bundle: true,
  format: "esm",
  write: false,
  minify: true,
});

// Read HTML and inline the bundle
let html = readFileSync("src/index.html", "utf-8");
html = html.replace(/<script type="importmap">[\s\S]*?<\/script>\s*/, "");
html = html.replace(
  /<script type="module" src="main.js"><\/script>/,
  `<script type="module">\n${result.outputFiles[0].text}</script>`,
);

mkdirSync("dist", { recursive: true });
writeFileSync("dist/index.html", html);
console.log(`dist/index.html (${(Buffer.byteLength(html) / 1024).toFixed(1)} KB)`);
```

**See:** `templates/minimal-host-app/` for complete example.

## Environment Variables

```bash
# Option A: Use p1p (recommended - no .env file needed)
export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)

# Option B: Add to .env (NEVER COMMIT)
DOTNS_MNEMONIC="your 12 word mnemonic"

# Optional
DOTNS_RPC=wss://asset-hub-paseo-rpc.n.dwellir.com
DOTNS_KEYSTORE_PATH=~/.dotns/keystore
DOTNS_KEYSTORE_PASSWORD=your-password
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| "Requires Personhood Lite verification" | Run `pop set lite` (see First-Time Setup) |
| "Account is not authorized for Bulletin" | Run `bulletin authorize` (see First-Time Setup) |
| Assets return 404 on IPFS | Add `base: './'` to Vite config, rebuild |
| "Missing WebSocket class" | Use Node.js 22+, Bun, or add `NODE_OPTIONS="--experimental-websocket"` |
| "Insufficient balance" | Get PAS from faucet, bridge to Asset Hub |
| Domain already registered | Check owner: `dotns lookup owner-of <domain>` |

### Node.js < 22 WebSocket Workaround

If using Node.js < 22 and getting "Missing WebSocket class" errors:

```bash
# Add NODE_OPTIONS flag before dotns commands
NODE_OPTIONS="--experimental-websocket" dotns bulletin upload ./dist --parallel -m "$DOTNS_MNEMONIC"
NODE_OPTIONS="--experimental-websocket" dotns content set <domain> <cid> -m "$DOTNS_MNEMONIC"
```

Or set it for your shell session:
```bash
export NODE_OPTIONS="--experimental-websocket"
dotns bulletin upload ./dist --parallel -m "$DOTNS_MNEMONIC"
```

## Text Records (Metadata)

Store metadata on your .dot domain (Twitter handles, descriptions, etc.):

```bash
# Set a text record
dotns text set <domain-name> <key> <value> -m "$DOTNS_MNEMONIC"

# Examples
dotns text set myapp twitter "@myapp" -m "$DOTNS_MNEMONIC"
dotns text set myapp description "My decentralized app" -m "$DOTNS_MNEMONIC"
dotns text set myapp url "https://myapp.dot.li" -m "$DOTNS_MNEMONIC"

# View a text record
dotns text view <domain-name> <key>

# Examples
dotns text view myapp twitter      # → @myapp
dotns text view myapp description  # → My decentralized app
```

**Common keys:** `twitter`, `github`, `description`, `url`, `email`, `avatar`

## Common Commands Reference

```bash
# View content hash on domain
dotns content view <domain-name>

# View text records
dotns text view <domain-name> <key>

# View upload history
dotns bulletin history -m "$DOTNS_MNEMONIC"

# Check PoP status
dotns pop status -m "$DOTNS_MNEMONIC"

# Lookup domain info
dotns lookup name <domain-name>
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Register new domain without explicit request | FORBIDDEN | Only register domains when user explicitly asks |
| Skip PoP setup | FORBIDDEN | Domain registration will fail |
| Skip Bulletin authorization | FORBIDDEN | Upload will fail |
| Commit mnemonic to git | FORBIDDEN | Security risk |
| Use absolute paths in build | FORBIDDEN | Breaks on IPFS gateways |
| Deploy to mainnet first | FORBIDDEN | Test on Paseo first |

---

## Verification (REQUIRED before marking complete)

### Pre-Deployment

```bash
# Build succeeds
npm run build  # or pnpm build

# Output is static files
ls dist/

# Check for relative paths (should see ./ not /)
grep -r 'src="/' dist/ && echo "ERROR: absolute paths found" || echo "OK: paths are relative"
```

### Post-Deployment

```bash
# Content hash is set
dotns content view <domain-name>

# Site loads correctly
curl -I "https://<domain-name>.dot.li/"
# Should return 200

# Open in browser
open "https://<domain-name>.dot.li/"
```

### Checklist

- [ ] PoP Lite set (`pop status` shows active)
- [ ] Bulletin authorized (`bulletin authorize`)
- [ ] Build output is static (no SSR)
- [ ] `base: './'` in Vite config (or equivalent)
- [ ] Content hash set on domain
- [ ] Site loads in browser
- [ ] All assets load (check network tab)
