---
name: previewnet
description: "Ephemeral development network with pre-funded accounts. Triggers: previewnet, local dev, no faucet, ephemeral"
---

# Previewnet - Ephemeral Development Network

## When to Activate

- Setting up local development environment
- Testing before using Paseo testnet tokens
- Need pre-funded accounts without faucet
- Integration testing with Asset Hub, People Chain, or Bulletin

## Context
Use Previewnet for initial development and testing before deploying to Paseo testnet. No faucet tokens needed - accounts are pre-funded.

## What is Previewnet?

Previewnet provides ephemeral Substrate networks for development. It mirrors the production Polkadot structure with Asset Hub, People Chain, and Bulletin - but is disposable and comes with pre-funded accounts.

## Network Endpoints

### Ethereum RPC (for EVM development)
```
https://previewnet.substrate.dev/eth-rpc
```

### WebSocket Endpoints

| Chain | Endpoint |
|-------|----------|
| Asset Hub | `wss://previewnet.substrate.dev/asset-hub` |
| People Chain | `wss://previewnet.substrate.dev/people` |
| Bulletin | `wss://previewnet.substrate.dev/bulletin` |

### Relay Chain Validators
- `wss://previewnet.substrate.dev/relay/alice`
- `wss://previewnet.substrate.dev/relay/bob`
- `wss://previewnet.substrate.dev/relay/charlie`
- `wss://previewnet.substrate.dev/relay/dave`
- `wss://previewnet.substrate.dev/relay/eve`
- `wss://previewnet.substrate.dev/relay/ferdie`

### Auxiliary Services

| Service | Endpoint |
|---------|----------|
| IPFS Gateway | `https://previewnet.substrate.dev/ipfs/` |
| Statement Store | `wss://previewnet.substrate.dev/people` (statement_* RPC) |

## Pre-funded Dev Accounts

Standard Substrate dev accounts are pre-funded:

| Account | Address |
|---------|---------|
| Alice | `0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d` |
| Bob | `0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48` |

For EVM, use the corresponding ETH-style addresses derived from these accounts.

## Foundry Configuration

Add previewnet to your `foundry.toml`:

```toml
[rpc_endpoints]
previewnet = "https://previewnet.substrate.dev/eth-rpc"
paseo = "https://paseo-asset-hub-eth-rpc.polkadot.io"
polkadot = "https://polkadot-asset-hub-eth-rpc.polkadot.io"
local = "http://127.0.0.1:8545"
```

## Development Workflow

### Recommended Order

1. **Local Anvil** - Unit tests, fast iteration
2. **Previewnet** - Integration tests, no tokens needed
3. **Paseo Testnet** - Production-like testing
4. **Polkadot Mainnet** - Production deployment

### Deploy to Previewnet

```bash
# No need to source .env for previewnet - use dev accounts
forge script script/Deploy.s.sol \
  --rpc-url previewnet \
  --broadcast \
  --slow \
  -vvvv
```

### Using Dev Account Keys

For Previewnet, you can use the standard dev account keys:

```bash
# Alice's dev private key (for testing only!)
PRIVATE_KEY=0xe5be9a5092b81bca64be81d212e7f2f9eba183bb7a90954f7b76361f6edb5c0a
```

## When to Use Previewnet vs Paseo

| Scenario | Use |
|----------|-----|
| Initial development | Previewnet |
| No tokens available | Previewnet |
| Quick iteration | Previewnet |
| Testing cross-chain | Previewnet |
| Pre-launch testing | Paseo |
| External testing | Paseo |
| Production rehearsal | Paseo |

## Chain Specifications

Download chain specs for smoldot light client:

| Chain | Parachain ID |
|-------|--------------|
| Relay Chain | Westend Local |
| Asset Hub | 1000 |
| People Chain | 1004 |
| Bulletin | 2487 |

## Spawning Custom Networks

Previewnet supports spawning ephemeral instances with custom configuration:
- Choice of parachains
- Custom release versions
- Configurable TTL (time-to-live)

Visit https://previewnet.substrate.dev/ for the web interface.

## Polkadot.js Integration

Connect directly via Polkadot.js Apps:
- Asset Hub: https://polkadot.js.org/apps/?rpc=wss://previewnet.substrate.dev/asset-hub

## Limitations

| Aspect | Previewnet | Paseo |
|--------|------------|-------|
| Persistence | Ephemeral | Persistent |
| Public visibility | Limited | Full |
| Token value | None | None (testnet) |
| Network stability | Dev-grade | Production-grade |

## Anti-Patterns (FORBIDDEN)

| Pattern | Why Forbidden | Instead |
|---------|---------------|---------|
| Skip previewnet, deploy to Paseo first | Wastes faucet tokens, slower iteration | MUST use previewnet for initial development |
| Hardcode previewnet endpoints | URLs may change | MUST use foundry.toml rpc_endpoints |
| Use mainnet keys on previewnet | Security risk if keys leak | MUST use dev account keys (Alice, Bob) |
| Assume state persists | Previewnet is ephemeral | MUST expect resets, deploy fresh |
| Deploy without `--slow` | Nonce issues on Asset Hub | MUST always use `--slow` flag |
| Test only on previewnet | Different from production | MUST also test on Paseo before mainnet |
