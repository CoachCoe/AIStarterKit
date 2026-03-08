---
name: triangle-spektr-manager
description: "Container orchestration for embedded products in Triangle hosts. Triggers: spektr, container, iframe, embed product"
---

# SpektrManager - Container Orchestration

## When to Activate

- Building a host that embeds third-party products
- Managing iframe containers for products
- Implementing account injection to products

## Context

Use when building a **host** that embeds third-party products in iframes. SpektrManager is the singleton service that orchestrates all embedded product containers.

**Prerequisites:** Read `triangle/OVERVIEW.md` first.

## Core Concepts

### What SpektrManager Does

1. Creates and manages iframe containers for embedded products
2. Handles account injection to products
3. Delegates signing requests to wallet (Papp or browser extension)
4. Provides JSON-RPC proxy for chain access (RPC or light client)
5. Scopes localStorage per product to prevent collisions

### Key Interfaces

```typescript
interface RemoteAccount {
  address: string;
  name?: string;
  publicKey: Uint8Array;
}

type ConnectionMode = 'lightclient' | 'rpc';

interface CreateToolOptions {
  iframe: HTMLIFrameElement;
  url: string;
  toolId: string;
  accounts: RemoteAccount[];
  connectionMode?: ConnectionMode;  // default: 'rpc'
  chain?: ChainConfig;
  signPayload?: SignHandler;
  signRaw?: SignHandler;
  onConnectionStatusChange?: (status: string) => void;
  onChainStatusChange?: (status: 'connecting' | 'connected' | 'error') => void;
}
```

## Implementation Patterns

### Singleton Pattern

```typescript
// lib/services/spektr-manager.ts
import { createContainer, createIframeProvider } from '@novasamatech/host-container';
import type { Container } from '@novasamatech/host-container';
import mitt from 'mitt';

class SpektrManager {
  private containers = new Map<string, Container>();
  private iframeElements = new Map<string, HTMLIFrameElement>();
  private creationLocks = new Map<string, Promise<Container>>();
  private toolAccounts = new Map<string, RemoteAccount[]>();
  private toolSignHandlers = new Map<string, { signPayload?: SignHandler; signRaw?: SignHandler }>();
  private toolChainProviders = new Map<string, Map<string, JsonRpcProvider>>();
  private eventBus = mitt();

  // ... methods below
}

// Export singleton
export const spektrManager = new SpektrManager();
```

### Creating a Tool Container

```typescript
async createTool(options: CreateToolOptions): Promise<Container> {
  const { iframe, url, toolId, accounts, connectionMode = 'rpc', chain, signPayload, signRaw } = options;

  // Deduplicate: return existing container if same iframe
  if (this.iframeElements.get(toolId) === iframe && this.containers.has(toolId)) {
    this.toolAccounts.set(toolId, accounts);
    this.toolSignHandlers.set(toolId, { signPayload, signRaw });
    return this.containers.get(toolId)!;
  }

  // Lock to prevent duplicate concurrent creation
  const existingLock = this.creationLocks.get(toolId);
  if (existingLock) return existingLock;

  const creationPromise = this._createToolInternal(options);
  this.creationLocks.set(toolId, creationPromise);

  try {
    return await creationPromise;
  } finally {
    this.creationLocks.delete(toolId);
  }
}
```

### Handler Registration

```typescript
private async _createToolInternal(options: CreateToolOptions): Promise<Container> {
  const provider = createIframeProvider({ iframe: options.iframe, url: options.url });
  const container = createContainer(provider);

  // Feature support check - tell embedded app which chains we support
  container.handleFeatureSupported((params, { ok }) => {
    if (params.tag === 'Chain') {
      const supported = SUPPORTED_CHAINS.some(c => c.genesisHash === params.value);
      return ok(supported);
    }
    return ok(false);
  });

  // Account injection
  container.handleGetNonProductAccounts((_, { ok }) => {
    const accounts = this.toolAccounts.get(options.toolId) || [];
    return ok(accounts.map(acc => ({
      publicKey: acc.publicKey,
      name: acc.name,
    })));
  });

  // Signing handlers (see authentication.md for full implementation)
  container.handleSignPayload((params, { err }) => {
    const handlers = this.toolSignHandlers.get(options.toolId);
    if (!handlers?.signPayload) {
      return err(new SigningErr.Unknown({ reason: 'Signing not configured' }));
    }
    // Delegate to sign handler...
  });

  // Scoped localStorage per product
  container.handleLocalStorageRead((key, { ok }) => {
    const storageKey = `product:${options.toolId}:${key}`;
    const raw = localStorage.getItem(storageKey);
    return ok(raw !== null ? new TextEncoder().encode(raw) : undefined);
  });

  container.handleLocalStorageWrite(([key, value], { ok }) => {
    const storageKey = `product:${options.toolId}:${key}`;
    localStorage.setItem(storageKey, new TextDecoder().decode(value));
    return ok(undefined);
  });

  this.containers.set(options.toolId, container);
  return container;
}
```

### Multi-Chain Provider Setup

```typescript
// Dynamic chain provider - lazily creates providers for any supported chain
const chainProviders = new Map<string, JsonRpcProvider>();

const getOrCreateProvider = async (chainConfig: ChainConfig): Promise<JsonRpcProvider> => {
  const existing = chainProviders.get(chainConfig.genesisHash);
  if (existing) return existing;

  let provider: JsonRpcProvider;
  if (connectionMode === 'lightclient' && chainConfig.getChainSpec) {
    const chainSpec = await chainConfig.getChainSpec();
    provider = await createLightClientProvider({ chainId: chainConfig.genesisHash, chainSpec });
  } else {
    provider = getWsProvider(chainConfig.rpcUrl);
  }

  chainProviders.set(chainConfig.genesisHash, provider);
  return provider;
};

// Eagerly create default chain provider
await getOrCreateProvider(chain);

// Register handler for additional chains (lazy, sync callback = RPC only)
container.handleChainConnection((requestedGenesisHash) => {
  const chainConfig = getChainByGenesisHash(requestedGenesisHash);
  if (!chainConfig) return null;

  const existing = chainProviders.get(requestedGenesisHash);
  if (existing) return existing;

  // Sync callback = must use RPC (can't await light client)
  const provider = getWsProvider(chainConfig.rpcUrl);
  chainProviders.set(requestedGenesisHash, provider);
  return provider;
});
```

### Updating Accounts

```typescript
updateAccounts(toolId: string, accounts: RemoteAccount[]) {
  this.toolAccounts.set(toolId, accounts);
  this.eventBus.emit('accounts:changed', accounts);

  // Notify iframe about account changes
  const iframe = this.iframeElements.get(toolId);
  if (iframe) {
    let targetOrigin = '*';
    try {
      const url = new URL(iframe.src);
      if (url.protocol !== 'blob:' && url.protocol !== 'data:') {
        targetOrigin = url.origin;
      }
    } catch {
      targetOrigin = window.location.origin;
    }
    iframe.contentWindow?.postMessage({ type: 'accounts-updated' }, targetOrigin);
  }
}

updateAllAccounts(accounts: RemoteAccount[]) {
  for (const toolId of this.containers.keys()) {
    this.updateAccounts(toolId, accounts);
  }
}
```

### Disposal

```typescript
disposeTool(toolId: string) {
  // Clean up in order
  this.connectionUnsubscribes.get(toolId)?.();
  this.connectionUnsubscribes.delete(toolId);

  const container = this.containers.get(toolId);
  this.containers.delete(toolId);
  this.creationLocks.delete(toolId);
  this.toolChainProviders.delete(toolId);
  this.iframeElements.delete(toolId);
  this.toolAccounts.delete(toolId);
  this.toolSignHandlers.delete(toolId);

  container?.dispose();  // Last - handles WebSocket teardown
}
```

## Chain Configuration

```typescript
// lib/host/chains.ts
export interface ChainConfig {
  id: string;
  name: string;
  genesisHash: `0x${string}`;
  rpcUrl: string;
  tokenSymbol: string;
  tokenDecimals: number;
  getChainSpec?: () => Promise<string>;  // For light client support
}

export const PASEO_ASSET_HUB: ChainConfig = {
  id: 'paseo-asset-hub',
  name: 'Paseo Asset Hub',
  genesisHash: '0xd6eec26135305a8ad257a20d003357284c8aa03d0bdb2b357ab0a22371e11ef2',
  rpcUrl: 'wss://sys.ibp.network/asset-hub-paseo',
  tokenSymbol: 'PAS',
  tokenDecimals: 10,
  getChainSpec: async () => {
    const { chainSpec } = await import('@polkadot-api/known-chains/paseo_asset_hub');
    return chainSpec;
  },
};

export const SUPPORTED_CHAINS: ChainConfig[] = [PASEO_ASSET_HUB, PREVIEWNET, PREVIEWNET_ASSET_HUB];
```

## Usage with React Hook

```typescript
// hooks/use-product-frame.ts
export function useProductFrame(
  iframeRef: RefObject<HTMLIFrameElement>,
  options: { source: FrameSource; connectionMode?: ConnectionMode }
) {
  const { selectedAccount, signPayload, signRaw } = useUnifiedAccount();
  const [status, setStatus] = useState<'idle' | 'connecting' | 'connected'>('idle');

  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe || !selectedAccount) return;

    const toolId = `tool-${source.value}`;
    const accounts = selectedAccount ? [toRemoteAccount(selectedAccount)] : [];

    spektrManager.createTool({
      iframe,
      url: resolvedUrl,
      toolId,
      accounts,
      connectionMode,
      signPayload,
      signRaw,
      onConnectionStatusChange: setStatus,
    });

    return () => spektrManager.disposeTool(toolId);
  }, [selectedAccount, signPayload, signRaw]);

  // Update accounts when they change
  useEffect(() => {
    spektrManager.updateAccounts(toolId, accounts);
  }, [accounts]);

  return { status };
}
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Creating container without lock | FORBIDDEN | Race conditions, duplicate containers |
| Storing accounts globally | FORBIDDEN | Accounts are per-tool |
| Calling dispose() before clearing maps | RISKY | Can cause stale reference errors |
| Hardcoding chain genesis hash | RISKY | Use SUPPORTED_CHAINS lookup |
| Ignoring connection status | RISKY | Users need feedback |
