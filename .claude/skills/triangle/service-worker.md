# Triangle Service Worker

## Context

Use when building a production Triangle host that serves embedded products from IPFS/Bulletin storage. The Service Worker handles caching, serving, and routing for embedded product files.

**Prerequisites:** Read `triangle/OVERVIEW.md` and `dotns-resolution.md` first.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Service Worker                                                  │
│  ├── fileCache (Map)           In-memory archive storage        │
│  ├── productIdIndex (Map)      O(1) lookup by productId         │
│  ├── clientProductMap (Map)    Track iframe → product mapping   │
│  └── IndexedDB                 Persistent archive storage       │
└─────────────────────────────────────────────────────────────────┘
```

## Data Structures

```javascript
// In-memory cache (keyed by domain)
const fileCache = new Map();

// O(1) lookup by productId (keyed by productId -> archive)
const productIdIndex = new Map();

// Track which clients (iframes) belong to which product
// Handles case where iframe navigates to absolute path (e.g., /auth)
const clientProductMap = new Map();  // clientId -> productId
```

## Message Events

### Save Archive

```javascript
// Send from main thread:
const archive = {
  domain: 'myapp.dot',
  assetsOrigin: 'https://myapp_dot-abc123...',
  entrypointBase: './product-myapp_dot-abc12',
  files: { 'index.html': Uint8Array, 'app.js': Uint8Array, ... },
  contenthash: '0xe3010170...',  // For cache validation
};

const messageChannel = new MessageChannel();
messageChannel.port1.onmessage = (event) => {
  if (event.data.success) console.log('Archive saved');
};
controller.postMessage({ type: 'SW_SAVE_EVENT', ...archive }, [messageChannel.port2]);
```

```javascript
// SW handler:
self.addEventListener('message', (event) => {
  // Security: Validate origin
  if (event.origin && event.origin !== self.location.origin) {
    console.warn('[SW] Rejected message from different origin');
    return;
  }

  if (event.data.type === 'SW_SAVE_EVENT') {
    const archive = { domain, assetsOrigin, entrypointBase, files, contenthash };

    fileCache.set(archive.domain, archive);
    const productId = getProductId(archive);
    productIdIndex.set(productId, archive);
    saveArchiveToDB(archive);

    for (const port of event.ports) {
      port.postMessage({ success: true });
    }
  }
});
```

### Cache Lookup

```javascript
// Send from main thread:
controller.postMessage({ type: 'SW_CACHE_LOOKUP_EVENT', domain }, [messageChannel.port2]);

// SW handler:
if (event.data.type === 'SW_CACHE_LOOKUP_EVENT') {
  const domain = event.data.domain;
  let archive = fileCache.get(domain);

  // Skip stale archives without contenthash
  if (archive && !archive.contenthash) {
    fileCache.delete(domain);
    archive = null;
  }

  if (!archive) {
    // Try IndexedDB
    const dbArchive = await loadArchiveFromDBByDomain(domain);
    if (dbArchive && dbArchive.contenthash) {
      fileCache.set(domain, dbArchive);
      productIdIndex.set(getProductId(dbArchive), dbArchive);
      archive = dbArchive;
    }
  }

  for (const port of event.ports) {
    port.postMessage({ found: !!archive, archive });
  }
}
```

## Fetch Handler - 4-Step Routing

```javascript
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  const clientId = event.clientId;

  // STEP 1: Direct product path match (e.g., /product-xxx/something)
  for (const archive of fileCache.values()) {
    const match = matchArchive(url, archive);
    if (match) {
      // Track this client as belonging to this product
      if (clientId) {
        clientProductMap.set(clientId, getProductId(archive));
      }
      event.respondWith(serveFromArchive(archive, match.pathname, match.base));
      return;
    }
  }

  // STEP 2: Check referer for product context
  const referer = event.request.referrer;
  let productArchive = null;

  if (referer) {
    const refererUrl = new URL(referer);
    const segments = refererUrl.pathname.split('/').filter(Boolean);
    for (const segment of segments) {
      const archive = productIdIndex.get(segment);
      if (archive) {
        productArchive = archive;
        break;
      }
    }
  }

  // STEP 2b: Fallback to clientId mapping
  // Handles: iframe navigated to /auth, referer is now /auth (no productId)
  if (!productArchive && clientId) {
    const trackedProductId = clientProductMap.get(clientId);
    if (trackedProductId) {
      productArchive = productIdIndex.get(trackedProductId);
    }
  }

  // STEP 3: Serve from product archive (same-origin only)
  if (productArchive) {
    if (url.origin !== self.location.origin) {
      return;  // Cross-origin - pass to network
    }

    if (clientId) {
      clientProductMap.set(clientId, getProductId(productArchive));
    }

    const resolvedPath = resolveFilePath(productArchive, url.pathname);
    const base = `${url.origin}/${getProductId(productArchive)}/`;
    event.respondWith(serveFromArchive(productArchive, resolvedPath, base));
    return;
  }

  // STEP 4: Not from product - pass to network (host pages, host assets)
});
```

## Why ClientId Tracking?

When an embedded dapp navigates to an absolute path:

```
1. User clicks link to /auth
2. SW serves /auth from archive (referer still has productId)
3. Document URL becomes /auth
4. Page requests /_next/chunks/238.js
5. Referer is now /auth (no productId!)
6. Without clientId tracking → falls through → 404
7. With clientId tracking → finds archive → works
```

## Serving Files

```javascript
function serveFromArchive(archive, pathname, base) {
  // Security: Validate path
  if (!isValidPath(pathname)) {
    return new Response('Invalid path', { status: 400 });
  }

  let cleanPath = pathname.startsWith('/') ? pathname.substring(1) : pathname;
  if (cleanPath === '') cleanPath = 'index.html';

  // Remove query strings for file lookup
  const queryIndex = cleanPath.indexOf('?');
  if (queryIndex !== -1) cleanPath = cleanPath.substring(0, queryIndex);

  cleanPath = decodeURIComponent(cleanPath);

  let content = archive.files[cleanPath];
  let mimeType = getMimeType(cleanPath);

  // SPA fallback for extensionless paths
  if (!content && !cleanPath.includes('.')) {
    content = archive.files['index.html'];
    mimeType = 'text/html';
  }

  if (!content) {
    const page404 = archive.files['404.html'];
    return new Response(page404 || '404: Not found', {
      status: 404,
      headers: { 'Content-Type': page404 ? 'text/html' : 'text/plain' },
    });
  }

  // Inject base tag and rewrite absolute paths for HTML
  if (mimeType === 'text/html') {
    if (content instanceof Uint8Array) {
      content = new TextDecoder().decode(content);
    }
    content = content.replace('<head>', `<head><base href="${base}">`);
    // Rewrite framework paths
    content = content.replace(/(['\"(])\/_/g, '$1_');        // /_nuxt/ -> _nuxt/
    content = content.replace(/(['\"(])\/assets\//g, '$1assets/');
    content = content.replace(/(['\"(])\/static\//g, '$1static/');
  }

  return new Response(content, {
    status: 200,
    headers: { 'Content-Type': mimeType },
  });
}
```

## Path Security

```javascript
function isValidPath(path) {
  // Reject traversal sequences
  if (path.includes('..') ||
      path.includes('%2e%2e') ||
      path.includes('%2E%2E')) {
    return false;
  }
  return true;
}
```

## IndexedDB Persistence

```javascript
const DB_NAME = 'triangle-web-host-sw';
const DB_VERSION = 1;
const STORE_NAME = 'archives';

async function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'domain' });
      }
    };
  });
}

// Restore archives on SW activation
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const archives = await loadArchivesFromDB();
    for (const archive of archives) {
      // Skip stale archives
      if (!archive.contenthash) continue;

      fileCache.set(archive.domain, archive);
      productIdIndex.set(getProductId(archive), archive);
    }
    await self.clients.claim();
  })());
});
```

## MIME Type Handling

```javascript
const MIME_TYPES = {
  html: 'text/html',
  css: 'text/css',
  js: 'application/javascript',
  json: 'application/json',
  png: 'image/png',
  svg: 'image/svg+xml',
  woff2: 'font/woff2',
  wasm: 'application/wasm',
  // ... etc
};

function getMimeType(path) {
  const ext = path.split('.').pop()?.toLowerCase() || '';
  return MIME_TYPES[ext] || 'application/octet-stream';
}
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Using `indexOf` for productId matching | RISKY | Can match substrings falsely |
| Not validating path traversal | FORBIDDEN | Security vulnerability |
| Skipping contenthash validation | RISKY | Can serve stale content |
| Cross-origin requests from products | FORBIDDEN | Must pass to network |
| Not injecting `<base>` tag | RISKY | Relative paths will break |
| Ignoring clientId tracking | RISKY | SPA navigation breaks |
