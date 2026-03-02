# Asset Hub EVM Development

## Context
Use when deploying or interacting with contracts on Polkadot Asset Hub EVM.

## Network Configuration

### Previewnet (Local Development)
- RPC: https://previewnet.substrate.dev/eth-rpc
- Pre-funded accounts (Alice, Bob, etc.)
- No faucet needed - ephemeral network
- See `previewnet.md` skill for full details

### Paseo Testnet (Integration Testing)
- RPC: https://paseo-asset-hub-eth-rpc.polkadot.io
- Chain ID: 420420421
- Block Explorer: https://paseo.subscan.io
- Faucet: https://faucet.polkadot.io (get PAS, then bridge to Asset Hub)

### Polkadot Mainnet (Production)
- RPC: https://polkadot-asset-hub-eth-rpc.polkadot.io
- Chain ID: 420420420
- Block Explorer: https://assethub-polkadot.subscan.io

## Foundry Configuration

Use this exact foundry.toml:

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
solc = "0.8.20"
optimizer = true
optimizer_runs = 200
evm_version = "london"

[rpc_endpoints]
previewnet = "https://previewnet.substrate.dev/eth-rpc"
paseo = "https://paseo-asset-hub-eth-rpc.polkadot.io"
polkadot = "https://polkadot-asset-hub-eth-rpc.polkadot.io"
local = "http://127.0.0.1:8545"

[fmt]
line_length = 100
tab_width = 4
bracket_spacing = true
```

## Key Differences from Ethereum

1. **Native Token**: DOT (not ETH) - accessed via `msg.value` same as ETH
2. **Gas Prices**: Generally lower than Ethereum mainnet
3. **Block Time**: ~6 seconds (faster than Ethereum)
4. **No Etherscan**: Use Subscan for block exploration
5. **ERC20 Tokens**: HoLLAR available, pUSD coming soon

## Deployment Commands

```bash
# 1. Local Anvil (unit tests)
anvil --chain-id 420420421
forge script script/Deploy.s.sol --rpc-url local --broadcast

# 2. Previewnet (integration tests - no tokens needed)
forge script script/Deploy.s.sol \
  --rpc-url previewnet \
  --broadcast \
  --slow \
  -vvvv

# 3. Paseo testnet (pre-production)
source .env
forge script script/Deploy.s.sol \
  --rpc-url paseo \
  --broadcast \
  --slow \
  -vvvv
```

## Environment Variables (.env)

```
PRIVATE_KEY=0x...
PASEO_RPC_URL=https://paseo-asset-hub-eth-rpc.polkadot.io
POLKADOT_RPC_URL=https://polkadot-asset-hub-eth-rpc.polkadot.io
ADMIN_ADDRESS=0x...
```

## Common Issues & Solutions

1. **Transaction underpriced**: Increase gas price
   ```bash
   --with-gas-price 1000000000
   ```

2. **Nonce issues**: Use --slow flag for sequential transactions
   ```bash
   forge script ... --slow
   ```

3. **Contract verification**: Not supported via Etherscan API
   - Publish source code manually
   - Use Subscan's contract tab

4. **RPC timeout**: Add retry logic or use --slow

## Testing Against Asset Hub

For integration tests that need real Asset Hub state:

```solidity
// Fork Paseo for testing
vm.createSelectFork("paseo");
```
