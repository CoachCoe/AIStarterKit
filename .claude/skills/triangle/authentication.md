# Triangle Authentication

## Context

Use when implementing wallet authentication for a Triangle host. Supports two modes:
- **Papp (QR):** Authenticate via Polkadot mobile app QR scan
- **Browser Extensions:** Standard Polkadot.js/Talisman/SubWallet extensions

**Prerequisites:** Read `triangle/OVERVIEW.md` first.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  UnifiedAccountProvider                                          │
│  ├── Papp Mode (QR authentication)                              │
│  │   └── @novasamatech/host-papp-react-ui                       │
│  └── Extension Mode (browser extensions)                         │
│       └── window.injectedWeb3.* (PJS standard)                   │
│                                                                   │
│  Provides: accounts[], signPayload(), signRaw(), disconnect()   │
└─────────────────────────────────────────────────────────────────┘
```

## Unified Account Interface

```typescript
interface UnifiedAccount {
  address: string;
  name?: string;
  type?: string;
  genesisHash?: string;
  source?: string;  // 'papp' | extension name
}

type AuthMode = 'papp' | 'extension' | null;

interface UnifiedAccountContextValue {
  accounts: UnifiedAccount[];
  selectedAccount: UnifiedAccount | null;
  setSelectedAccount: (account: UnifiedAccount | null) => void;
  pappSession: UserSession | null;
  disconnect: () => Promise<void>;
  isConnected: boolean;
  mode: AuthMode;
  signPayload: ((payload: any) => Promise<SignResult>) | null;
  signRaw: ((payload: any) => Promise<SignResult>) | null;
  connectExtension: (extensionName: string) => Promise<void>;
  availableExtensions: string[];
}
```

## Extension Discovery & Connection

```typescript
// lib/extension/connector.ts

// Discover available extensions (filters out host-injected 'spektr')
export function discoverExtensions(): string[] {
  if (typeof window === 'undefined') return [];
  const injected = window.injectedWeb3 || {};
  return Object.keys(injected).filter(name => name !== 'spektr');
}

// Connect to a specific extension
export async function connectExtension(extensionName: string): Promise<ExtensionConnection> {
  const extension = window.injectedWeb3?.[extensionName];
  if (!extension) throw new Error(`Extension ${extensionName} not found`);

  const injected = await extension.enable('Your App Name');
  const accounts = await injected.accounts.get();
  const signer = injected.signer;

  return {
    name: extensionName,
    accounts,
    signer,
    subscribe: (callback) => injected.accounts.subscribe(callback),
    disconnect: () => { /* Extension API doesn't have disconnect */ },
  };
}
```

## Address Resolution Pattern

Embedded apps may re-encode addresses with different SS58 prefixes. Match by public key:

```typescript
import { decodeAddress } from '@polkadot/util-crypto';
import { u8aEq } from '@polkadot/util';

function resolveExtensionAddress(payloadAddress: string, extAccounts: InjectedAccount[]): string {
  try {
    const payloadPk = decodeAddress(payloadAddress);
    for (const acc of extAccounts) {
      const accPk = decodeAddress(acc.address);
      if (u8aEq(payloadPk, accPk)) {
        return acc.address;  // Return extension's original address
      }
    }
  } catch {
    // decode failed
  }
  return payloadAddress;
}
```

## Signing Mutex Pattern

Browser extensions can't handle concurrent signing popups. Serialize requests:

```typescript
const signingLockRef = useRef<Promise<any>>(Promise.resolve());

const extensionSign = useCallback((method: 'signPayload' | 'signRaw') => {
  if (!extensionSigner?.[method]) return null;

  return async (payload: any): Promise<SignResult> => {
    // Resolve address to extension's original
    const adapted = payload?.address
      ? { ...payload, address: resolveExtensionAddress(payload.address, rawExtensionAccounts) }
      : payload;

    // Chain onto the lock - requests queue instead of racing
    const request = signingLockRef.current.then(
      () => extensionSigner[method]!(adapted),
      () => extensionSigner[method]!(adapted),  // Proceed even if previous rejected
    );
    signingLockRef.current = request.catch(() => {});  // Swallow for chain continuity

    const result = await request;
    return { signature: result.signature as `0x${string}` };
  };
}, [extensionSigner]);
```

## Papp Sign Handlers

```typescript
const signPayload = useMemo(() => {
  if (mode === 'extension') {
    return extensionSign('signPayload');
  }
  if (mode === 'papp' && pappSession) {
    return async (payload: any): Promise<SignResult> => {
      const { u8aToHex } = await import('@polkadot/util');
      const result = await pappSession.signPayload(payload);
      if (result.isErr()) throw result.error;
      return {
        signature: u8aToHex(result.value.signature) as `0x${string}`,
        signedTransaction: result.value.signedTransaction
          ? (u8aToHex(result.value.signedTransaction) as `0x${string}`)
          : undefined,
      };
    };
  }
  return null;
}, [mode, extensionSign, pappSession]);
```

## Provider Hierarchy

Components using authentication must be wrapped correctly:

```tsx
// Provider hierarchy (defined in papp-provider.tsx)
<QueryClientProvider>
  <PappNetworkProvider>           {/* Network selection context */}
    <PappProvider key={network}>  {/* Re-mounts on network change */}
      <UnifiedAccountProvider>    {/* Unified auth context */}
        {children}
      </UnifiedAccountProvider>
    </PappProvider>
  </PappNetworkProvider>
</QueryClientProvider>
```

**Error:** `useUnifiedAccount must be used within a UnifiedAccountProvider`
**Solution:** Wrap component with `<PolkadotProvider>`.

## Auto-Reconnect Pattern

```typescript
useEffect(() => {
  const discovered = discoverExtensions();
  setAvailableExtensions(discovered);

  // Auto-reconnect to previously connected extension
  const savedExtension = localStorage.getItem('polkadot:extension-name');
  if (savedExtension && discovered.includes(savedExtension)) {
    connectExtension(savedExtension)
      .then((connection) => {
        extensionConnectionRef.current = connection;
        setExtensionAccounts(mapExtensionAccounts(connection.accounts, connection.name));
        setExtensionSigner(connection.signer);
        setMode('extension');

        // Restore selected account
        const savedAddress = localStorage.getItem('polkadot:selected-account');
        const found = savedAddress ? accounts.find(a => a.address === savedAddress) : null;
        setSelectedAccount(found ?? accounts[0] ?? null);

        // Subscribe to account changes
        connection.subscribe((newAccounts) => {
          // Update accounts and handle removal of selected account
        });
      })
      .catch(() => {
        localStorage.removeItem('polkadot:extension-name');
      });
  }
}, []);
```

## Disconnect Handling

```typescript
const disconnect = useCallback(async () => {
  if (mode === 'extension') {
    extensionConnectionRef.current?.disconnect();
    extensionConnectionRef.current = null;
    setExtensionAccounts([]);
    setExtensionSigner(null);
    localStorage.removeItem('polkadot:extension-name');
  }
  if (mode === 'papp' && pappSession) {
    try {
      await pappAuth.disconnect(pappSession);
    } catch {
      // Statement store errors during disconnect are non-fatal
    }
  }
  setMode(null);
  setSelectedAccount(null);
}, [mode, pappSession, pappAuth]);
```

## Network Selection for Papp

```typescript
// config/papp.ts
export type PappNetwork = 'previewnet' | 'pop3';

export function getPappConfig(network: PappNetwork) {
  return network === 'previewnet'
    ? { relayWss: 'wss://previewnet.substrate.dev/relay/alice', ... }
    : { relayWss: 'wss://pop3-relay-rpc.polkadot.io', ... };
}

// Switch network: remount PappProvider via key={network}
<PappProvider key={network}>
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Concurrent extension signing | FORBIDDEN | Extensions can't handle multiple popups |
| Comparing addresses as strings | RISKY | SS58 encoding may differ |
| Storing signer in global state | RISKY | Signer is per-connection |
| Ignoring rejected sign results | RISKY | User cancelled - handle gracefully |
| Not persisting extension name | RISKY | User must reconnect on page reload |
| Calling disconnect without try/catch | RISKY | Statement store errors are non-fatal |
