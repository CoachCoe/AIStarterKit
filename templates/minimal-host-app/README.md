# Minimal Host App Template

A minimal starter for building Triangle host apps using vanilla JavaScript. This template demonstrates all core Host API features in ~800 lines of code with only 3 npm dependencies.

## Features

- **Account detection** - Auto-detects login/logout via Host
- **Transaction signing** - System.remark example with finalization tracking
- **Raw message signing** - Sign arbitrary data via Host modal
- **Host storage** - Scoped key-value storage (JSON read/write/clear)
- **Chain queries** - Read on-chain state via Host-managed connection

## Prerequisites

- Node.js >= 18
- [DotNS CLI](https://github.com/paritytech/dotns-sdk) (for deployment only)

## Install

```bash
npm install
```

## Develop

```bash
npm run dev
```

Opens a local server at `http://localhost:8000` serving `src/` directly (uses ES module import maps for dependencies).

**Note:** Full functionality requires running inside a Triangle Host (dot.li, Spektr, Polkadot Desktop). Outside the Host, you'll see "Not in Host" message.

## Build

```bash
npm run build
```

Bundles all JS dependencies into a single `dist/index.html` via esbuild. The output is a self-contained HTML file ready for deployment.

## Deploy

### Prerequisites

1. Install DotNS CLI:
   ```bash
   cd dotns-sdk/packages/cli
   bun install && bun run build && npm link
   ```

2. Fund your account via https://faucet.polkadot.io/

3. Authorize for Bulletin storage via https://paritytech.github.io/polkadot-bulletin-chain/

### Deploy Command

```bash
# Set mnemonic (directly or via p1p)
export DOTNS_MNEMONIC="your twelve word mnemonic phrase goes here ..."
# Or: export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)

# Deploy
./deploy.sh <name>
```

Your site will be live at `https://<name>.dot.li`.

## Chain Configuration

Edit `CHAIN` in `src/main.js` to target a different chain:

```javascript
const CHAIN = {
  name: "Paseo Asset Hub",
  genesis: "0xd6eec26135305a8ad257a20d003357284c8aa03d0bdb2b357ab0a22371e11ef2",
  wsUrl: "wss://sys.ibp.network/asset-hub-paseo",
};
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Your App (iframe)                                               │
│  ├── NO direct HTTP/fetch (sandboxed)                           │
│  ├── Accounts via window.injectedWeb3.spektr                    │
│  └── Chain access via Host API                                   │
└─────────────────────────────────────────────────────────────────┘
         ↓ PostMessage via sandboxTransport
┌─────────────────────────────────────────────────────────────────┐
│  Triangle Host (dot.li / Spektr / Polkadot Desktop)             │
│  ├── Manages chain connections                                   │
│  ├── Provides account signing                                    │
│  └── Scoped localStorage per app                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `src/index.html` | UI with inline CSS, import maps for dev |
| `src/main.js` | All SDK patterns in one file |
| `build.mjs` | esbuild bundler (32 lines) |
| `deploy.sh` | Full deployment workflow |
| `package.json` | 3 dependencies only |

## Adapting This Template

1. Edit `CHAIN` config for your target chain
2. Remove unused sections (each is self-contained)
3. Add your own UI and logic
4. The imports work the same with a bundler

## Related Skills

- `triangle/OVERVIEW.md` - Triangle architecture
- `triangle/product-sdk.md` - SDK reference
- `deploy-frontend/SKILL.md` - Deployment workflow
- `asset-hub-evm.md` - Chain configuration
