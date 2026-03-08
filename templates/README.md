# Starter Templates

Working starter code for building on Polkadot. Use the init script for one-command setup.

---

## One-Command Setup (Recommended)

```bash
# Triangle Host App
./scripts/init.sh my-app
cd my-app && npm run dev    # → http://localhost:8000

# Smart Contracts (Foundry)
./scripts/init.sh my-contracts --contracts
cd my-contracts && forge test
```

---

## Available Templates

| Template | Command | What You Get |
|----------|---------|--------------|
| `minimal-host-app/` | `./scripts/init.sh name` | Host API, signing, storage |
| Smart Contracts | `./scripts/init.sh name --contracts` | UUPS, OpenZeppelin, Foundry |

---

## Manual Setup

### minimal-host-app

A minimal Triangle app demonstrating all Host API features in ~800 lines:

```bash
cp -r templates/minimal-host-app my-app
cd my-app
npm install && npm run dev    # → http://localhost:8000
npm run build && ./deploy.sh my-app  # → https://my-app.dot.li
```

**Features:**
- Account detection (login/logout)
- Transaction signing with finalization tracking
- Raw message signing
- Host storage (JSON read/write/clear)
- Chain queries via Host API

**Files:**
```
minimal-host-app/
├── src/
│   ├── index.html    # UI with inline CSS
│   └── main.js       # All SDK patterns
├── build.mjs         # esbuild bundler (32 lines)
├── deploy.sh         # Full deployment workflow
├── package.json      # 3 dependencies
└── README.md
```

---

## Creating from Template

1. **Copy the template directory**
   ```bash
   cp -r templates/minimal-host-app my-project
   cd my-project
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development**
   ```bash
   npm run dev
   ```

4. **Customize**
   - Edit `src/main.js` for logic
   - Edit `src/index.html` for UI
   - Edit `CHAIN` constant for different target chain

5. **Build and deploy**
   ```bash
   npm run build
   export DOTNS_MNEMONIC="your mnemonic..."
   ./deploy.sh your-app-name
   ```

---

## Planned Templates

| Template | Stack | Status |
|----------|-------|--------|
| `contracts-only/` | Foundry, Solidity | ✅ Available (`--contracts` flag) |
| `full-stack/` | Foundry + React | Planned |
| `react-host-app/` | React, Vite | Planned |

---

## Template Requirements

All templates should:
- Be self-contained (no external dependencies on repo)
- Include README.md with setup instructions
- Include working build + deploy scripts
- Follow "least code wins" philosophy
- Target Paseo Asset Hub by default

---

## Related Skills

- `triangle/OVERVIEW.md` - Triangle architecture
- `triangle/product-sdk.md` - SDK patterns
- `deploy-frontend/SKILL.md` - Deployment workflow
- `host-api.md` - Host API overview
