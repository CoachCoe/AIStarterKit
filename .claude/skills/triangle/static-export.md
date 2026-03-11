---
name: triangle-static-export
description: "Static export requirements for Bulletin/IPFS deployment. Triggers: static export, bulletin deploy, ipfs, no ssr"
---

# Static Export Requirements

## When to Activate

- Deploying Triangle host or product to Bulletin/IPFS
- Configuring Next.js or Vite for static output
- Troubleshooting SSR-related deployment issues

## Context

Use when deploying Triangle hosts or products to Bulletin Chain / IPFS. All Triangle apps must be static files (HTML, CSS, JS) - no server-side rendering or API routes.

**Prerequisites:** Read `triangle/OVERVIEW.md` first.

## Why Static Export?

Triangle hosts and products are deployed to:
- **Bulletin Chain:** Polkadot's decentralized storage
- **IPFS:** Content-addressed distributed storage

Both require static files. No server runtime is available.

## Next.js Configuration

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'export',           // Static HTML export (REQUIRED)
  distDir: 'dist',            // Output directory
  trailingSlash: true,        // Required for static file serving
  images: {
    unoptimized: true,        // No image optimization server available
  },
};

export default nextConfig;
```

## Build Output

```bash
npm run build   # Generates static files in dist/
npm run serve   # Local testing of static files
```

Output structure:
```
dist/
├── index.html
├── about/
│   └── index.html
├── _next/
│   ├── static/
│   │   ├── chunks/
│   │   └── css/
│   └── ...
└── ...
```

## SSR-Unsafe Code Patterns

All embedding and blockchain code uses browser-only APIs (WebSocket, localStorage, smoldot). Use dynamic imports:

### Page-Level Dynamic Import

```tsx
// src/app/page.tsx
import dynamic from 'next/dynamic';

const PageContent = dynamic(() => import('./page-content'), { ssr: false });

export default function Page() {
  return <PageContent />;
}
```

### Component-Level Wrapper

```tsx
// src/components/client-only-persistent-frames.tsx
import dynamic from 'next/dynamic';

export const ClientOnlyPersistentFrames = dynamic(
  () => import('./persistent-frames'),
  { ssr: false }
);
```

### Usage in Layout

```tsx
// src/app/layout.tsx
import { ClientOnlyPersistentFrames } from '@/components/client-only-persistent-frames';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <Header />
        {children}
        <ClientOnlyPersistentFrames />  {/* All embedding here */}
      </body>
    </html>
  );
}
```

## Vite Configuration

For Vite-based products:

```typescript
// vite.config.ts
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',  // REQUIRED for IPFS-compatible relative paths
});
```

## Path Requirements

### Relative Paths

All asset paths must be relative for IPFS gateway compatibility:

```html
<!-- Good -->
<script src="./assets/app.js"></script>
<link href="./styles/main.css" rel="stylesheet">

<!-- Bad - will break on IPFS -->
<script src="/assets/app.js"></script>
<link href="/styles/main.css" rel="stylesheet">
```

### Trailing Slashes

Configure framework to use trailing slashes:

```
/about    →  404 on IPFS
/about/   →  serves /about/index.html
```

## Service Worker Considerations

Service Workers must be at the root:

```
dist/
├── sw.js           # Service Worker at root
├── index.html
└── ...
```

Registration:

```typescript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
```

## API Routes: Not Supported

Static export means NO server-side code:

```typescript
// src/app/api/data/route.ts
// ❌ This will NOT work with static export!
export async function GET() {
  return Response.json({ data: 'hello' });
}
```

All data fetching must be client-side:

```typescript
// ✅ Client-side data fetching
useEffect(() => {
  fetch('https://api.example.com/data')
    .then(res => res.json())
    .then(setData);
}, []);
```

## Light Client: Host Provides

Don't bundle smoldot in products:

```typescript
// ❌ Don't do this in products
import { start } from 'smoldot';
const client = await start();

// ✅ Use host-provided provider
import { hostApi } from '@novasamatech/product-sdk';
const provider = hostApi.getChainProvider(genesisHash);
```

## Environment Variables

Client-side env vars only (prefixed):

```bash
# .env
NEXT_PUBLIC_PAPP_APP_ID=https://your-app.example.com
NEXT_PUBLIC_PAPP_METADATA_URL=/papp-metadata.json
```

```typescript
// Access in code
const appId = process.env.NEXT_PUBLIC_PAPP_APP_ID;
```

**Never expose secrets** - everything in the bundle is public.

## Deployment Checklist

- [ ] `output: 'export'` in Next.js config
- [ ] `base: './'` in Vite config (if using Vite)
- [ ] `trailingSlash: true` configured
- [ ] No API routes in the app
- [ ] All browser-only code uses `dynamic(..., { ssr: false })`
- [ ] All paths are relative (no leading `/` for assets)
- [ ] Service Worker at root level
- [ ] No server-side secrets in code
- [ ] Images set to `unoptimized: true`

## Testing Static Export

```bash
# Build
npm run build

# Serve locally (use any static server)
npx serve dist

# Or with Python
python -m http.server -d dist 3000
```

Verify:
1. All pages load correctly
2. Client-side navigation works
3. Assets load (no 404s in console)
4. Service Worker registers

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| API routes | FORBIDDEN | No server runtime |
| `getServerSideProps` | FORBIDDEN | No server runtime |
| Absolute asset paths | FORBIDDEN | Breaks on IPFS gateways |
| Bundling secrets | FORBIDDEN | Visible in browser |
| SSR for embedding code | FORBIDDEN | Browser-only APIs |
| Image optimization | FORBIDDEN | No optimization server |
| Middleware | FORBIDDEN | No edge runtime |

## Browser Compatibility (Sandbox Restrictions)

Products run in a sandboxed iframe with no direct network access. These Node.js patterns will fail:

| Pattern | Status | Alternative |
|---------|--------|-------------|
| `Buffer.from()` | FORBIDDEN | Use `Uint8Array` or `ss58Encode` from `@polkadot-labs/hdkd-helpers` |
| `fetch()` to external APIs | FORBIDDEN | Use host-provided APIs only |
| `window.ethereum` | FORBIDDEN | Use `@novasamatech/product-sdk` accounts |
| External tile servers (Leaflet, MapBox) | FORBIDDEN | HTTP requests blocked in sandbox |
| Direct WebSocket connections | FORBIDDEN | Use host's chain provider |

### Converting Public Keys to Addresses

```typescript
// ❌ WRONG - Buffer not available in browsers
const address = '0x' + Buffer.from(publicKey).toString('hex');

// ✅ CORRECT - Use ss58Encode
import { ss58Encode } from '@polkadot-labs/hdkd-helpers';
const address = ss58Encode(publicKey, 42); // 42 = generic SS58 prefix
```

### Installing Browser-Compatible Helpers

```bash
pnpm add @polkadot-labs/hdkd-helpers
```
