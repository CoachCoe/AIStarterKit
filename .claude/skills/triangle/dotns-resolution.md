# DotNS Resolution

## Context

Use when resolving `.dot` domains to IPFS content for loading products in Triangle hosts.

**Prerequisites:** Read `triangle/OVERVIEW.md` first.

## Why Two Resolvers?

DotNS contracts are deployed on **multiple chains**, and domains may be registered on any of them:

| Chain | Purpose | RPC Type | Speed |
|-------|---------|----------|-------|
| **Paseo Asset Hub** | Main testnet | HTTP (EVM) | ~100ms |
| **Previewnet** | Ephemeral dev network | WebSocket | ~500ms |

**Problem:** When resolving a domain, we don't know which chain it was registered on.

**Solution:** Race resolvers in parallel using `Promise.any()` - first success wins.

## Resolver Configuration

```typescript
// lib/dotns/constants.ts
export const PASEO_ASSET_HUB_EVM_RPC = 'https://paseo-asset-hub-eth-rpc.polkadot.io';
export const PASEO_ASSET_HUB_RESOLVER = '0x7756DF72CBc7f062e7403cD59e45fBc78bed1cD7';

export const DOTNS_CONTENT_RESOLVER_ABI = [
  {
    inputs: [{ name: 'node', type: 'bytes32' }],
    name: 'contenthash',
    outputs: [{ name: '', type: 'bytes' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;
```

## Resolution Implementation

```typescript
import { namehash, createPublicClient, http } from 'viem';

const paseoAssetHubClient = createPublicClient({
  transport: http(PASEO_ASSET_HUB_EVM_RPC),
});

async function resolveViaPaseoAssetHub(node: `0x${string}`): Promise<string | null> {
  try {
    const result = await paseoAssetHubClient.readContract({
      address: PASEO_ASSET_HUB_RESOLVER,
      abi: DOTNS_CONTENT_RESOLVER_ABI,
      functionName: 'contenthash',
      args: [node],
    });
    if (result && result !== '0x') {
      return result as string;
    }
  } catch (err) {
    console.warn('[DotNS] Paseo Asset Hub resolution failed:', err);
  }
  return null;
}
```

## Racing Pattern

```typescript
async function raceResolvers(node: `0x${string}`): Promise<string> {
  // Wrap each resolver to reject on null (so Promise.any skips it)
  const paseoPromise = resolveViaPaseoAssetHub(node).then((result) => {
    if (result) return result;
    throw new Error('Paseo Asset Hub returned empty');
  });

  const previewnetPromise = resolveViaPreviewnet(node).then((result) => {
    if (result) return result;
    throw new Error('Previewnet returned empty');
  });

  // Returns first successful result, others are ignored
  // If all fail → AggregateError (domain not found)
  return Promise.any([paseoPromise, previewnetPromise]);
}
```

## React Hook

```typescript
// hooks/use-dot-domain-combined.ts
interface UseDotDomainResult {
  archive: ProductArchive | null;
  loading: boolean;
  error: string | null;
  stage: 'idle' | 'connecting' | 'resolving' | 'fetching' | 'done' | 'error';
}

export function useDotDomain(domain: string | null): UseDotDomainResult {
  const [archive, setArchive] = useState<ProductArchive | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [stage, setStage] = useState<UseDotDomainResult['stage']>('idle');
  const resolvedDomains = useRef<Map<string, ProductArchive>>(new Map());

  useEffect(() => {
    if (!domain || !dotNsService.isDotDomain(domain)) {
      setArchive(null);
      setStage('idle');
      return;
    }

    // Return cached if already resolved
    const cached = resolvedDomains.current.get(domain);
    if (cached) {
      setArchive(cached);
      setStage('done');
      return;
    }

    let cancelled = false;

    async function resolve() {
      setLoading(true);
      setStage('resolving');

      try {
        const node = namehash(domain) as `0x${string}`;
        const contenthash = await raceResolvers(node);

        if (cancelled) return;

        setStage('fetching');
        const fetchedArchive = await ipfsService.fetchFromIpfs(domain, contenthash);

        if (cancelled) return;

        if (!fetchedArchive) {
          throw new Error('Failed to fetch content from IPFS');
        }

        resolvedDomains.current.set(domain, fetchedArchive);
        setArchive(fetchedArchive);
        setStage('done');
      } catch (err) {
        if (cancelled) return;
        const message = err instanceof AggregateError
          ? 'Domain has no contenthash set'
          : err instanceof Error ? err.message : String(err);
        setError(message);
        setStage('error');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    resolve();
    return () => { cancelled = true; };
  }, [domain]);

  return { archive, loading, error, stage };
}
```

## Contenthash Decoding

```typescript
import { decode as decodeContent, getCodec } from '@ensdomains/content-hash';

function decodeContenthash(contenthash: `0x${string}`): string | null {
  try {
    const codec = getCodec(contenthash);
    if (codec === 'ipfs') {
      return decodeContent(contenthash);  // Returns IPFS CID
    }
    return null;
  } catch {
    return null;
  }
}
```

## IPFS Fetching with Retry

```typescript
const RETRY_COUNT = 3;
const RETRY_DELAY_MS = 2000;

async function fetchFromIpfsGateway(url: string): Promise<Uint8Array | null> {
  for (let attempt = 1; attempt <= RETRY_COUNT; attempt++) {
    try {
      const response = await fetch(url, {
        signal: AbortSignal.timeout(30000),
      });
      if (response.ok) {
        return new Uint8Array(await response.arrayBuffer());
      }
    } catch (error) {
      console.warn(`[IPFS] Attempt ${attempt} error:`, error);
    }

    if (attempt < RETRY_COUNT) {
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY_MS));
    }
  }
  return null;
}
```

## Cache-First Strategy

```typescript
async function fetchFromIpfs(domain: string, contenthash: `0x${string}`): Promise<ProductArchive | null> {
  // Check Service Worker cache first
  const cachedArchive = await getArchiveFromServiceWorker(domain);
  if (cachedArchive && cachedArchive.contenthash === contenthash) {
    return cachedArchive;  // Content unchanged, use cache
  }

  // Cache miss or stale - fetch from IPFS
  const ipfsCid = decodeContenthash(contenthash);
  const buffer = await fetchFromIpfsGateway(`${IPFS_GATEWAY}/${ipfsCid}`);

  // Parse and save to cache
  const files = await parseCarFile(buffer);
  const archive = { domain, files, contenthash, ... };
  await saveArchiveToServiceWorker(archive);

  return archive;
}
```

## Benefits of Racing

1. **Universal compatibility:** Works for domains registered on any supported chain
2. **Speed:** HTTP (EVM) usually wins, but fallback is automatic
3. **Resilience:** If one chain is down, the other still works
4. **No configuration:** User doesn't need to know which chain has their domain

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Sequential resolver calls | RISKY | Slow - race in parallel |
| Caching by domain only | RISKY | Must validate contenthash hasn't changed |
| Ignoring AggregateError | RISKY | All resolvers failed = domain not found |
| No retry logic for IPFS | RISKY | IPFS gateways can be flaky |
| Using `Promise.all` for resolvers | FORBIDDEN | Need first success, not all |
| Hardcoding single resolver | RISKY | Domains can be on different chains |
